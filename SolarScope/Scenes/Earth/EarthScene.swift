import Combine
import CoreText
import RealityKit
import SwiftUI
import UIKit

/// Builds and animates the table-top Earth and ISS scene.
///
/// Structure: Earth turns on its axis inside a billboarded atmosphere glow,
/// while the Space Station circles it on a ring tilted to the station's real
/// 51.6° inclination. A display link drives the motion and honours the
/// animation settings from the Settings screen. Only the station is
/// selectable; tapping it opens the ISS info panel.
@MainActor
final class EarthScene: NSObject, ObservableObject {

    /// Whether the Space Station is selected, shown in the info panel.
    @Published private(set) var issSelected = false

    /// Playback state, controlled by the toolbar button. The scene starts
    /// paused when "Animate scenes" is switched off in Settings.
    @Published private(set) var isPaused: Bool

    /// Prefix of the selectable node (`item-iss`).
    private static let itemPrefix = "item-"

    private static let earthRadius: Float = 0.14
    private static let orbitRadius: Float = 0.30
    /// The ISS's real orbital inclination, in radians.
    private static let inclination: Float = 0.9006
    /// Educational durations in seconds: one spin and one lap.
    private static let earthSpinPeriod: Double = 40
    private static let issOrbitPeriod: Double = 26
    private static let issExtent: Float = 0.05

    private var earthSpin: Entity?
    private var orbitPivot: Entity?
    private var issHolder: Entity?
    private var spinAngle: Float = 0
    private var orbitAngle: Float = 0
    private var targetScale: Float = 1
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
        root.name = "earthISS"
        root.addChild(Self.sunlight())
        root.addChild(makeEarth())
        root.addChild(makeOrbit())

