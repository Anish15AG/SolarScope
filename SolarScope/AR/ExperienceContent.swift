import RealityKit
import SwiftUI
import UIKit

/// Builds the root entity placed into AR for a given experience.
enum ExperienceContent {
    @MainActor
    static func make(for experience: Experience) -> Entity {
        // Phase 2: every experience shares the tinted placeholder scene.
        // Experience-specific scenes arrive in their own phase.
        PreviewSceneContent.make(tint: experience.tint)
    }
}

/// Tinted stand-in scene: a placement pad with a floating orb, so the
/// placement flow can be tested before real models are loaded.
enum PreviewSceneContent {
    @MainActor
    static func make(tint: Color) -> Entity {
        let root = Entity()
        root.name = "previewContent"

        let pad = ModelEntity(
            mesh: .generateCylinder(height: 0.008, radius: 0.24),
            materials: [
                SimpleMaterial(color: UIColor(white: 0.85, alpha: 0.40),
                               roughness: 0.9,
                               isMetallic: false)
            ]
        )
        pad.name = "pad"
        pad.position.y = 0.004
        root.addChild(pad)

        let disc = ModelEntity(
            mesh: .generateCylinder(height: 0.012, radius: 0.16),
            materials: [
                SimpleMaterial(color: UIColor(tint).withAlphaComponent(0.85),
                               roughness: 0.5,
                               isMetallic: false)
            ]
        )
        disc.name = "disc"
        disc.position.y = 0.014
        root.addChild(disc)

        let orb = ModelEntity(
            mesh: .generateSphere(radius: 0.09),
            materials: [
                SimpleMaterial(color: UIColor(tint),
                               roughness: 0.35,
                               isMetallic: false)
            ]
        )
        orb.name = "orb"
        orb.position.y = 0.13
        root.addChild(orb)

        return root
    }
}
