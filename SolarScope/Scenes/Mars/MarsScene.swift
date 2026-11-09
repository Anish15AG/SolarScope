import Combine
import RealityKit
import simd
import SwiftUI
import UIKit

/// Builds and animates the table-top Mars exploration scene.
///
/// The scene is a slice of Martian ground: a generated crater-rim terrain disc
/// scattered with rocks, dunes and mesas, with Perseverance and Curiosity
/// standing on the surface and Ingenuity flying repeated take-off and landing
/// cycles above it. Warm directional light and rust-coloured materials give
/// the whole scene the look of the planet. A display link drives the motion
/// and honours the animation settings from the Settings screen.
@MainActor
final class MarsScene: NSObject, ObservableObject {

    /// The mission currently selected by a tap, shown in the info panel.
    @Published private(set) var selectedMission: MarsMission?

    /// Playback state, controlled by the toolbar button. The scene starts
    /// paused when "Animate scenes" is switched off in Settings.
    @Published private(set) var isPaused: Bool

    /// Whether the Curiosity comparison rover is visible on the surface.
    @Published private(set) var showsCuriosity = false

    /// Prefix of the selectable node for each item (`item-perseverance`, …).
    private static let itemPrefix = "item-"

    /// Radius of the terrain disc, in metres.
    private static let groundRadius: Float = 0.34

    /// Length of one Ingenuity flight cycle in seconds: rise, hover, land.
    private static let flightCycle: Double = 9

    private struct Item {
        let id: String
        /// Carries the model and label; scaled up when selected.
        let holder: Entity
        var targetScale: Float = 1
    }

    private var items: [Item] = []
    private var curiosityHolder: Entity?
    private var ingenuityFlight: Entity?
    private var ingenuityYaw: Entity?
    private var flightTime: Double = 0
    private var yawAngle: Float = 0
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
        root.name = "mars"
        root.addChild(Self.ground())
        root.addChild(Self.sunlight())

        let perseverance = makeRover(
            id: "perseverance",
            assetName: "25042_Perseverance",
            targetExtent: 0.13,
            label: "Perseverance",
            at: SIMD2(-0.13, 0.05)
        )
        root.addChild(perseverance)

        let ingenuity = makeIngenuity(at: SIMD2(0.00, 0.15))
        root.addChild(ingenuity)

        let curiosity = makeRover(
            id: "curiosity",
            assetName: "24584_Curiosity_static",
            targetExtent: 0.12,
            label: "Curiosity",
            at: SIMD2(0.14, -0.09)
        )
        curiosity.isEnabled = false
        curiosityHolder = curiosity
        root.addChild(curiosity)

        root.addChild(Self.scatterTerrain())