        rootEntity = root
        startAnimating()
        return root
    }

    /// Earth: the model spins inside a static glow and a fixed name label.
    private func makeEarth() -> Entity {
        let holder = Entity()
        holder.name = "earth"

        let spin = Entity()
        spin.name = "earthSpin"
        let (model, _) = Self.scaledModel(named: "EarthClouds_1_12756",
                                          targetExtent: Self.earthRadius * 2)
        spin.addChild(model)
        holder.addChild(spin)

        holder.addChild(Self.atmosphere())
        holder.addChild(Self.label(text: "Earth", height: Self.earthRadius + 0.10, size: 0.03))

        earthSpin = spin
        return holder
    }

    /// The station's orbit: a tilted ring with the ISS riding around it.
    private func makeOrbit() -> Entity {
        let tilt = Entity()
        tilt.name = "orbitPlane"
        tilt.orientation = simd_quatf(angle: Self.inclination, axis: SIMD3(1, 0, 0))
        tilt.addChild(Self.orbitRing())

        let pivot = Entity()
        pivot.name = "orbitPivot"
        tilt.addChild(pivot)

        let holder = Entity()
        holder.name = Self.itemPrefix + "iss"
        holder.position = SIMD3(Self.orbitRadius, 0, 0)
        pivot.addChild(holder)

        let (model, lift) = Self.scaledModel(named: ISSData.assetName,
                                             targetExtent: Self.issExtent)
        model.position.y = lift
        holder.addChild(model)
        holder.addChild(Self.label(text: "ISS", height: Self.issExtent * 0.7 + 0.03, size: 0.02))

        orbitPivot = pivot
        issHolder = holder
        return tilt
    }

    /// Loads a model, centres it on its own origin and scales its largest
    /// dimension to `targetExtent`. Returns the wrapper plus the lift needed
    /// so the model rests on its holder's origin instead of sinking into it.
    private static func scaledModel(named assetName: String, targetExtent: Float) -> (Entity, Float) {
        guard let loaded = try? Entity.load(named: assetName) else {
            let standIn = ModelEntity(
                mesh: .generateBox(width: targetExtent,
                                   height: targetExtent * 0.5,
                                   depth: targetExtent * 0.6),
                materials: [SimpleMaterial(color: UIColor(white: 0.8, alpha: 1),
                                           roughness: 0.7,
                                           isMetallic: false)]
            )
            return (standIn, targetExtent * 0.25)
        }

        let wrapper = Entity()
        wrapper.addChild(loaded)
        let bounds = loaded.visualBounds(relativeTo: wrapper)
        let extent = max(bounds.extents.x, max(bounds.extents.y, bounds.extents.z))
        guard extent > 0.0001 else { return (wrapper, 0) }

        loaded.position -= bounds.center
        let scale = targetExtent / extent
        wrapper.scale = SIMD3(repeating: scale)
        return (wrapper, bounds.extents.y / 2 * scale)
    }

    /// Soft blue rim glow, drawn as a camera-facing quad whose gradient peaks
    /// exactly at Earth's silhouette.
    private static func atmosphere() -> Entity {
        let side = earthRadius * 2.6
        let mesh = MeshResource.generatePlane(width: side, height: side)

        var material = UnlitMaterial()
        if let texture = Self.glowTexture() {
            material.color = UnlitMaterial.BaseColor(texture: MaterialParameters.Texture(texture))
        } else {
            material.color = .init(tint: UIColor(red: 0.4, green: 0.65, blue: 1, alpha: 0.5))
        }
        material.blending = .transparent(opacity: 1.0)

        let halo = ModelEntity(mesh: mesh, materials: [material])
        halo.name = "atmosphere"
        halo.components.set(BillboardComponent())
        return halo
    }

    /// Radial gradient: transparent across Earth's disc, brightest at the
    /// limb, fading out into space.
    private static func glowTexture() -> TextureResource? {
        let side: CGFloat = 256
        let image = UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { context in
            let cg = context.cgContext
            cg.clear(CGRect(x: 0, y: 0, width: side, height: side))

            let center = CGPoint(x: side / 2, y: side / 2)
            let colors = [
                UIColor(red: 0.35, green: 0.62, blue: 1.0, alpha: 0).cgColor,
                UIColor(red: 0.45, green: 0.70, blue: 1.0, alpha: 0.55).cgColor,
                UIColor(red: 0.30, green: 0.55, blue: 1.0, alpha: 0).cgColor
            ] as CFArray
            let locations: [CGFloat] = [0.66, 0.79, 1.0]
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                            colors: colors,
                                            locations: locations)
            else { return }
            cg.drawRadialGradient(gradient,
                                  startCenter: center, startRadius: 0,
                                  endCenter: center, endRadius: side / 2,
                                  options: [])
        }
        guard let cgImage = image.cgImage else { return nil }
        return try? TextureResource(image: cgImage, options: .init(semantic: .color))
    }

    /// Thin translucent ring marking the station's orbit.
    private static func orbitRing() -> Entity {
        guard let mesh = try? annulus(innerRadius: orbitRadius - 0.003,
                                      outerRadius: orbitRadius + 0.003,
                                      segments: 128)
        else { return Entity() }

        let ring = ModelEntity(
            mesh: mesh,
            materials: [UnlitMaterial(color: UIColor(white: 1, alpha: 0.35))]
        )
        ring.name = "orbit-iss"
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

    /// Warm sunlight, so the lit side of Earth reads against the night side.
    private static func sunlight() -> DirectionalLight {
        let light = DirectionalLight()
        light.name = "sunlight"
        light.light = DirectionalLightComponent(
            color: DirectionalLightComponent.Color(red: 1.0, green: 0.96, blue: 0.90, alpha: 1),
            intensity: 3000
        )
        light.orientation = simd_quatf(angle: -0.7,
                                       axis: simd_normalize(SIMD3(1, 0, 0.35)))
        return light
    }

    /// Floating name label, always facing the camera.
    private static func label(text: String, height: Float, size: CGFloat) -> Entity {
        let mesh = MeshResource.generateText(
            text,
            extrusionDepth: 0.001,
            font: .systemFont(ofSize: size),
            containerFrame: CGRect(x: 0, y: 0, width: 1, height: size * 2),
            alignment: .center,
            lineBreakMode: .byTruncatingTail
        )
        let text = ModelEntity(mesh: mesh,
                               materials: [UnlitMaterial(color: UIColor(white: 1, alpha: 0.92))])

        let container = Entity()
        container.addChild(text)
        text.position -= text.visualBounds(relativeTo: container).center
        container.position = SIMD3(0, height, 0)
        container.components.set(BillboardComponent())
        return container
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

        // Selection highlight eases towards its target scale.
        if let holder = issHolder {
            let difference = targetScale - holder.scale.x
            if abs(difference) > 0.001 {
                let eased = holder.scale.x + difference * min(1, frame * 12)
                holder.scale = SIMD3(repeating: eased)
            }
        }

        guard !isPaused else { return }
        let delta = Double(frame) * speed

        orbitAngle += Float(2 * Double.pi * delta / Self.issOrbitPeriod)
        spinAngle += Float(2 * Double.pi * delta / Self.earthSpinPeriod)
        orbitPivot?.orientation = simd_quatf(angle: orbitAngle, axis: SIMD3(0, 1, 0))
        earthSpin?.orientation = simd_quatf(angle: spinAngle, axis: SIMD3(0, 1, 0))
    }

    // MARK: Selection

    /// Maps a tapped entity to the station and toggles the selection.
    func handleSelection(_ entity: Entity?) {
        guard let id = itemID(of: entity) else {
            clearSelection()
            return
        }
        guard id == "iss" else {
            clearSelection()
            return
        }
        issSelected.toggle()
        targetScale = issSelected ? 1.35 : 1
    }

    func clearSelection() {
        guard issSelected else { return }
        issSelected = false
        targetScale = 1
    }

    /// Walks up the tapped entity to the nearest selectable item node.
    private func itemID(of entity: Entity?) -> String? {
        var node = entity
        while let current = node {
            if current.name.hasPrefix(Self.itemPrefix) {
                return String(current.name.dropFirst(Self.itemPrefix.count))
            }
            node = current.parent
        }
        return nil
    }
}
