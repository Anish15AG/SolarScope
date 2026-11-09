import SceneKit
import simd
import SwiftUI
import UIKit

/// Fixed miniature render of a USDZ asset for grid and list tiles.
///
/// SceneKit is used instead of an AR view so each thumbnail is a plain,
/// lightweight view: it renders a single frame on appearance and then stops,
/// interaction is disabled so tiles keep their navigation tap, and a failed
/// load falls back to a tinted sphere.
struct ModelThumbnail: UIViewRepresentable {
    let assetName: String
    let fallbackTint: UIColor

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView(frame: .zero)
        view.backgroundColor = .clear
        view.antialiasingMode = .multisampling4X
        view.isUserInteractionEnabled = false
        view.autoenablesDefaultLighting = true

        if let url = Bundle.main.url(forResource: assetName, withExtension: "usdz"),
           let scene = try? SCNScene(url: url, options: nil) {
            Self.normalizeGeometry(in: scene)
            // Tilt like a planet's axis so ringed bodies (Saturn) present
            // their rings as an ellipse instead of an edge-on line.
            scene.rootNode.eulerAngles.x = Self.presentationPitch
            view.scene = scene
            view.pointOfView = Self.framingCamera(for: scene)
        } else {
            view.scene = Self.fallbackScene(tint: fallbackTint)
            view.pointOfView = Self.framingCamera(for: view.scene!)
        }

        // One frame now, nothing afterwards: the thumbnail is static.
        view.isPlaying = false
        DispatchQueue.main.async { _ = view.snapshot() }
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}

    // MARK: Helpers

    /// ≈23.4°, the same pitch as Earth's axis.
    private static let presentationPitch: Float = 0.409

    /// Rebuilds every triangle element with an explicit index size.
    ///
    /// USDZ assets loaded through `SCNScene(url:)` can arrive with index data
    /// whose declared width does not match the buffer, in which case the mesh
    /// silently draws nothing. Re-declaring the same bytes with the width
    /// implied by the buffer size makes the geometry render.
    private static func normalizeGeometry(in scene: SCNScene) {
        scene.rootNode.enumerateChildNodes { node, _ in
            guard let geo = node.geometry, !geo.elements.isEmpty else { return }

            var changed = false
            let elements = geo.elements.map { element -> SCNGeometryElement in
                let indices: Int
                switch element.primitiveType {
                case .triangles: indices = 3
                case .line: indices = 2
                case .point: indices = 1
                default: return element
                }
                let expected = element.primitiveCount * indices
                guard expected > 0, element.data.count % expected == 0 else { return element }
                let bytesPerIndex = element.data.count / expected
                guard bytesPerIndex == 2 || bytesPerIndex == 4 else { return element }
                changed = true
                return SCNGeometryElement(
                    data: element.data,
                    primitiveType: element.primitiveType,
                    primitiveCount: element.primitiveCount,
                    bytesPerIndex: bytesPerIndex
                )
            }

            guard changed else { return }
            let rebuilt = SCNGeometry(sources: geo.sources, elements: elements)
            rebuilt.materials = geo.materials
            node.geometry = rebuilt
        }
    }

    /// Orthographic camera that frames the scene's bounding box head-on.
    ///
    /// The box is taken in world space so a pitched root node (see
    /// `presentationPitch`) is framed by the content the viewer actually sees.
    private static func framingCamera(for scene: SCNScene) -> SCNNode {
        let local = scene.rootNode.boundingBox
        let transform = scene.rootNode.simdWorldTransform

        var lo = SIMD3<Float>(repeating: Float.greatestFiniteMagnitude)
        var hi = SIMD3<Float>(repeating: -Float.greatestFiniteMagnitude)
        for x in [local.min.x, local.max.x] {
            for y in [local.min.y, local.max.y] {
                for z in [local.min.z, local.max.z] {
                    let world = transform * SIMD4<Float>(x, y, z, 1)
                    lo = simd_min(lo, SIMD3<Float>(world.x, world.y, world.z))
                    hi = simd_max(hi, SIMD3<Float>(world.x, world.y, world.z))
                }
            }
        }

        let center = SCNVector3((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, (lo.z + hi.z) / 2)
        let extent = Swift.max(Swift.max(hi.x - lo.x, hi.y - lo.y), 0.001)

        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = Double(extent) * 0.62
        camera.zNear = 0.1
        camera.zFar = Double(extent) * 4 + 1000

        let node = SCNNode()
        node.camera = camera
        node.position = SCNVector3(center.x, center.y, hi.z + extent * 2)
        return node
    }

    /// Tinted sphere shown when the asset cannot be loaded.
    private static func fallbackScene(tint: UIColor) -> SCNScene {
        let scene = SCNScene()
        let sphere = SCNSphere(radius: 0.5)
        let material = SCNMaterial()
        material.diffuse.contents = tint
        material.lightingModel = .lambert
        sphere.firstMaterial = material
        scene.rootNode.addChildNode(SCNNode(geometry: sphere))
        return scene
    }
}
