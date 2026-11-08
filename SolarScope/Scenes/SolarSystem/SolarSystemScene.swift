import Combine
import CoreText
import RealityKit
import SwiftUI
import UIKit

/// Builds and animates the table-top Solar System scene.
///
/// Structure: the Sun sits at the centre and every planet hangs from its own
/// pivot, which revolves around the Sun, while a spin node turns the model on
/// its axis. Generated orbit rings and billboarded name labels complete the
/// model. A display link drives the motion and honours the animation
/// settings from the Settings screen.
@MainActor
final class SolarSystemScene: NSObject, ObservableObject {

    /// The planet currently selected by a tap, shown in the info panel.
    @Published private(set) var selectedPlanet: Planet?

    /// Playback state, controlled by the toolbar button. The scene starts
    /// paused when "Animate scenes" is switched off in Settings.
    @Published private(set) var isPaused: Bool

    /// Prefix of the selectable node for each body (`body-earth`, …).
    private static let bodyPrefix = "body-"

    private struct Body {
        let planet: Planet
        /// Rotates around the Sun (revolution).
        let pivot: Entity
        /// Fixed point on the orbit; carries the label (`body-<id>`).
        let holder: Entity
        /// Turns on the model's axis (rotation); scaled up when selected.
        let spin: Entity
        var orbitAngle: Float
        var spinAngle: Float
        var targetScale: Float = 1
    }

    private var bodies: [Body] = []
    private var rootEntity: Entity?
    private var displayLink: CADisplayLink?
    private var lastTick: TimeInterval = 0
    private let speed: Double

    override init() {
        let defaults = UserDefaults.standard
        let animationsOn = defaults.object(forKey: SettingsKey.animationsEnabled) as? Bool ?? true
        isPaused = !animationsOn
        speed = defaults.object(forKey: SettingsKey.animationSpeed) as? Double ?? 1.0
        super.init()
    }

    // MARK: Scene building

    /// Builds the scene once and returns it for placement in AR.
    func makeRoot() -> Entity {
        if let rootEntity { return rootEntity }

        let root = Entity()
        root.name = "solarSystem"
        root.addChild(makeBody(PlanetData.sun, initialOrbitAngle: 0))
        for (index, planet) in PlanetData.planets.enumerated() {
            root.addChild(Self.orbitRing(for: planet))
            // Golden-angle spacing keeps the starting positions natural.
            let start = Float(index) * 2.399
            root.addChild(makeBody(planet, initialOrbitAngle: start))
        }

        rootEntity = root
        startAnimating()
        return root
    }

    private func makeBody(_ planet: Planet, initialOrbitAngle: Float) -> Entity {
        let pivot = Entity()
        pivot.name = "pivot-\(planet.id)"

        let holder = Entity()
        holder.name = Self.bodyPrefix + planet.id
        holder.position = SIMD3(Float(planet.orbitRadius), 0, 0)
        pivot.addChild(holder)

        let spin = Entity()
        spin.name = "spin-\(planet.id)"
        spin.orientation = simd_quatf(angle: initialOrbitAngle, axis: SIMD3(0, 1, 0))
        holder.addChild(spin)

        spin.addChild(Self.model(for: planet))
        holder.addChild(Self.label(for: planet))

        if planet.kind == .sun {
            let light = PointLight()
            light.light = PointLightComponent(intensity: 3_500, attenuationRadius: 3)
            light.position = SIMD3(0, 0.1, 0)
            holder.addChild(light)
        }

        bodies.append(
            Body(planet: planet,
                 pivot: pivot,
                 holder: holder,
                 spin: spin,
                 orbitAngle: initialOrbitAngle,
                 spinAngle: initialOrbitAngle)
        )
        return pivot
    }

    /// Loads the body's USDZ model, scaled to the educational size and
    /// centred on its own origin. Falls back to a tinted sphere when the
    /// asset cannot be loaded.
    private static func model(for planet: Planet) -> Entity {
        let radius = Float(planet.visualRadius)

        guard let model = try? Entity.load(named: planet.assetName) else {
            return ModelEntity(
                mesh: .generateSphere(radius: radius),
                materials: [SimpleMaterial(color: UIColor(planet.tint),
                                           roughness: 0.8,
                                           isMetallic: false)]
            )
        }

        let wrapper = Entity()
        wrapper.addChild(model)
        let bounds = model.visualBounds(relativeTo: wrapper)
        let extent = max(bounds.extents.x, max(bounds.extents.y, bounds.extents.z))
        guard extent > 0.0001 else { return wrapper }

        model.position -= bounds.center
        wrapper.scale = SIMD3(repeating: (radius * 2) / extent)
        return wrapper
    }