        rootEntity = root
        startAnimating()
        return root
    }

    /// The terrain disc: rust-coloured soil with a raised crater rim.
    private static func ground() -> Entity {
        guard let mesh = try? terrainMesh() else { return Entity() }

        var material = PhysicallyBasedMaterial()
        material.baseColor = PhysicallyBasedMaterial.BaseColor(
            // The speckled texture already carries the soil colour; the tint
            // stays neutral so it does not multiply it down to maroon.
            tint: UIColor(white: 1, alpha: 1),
            texture: groundTexture()
        )
        material.roughness = 0.98
        material.metallic = 0.0

        let ground = ModelEntity(mesh: mesh, materials: [material])
        ground.name = "ground"
        return ground
    }

    /// Warm, low sun over the terrain.
    private static func sunlight() -> DirectionalLight {
        let light = DirectionalLight()
        light.name = "sunlight"
        light.light = DirectionalLightComponent(
            color: DirectionalLightComponent.Color(red: 1.0, green: 0.87, blue: 0.70, alpha: 1),
            intensity: 3000
        )
        // Shine down across the scene.
        light.orientation = simd_quatf(angle: -0.7,
                                       axis: simd_normalize(SIMD3(1, 0, 0.35)))
        return light
    }

    /// Rocks, dunes and mesas scattered over the terrain, placed away from
    /// the rover positions so nothing intersects a model.
    private static func scatterTerrain() -> Entity {
        let clearing: [SIMD2<Float>] = [
            SIMD2(-0.13, 0.05), SIMD2(0.00, 0.15), SIMD2(0.14, -0.09)
        ]

        let cluster = Entity()
        cluster.name = "terrainDetails"
        var rng = SeededRandom(seed: 2021_02_18) // Perseverance landing day.

        // Rocks.
        for _ in 0..<16 {
            let angle = rng.next() * 2 * .pi
            let radius = Float(0.10 + rng.next() * 0.20)
            let position = SIMD2<Float>(cos(angle) * radius, sin(angle) * radius)
            guard clearing.allSatisfy({ simd_distance($0, position) > 0.06 }) else { continue }

            let size = Float(0.008 + rng.next() * 0.016)
            let rock = ModelEntity(
                mesh: .generateSphere(radius: size),
                materials: [SimpleMaterial(color: UIColor(red: 0.52, green: 0.28, blue: 0.19, alpha: 1),
                                           roughness: 1,
                                           isMetallic: false)]
            )
            rock.name = "rock"
            rock.scale = SIMD3(1, Float(0.55 + rng.next() * 0.4), Float(0.7 + rng.next() * 0.5))
            rock.orientation = simd_quatf(angle: rng.next() * 2 * .pi, axis: SIMD3(0, 1, 0))
            rock.position = SIMD3(position.x, groundHeight(position.x, position.y) + size * 0.35, position.y)
            cluster.addChild(rock)
        }

        // Dunes: flattened mounds half-buried in the soil.
        for _ in 0..<3 {
            let angle = Float(0.5 + rng.next() * 5.2)
            let radius = Float(0.17 + rng.next() * 0.08)
            let position = SIMD2<Float>(cos(angle) * radius, sin(angle) * radius)
            guard clearing.allSatisfy({ simd_distance($0, position) > 0.09 }) else { continue }

            let width = Float(0.035 + rng.next() * 0.035)
            let dune = ModelEntity(
                mesh: .generateSphere(radius: width),
                materials: [SimpleMaterial(color: UIColor(red: 0.74, green: 0.42, blue: 0.28, alpha: 1),
                                           roughness: 1,
                                           isMetallic: false)]
            )
            dune.name = "dune"
            dune.scale = SIMD3(1.6, 0.3, 1.2)
            dune.orientation = simd_quatf(angle: rng.next() * 2 * .pi, axis: SIMD3(0, 1, 0))
            dune.position = SIMD3(position.x, groundHeight(position.x, position.y) - width * 0.16, position.y)
            cluster.addChild(dune)
        }

        // Mesas on the crater rim: low, flat-topped blocks.
        for index in 0..<2 {
            let angle = Float(index) * 2.6 + 1.1
            let radius = Float(groundRadius) * 0.88
            let position = SIMD2<Float>(cos(angle) * radius, sin(angle) * radius)

            let mesa = ModelEntity(
                mesh: .generateBox(width: 0.07, height: 0.03, depth: 0.045),
                materials: [SimpleMaterial(color: UIColor(red: 0.62, green: 0.33, blue: 0.22, alpha: 1),
                                           roughness: 1,
                                           isMetallic: false)]
            )
            mesa.name = "mesa"
            mesa.orientation = simd_quatf(angle: angle, axis: SIMD3(0, 1, 0))
            mesa.position = SIMD3(position.x, groundHeight(position.x, position.y) + 0.008, position.y)
            cluster.addChild(mesa)
        }

        return cluster
    }

    /// A rover (or any surface item) standing on the terrain.
    private func makeRover(id: String,
                           assetName: String,
                           targetExtent: Float,
                           label: String,
                           at xz: SIMD2<Float>) -> Entity {
        let holder = Entity()
        holder.name = Self.itemPrefix + id
        holder.position = SIMD3(xz.x, Self.groundHeight(xz.x, xz.y), xz.y)

        let (model, lift) = Self.model(assetName: assetName, targetExtent: targetExtent)
        model.position.y = lift
        holder.addChild(model)
        holder.addChild(Self.label(text: label, height: targetExtent * 0.7 + 0.05))

        items.append(Item(id: id, holder: holder))
        return holder
    }

    /// Ingenuity hangs from a flight node so the take-off cycle can lift it.
    private func makeIngenuity(at xz: SIMD2<Float>) -> Entity {
        let holder = Entity()
        holder.name = Self.itemPrefix + "ingenuity"
        holder.position = SIMD3(xz.x, Self.groundHeight(xz.x, xz.y), xz.y)

        let flight = Entity()
        flight.name = "ingenuityFlight"

        let (model, lift) = Self.model(assetName: "25043_Ingenuity_v3", targetExtent: 0.05)
        model.position.y = lift
        flight.addChild(model)
        holder.addChild(flight)
        holder.addChild(Self.label(text: "Ingenuity", height: 0.21))

        ingenuityFlight = flight
        ingenuityYaw = model
        items.append(Item(id: "ingenuity", holder: holder))
        return holder
    }

    /// Loads a model, centres it on its own origin and scales its largest
    /// dimension to `targetExtent`. Returns the wrapper plus the lift needed
    /// so the model rests on its holder's origin instead of sinking into it.
    /// A tinted stand-in is used when the asset cannot be loaded.
    private static func model(assetName: String, targetExtent: Float) -> (entity: Entity, lift: Float) {
        guard let loaded = try? Entity.load(named: assetName) else {
            let standIn = ModelEntity(
                mesh: .generateBox(width: targetExtent,
                                   height: targetExtent * 0.5,
                                   depth: targetExtent * 0.6),
                materials: [SimpleMaterial(color: UIColor(red: 0.55, green: 0.30, blue: 0.20, alpha: 1),
                                           roughness: 0.8,
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

    /// Floating name label above an item, always facing the camera.
    private static func label(text: String, height: Float) -> Entity {
        let mesh = MeshResource.generateText(
            text,
            extrusionDepth: 0.001,
            font: .systemFont(ofSize: 0.018),
            containerFrame: CGRect(x: 0, y: 0, width: 1, height: 0.03),
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

    // MARK: Terrain

    /// Height of the generated soil at a point: gentle undulations plus a
    /// rising rim that turns the disc into the edge of a crater.
    static func groundHeight(_ x: Float, _ z: Float) -> Float {
        let r = (x * x + z * z).squareRoot()
        let undulation = 0.008 * sin(x * 19) * cos(z * 15) + 0.005 * sin((x + z) * 31)
        let rimProgress = max(0, (r - (groundRadius - 0.09)) / 0.09)
        return undulation + 0.03 * rimProgress * rimProgress
    }

    private static func groundNormal(_ x: Float, _ z: Float) -> SIMD3<Float> {
        let epsilon: Float = 0.01
        let dx = (groundHeight(x + epsilon, z) - groundHeight(x - epsilon, z)) / (2 * epsilon)
        let dz = (groundHeight(x, z + epsilon) - groundHeight(x, z - epsilon)) / (2 * epsilon)
        return simd_normalize(SIMD3(-dx, 1, -dz))
    }

    /// Radial grid mesh for the soil disc, with normals and UVs.
    private static func terrainMesh() throws -> MeshResource {
        let rings = 16
        let segments = 48

        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []

        positions.append(SIMD3(0, groundHeight(0, 0), 0))
        normals.append(groundNormal(0, 0))
        uvs.append(SIMD2(0.5, 0.5))

        for ring in 1...rings {
            let radius = groundRadius * Float(ring) / Float(rings)
            for segment in 0..<segments {
                let angle = Float(segment) / Float(segments) * 2 * .pi
                let x = cos(angle) * radius
                let z = sin(angle) * radius
                positions.append(SIMD3(x, groundHeight(x, z), z))
                normals.append(groundNormal(x, z))
                uvs.append(SIMD2(x / groundRadius * 0.5 + 0.5,
                                 z / groundRadius * 0.5 + 0.5))
            }
        }

        // Centre fan.
        for segment in 0..<segments {
            let near = UInt32(1 + segment)
            let far = UInt32(1 + (segment + 1) % segments)
            indices.append(contentsOf: [0, far, near])
        }

        // Ring quads.
        for ring in 1..<rings {
            let innerBase = 1 + (ring - 1) * segments
            let outerBase = 1 + ring * segments
            for segment in 0..<segments {
                let next = (segment + 1) % segments
                let inner = UInt32(innerBase + segment)
                let innerNext = UInt32(innerBase + next)
                let outer = UInt32(outerBase + segment)
                let outerNext = UInt32(outerBase + next)
                indices.append(contentsOf: [inner, innerNext, outer,
                                            innerNext, outerNext, outer])
            }
        }

        var descriptor = MeshDescriptor(name: "marsGround")
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.normals = MeshBuffers.Normals(normals)
        descriptor[MeshBuffers.textureCoordinates] = MeshBuffers.TextureCoordinates(uvs)
        descriptor.primitives = .triangles(indices)
        return try MeshResource.generate(from: [descriptor])
    }

    /// Speckled soil texture, generated once so the ground reads as dirt
    /// rather than a flat colour.
    private static func groundTexture() -> MaterialParameters.Texture? {
        let size = CGSize(width: 128, height: 128)
        let image = UIGraphicsImageRenderer(size: size).image { context in
            UIColor(red: 0.70, green: 0.37, blue: 0.24, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))

            var rng = SeededRandom(seed: 7)
            for _ in 0..<500 {
                let shade = CGFloat(rng.next())
                let diameter = CGFloat(rng.next()) * 4 + 1
                UIColor(red: 0.44 + shade * 0.34,
                        green: 0.22 + shade * 0.22,
                        blue: 0.14 + shade * 0.16,
                        alpha: 0.45).setFill()
                let origin = CGPoint(x: CGFloat(rng.next()) * size.width,
                                     y: CGFloat(rng.next()) * size.height)
                context.cgContext.fillEllipse(in: CGRect(origin: origin,
                                                         size: CGSize(width: diameter, height: diameter)))
            }
        }
        guard let cgImage = image.cgImage else { return nil }
        return try? MaterialParameters.Texture(
            TextureResource(image: cgImage, options: .init(semantic: .color))
        )
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
        for i in items.indices {
            let item = items[i]
            let difference = item.targetScale - item.holder.scale.x
            if abs(difference) > 0.001 {
                let eased = item.holder.scale.x + difference * min(1, frame * 12)
                item.holder.scale = SIMD3(repeating: eased)
            }
        }

        guard !isPaused else { return }
        updateIngenuity(delta: Double(frame) * speed)
    }

    /// Take-off, hover and landing cycle for the Ingenuity helicopter.
    private func updateIngenuity(delta: Double) {
        guard let flight = ingenuityFlight else { return }

        flightTime = (flightTime + delta).truncatingRemainder(dividingBy: Self.flightCycle)
        let time = Float(flightTime)
        let hoverHeight: Float = 0.12

        let height: Float
        if time < 3 {
            height = hoverHeight * smoothstep(time / 3)
        } else if time < 6 {
            height = hoverHeight + 0.004 * sin((time - 3) * 2)
        } else {
            height = hoverHeight * (1 - smoothstep((time - 6) / 3))
        }
        flight.position.y = height

        // Slowly turn while airborne so the rotors catch the light.
        if height > 0.01, let yaw = ingenuityYaw {
            yawAngle += Float(delta) * 1.6
            yaw.orientation = simd_quatf(angle: yawAngle, axis: SIMD3(0, 1, 0))
        }
    }

    private func smoothstep(_ value: Float) -> Float {
        let clamped = min(max(value, 0), 1)
        return clamped * clamped * (3 - 2 * clamped)
    }

    // MARK: Curiosity comparison

    func toggleCuriosity() {
        showsCuriosity.toggle()
        curiosityHolder?.isEnabled = showsCuriosity
        if !showsCuriosity, selectedMission?.id == "curiosity" {
            clearSelection()
        }
    }

    // MARK: Selection

    /// Maps a tapped entity to its mission and toggles the selection.
    func handleSelection(_ entity: Entity?) {
        guard let id = itemID(of: entity) else {
            clearSelection()
            return
        }
        if selectedMission?.id == id {
            clearSelection()
        } else {
            selectedMission = MarsMissionData.missions.first { $0.id == id }
            updateHighlight()
        }
    }

    func clearSelection() {
        selectedMission = nil
        updateHighlight()
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

    private func updateHighlight() {
        let selectedID = selectedMission.map { Self.itemPrefix + $0.id }
        for i in items.indices {
            items[i].targetScale = items[i].holder.name == selectedID ? 1.3 : 1
        }
    }
}

/// Deterministic pseudo-random numbers, so the terrain is identical on every
/// launch.
private struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> Float {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Float(state >> 40) / Float(1 << 24)
    }
}
