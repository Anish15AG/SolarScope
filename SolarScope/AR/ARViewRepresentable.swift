import ARKit
import RealityKit
import SwiftUI

/// Bridges RealityKit's `ARView` into SwiftUI.
struct ARViewRepresentable: UIViewRepresentable {
    @ObservedObject var controller: ARController
    let makeContent: @MainActor () -> Entity
    let onEntitySelected: (@MainActor (Entity?) -> Void)?

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero,
                          cameraMode: .ar,
                          automaticallyConfigureSession: false)
        controller.attach(view: view,
                          makeContent: makeContent,
                          onEntitySelected: onEntitySelected)
        return view
    }

    func updateUIView(_ view: ARView, context: Context) {}

    static func dismantleUIView(_ view: ARView, coordinator: ()) {
        view.session.pause()
    }
}