    /// Floating name label above a body, always facing the camera.
    private static func label(for planet: Planet) -> Entity {
        let mesh = MeshResource.generateText(
            planet.name,
            extrusionDepth: 0.002,
            font: .systemFont(ofSize: 0.045),
            containerFrame: CGRect(x: 0, y: 0, width: 1, height: 0.1),
            alignment: .center,
            lineBreakMode: .byTruncatingTail
        )
        let text = ModelEntity(mesh: mesh,
                               materials: [UnlitMaterial(color: UIColor(white: 1, alpha: 0.92))])

        let container = Entity()
        container.addChild(text)
        text.position -= text.visualBounds(relativeTo: container).center
        container.position = SIMD3(0, Float(planet.visualRadius) + 0.06, 0)
        container.components.set(BillboardComponent())
        return container
    }

    /// Thin translucent ring marking the planet's orbit.
    private static func orbitRing(for planet: Planet) -> Entity {
        let radius = Float(planet.orbitRadius)
        guard let mesh = try? Self.annulus(innerRadius: radius - 0.004,
                                            outerRadius: radius + 0.004,
                                            segments: 128)
        else { return Entity() }

        let ring = ModelEntity(
            mesh: mesh,
            materials: [UnlitMaterial(color: UIColor(planet.tint).withAlphaComponent(0.35))]
        )
        ring.name = "orbit-\(planet.id)"
        return ring
    }

    /// Flat ring mesh: a thin annulus lying in the XZ plane.
    private static func annulus(innerRadius: Float,
                                outerRadius: Float,
                                segments: Int) throws -> MeshResource {
        var positions: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        positions.reserveCapacity(segments * 2)
        indices.reserveCapacity(segments * 6)

        for i in 0..<segments {
            let angle = Float(i) / Float(segments) * 2 * Float.pi
            let direction = SIMD3<Float>(cos(angle), 0, sin(angle))
            positions.append(direction * innerRadius)
            positions.append(direction * outerRadius)
        }
        for i in 0..<segments {
            let inner = UInt32(i * 2)
            let outer = inner + 1
            let nextInner = UInt32(((i + 1) % segments) * 2)
            let nextOuter = nextInner + 1
            indices.append(contentsOf: [inner, nextInner, outer,
                                        outer, nextInner, nextOuter])
        }

        var descriptor = MeshDescriptor(name: "orbitRing")
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.primitives = .triangles(indices)
        return try MeshResource.generate(from: [descriptor])
    }

    // MARK: Animation

    func startAnimating() {
        guard displayLink == nil else { return }
        lastTick = 0
        let link = CADisplayLink(target: self, selector: #selector(step(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func stopAnimating() {
        displayLink?.invalidate()
        displayLink = nil
        lastTick = 0
    }

    func togglePaused() {
        isPaused.toggle()
        lastTick = 0
    }

    @objc private func step(_ link: CADisplayLink) {
        let now = link.timestamp
        let elapsed = lastTick == 0 ? 1.0 / 60.0 : now - lastTick
        lastTick = now

        let frame = Float(min(elapsed, 0.1))
        for i in bodies.indices {
            // Selection highlight eases towards its target scale.
            let body = self.bodies[i]
            let difference = body.targetScale - body.spin.scale.x
            if abs(difference) > 0.001 {
                let eased = body.spin.scale.x + difference * min(1, frame * 12)
                body.spin.scale = SIMD3(repeating: eased)
            }

            guard !isPaused else { continue }
            let delta = Double(frame) * speed
            bodies[i].orbitAngle += Float(2 * Double.pi * delta / bodies[i].planet.revolutionPeriod)
            bodies[i].spinAngle += Float(2 * Double.pi * delta / bodies[i].planet.rotationPeriod)
            bodies[i].pivot.orientation = simd_quatf(angle: bodies[i].orbitAngle,
                                                     axis: SIMD3(0, 1, 0))
            bodies[i].spin.orientation = simd_quatf(angle: bodies[i].spinAngle,
                                                    axis: SIMD3(0, 1, 0))
        }
    }

    // MARK: Selection

    /// Maps a tapped entity to its body and toggles the selection.
    func handleSelection(_ entity: Entity?) {
        guard let id = bodyID(of: entity) else {
            clearSelection()
            return
        }
        if selectedPlanet?.id == id {
            clearSelection()
        } else {
            selectedPlanet = PlanetData.planet(withID: id)
            updateHighlight()
        }
    }

    func clearSelection() {
        selectedPlanet = nil
        updateHighlight()
    }

    /// Walks up the tapped entity to the nearest selectable body node.
    private func bodyID(of entity: Entity?) -> String? {
        var node = entity
        while let current = node {
            if current.name.hasPrefix(Self.bodyPrefix) {
                return String(current.name.dropFirst(Self.bodyPrefix.count))
            }
            node = current.parent
        }
        return nil
    }

    private func updateHighlight() {
        let selectedID = selectedPlanet.map { Self.bodyPrefix + $0.id }
        for i in bodies.indices {
            bodies[i].targetScale = bodies[i].holder.name == selectedID ? 1.35 : 1
        }
    }
}
