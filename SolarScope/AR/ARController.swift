import ARKit
import AVFoundation
import Combine
import RealityKit
import SwiftUI
import UIKit

/// Owns the AR session, the placement flow and the gestures shared by every
/// AR experience.
///
/// Experience-specific content is supplied by the view through `makeContent`,
/// so this type stays free of scene details.
@MainActor
final class ARController: NSObject, ObservableObject {

    enum Phase: Equatable {
        /// Camera is being authorised / the session is starting.
        case starting
        /// The user (or system) denied camera access.
        case permissionDenied
        /// Session running, no usable surface found yet.
        case scanning
        /// A surface is available, nothing placed yet.
        case ready
        /// Content has been placed in the scene.
        case placed
        /// The session could not run.
        case failed(String)
    }

    @Published private(set) var phase: Phase = .starting
    @Published private(set) var isSurfaceDetected = false
    @Published private(set) var isTrackingLimited = false

    private(set) var rootEntity: AnchorEntity?

    weak private(set) var arView: ARView?

    private var makeContent: (@MainActor () -> Entity)?
    private var onEntitySelected: (@MainActor (Entity?) -> Void)?
    private var monitor: Task<Void, Never>?
    private var prepTask: Task<Void, Never>?
    private weak var gestureView: ARView?
    private var startingDeadline: Date?

    // Gesture bookkeeping.
    private var scaleAtGestureStart: Float = 1
    private var rotationAtGestureStart = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
    private var dragOffset = SIMD3<Float>.zero

    // MARK: Lifecycle

    func attach(view: ARView,
                makeContent: @escaping @MainActor () -> Entity,
                onEntitySelected: (@MainActor (Entity?) -> Void)?) {
        arView = view
        self.makeContent = makeContent
        self.onEntitySelected = onEntitySelected
        if gestureView !== view {
            installGestures(on: view)
            gestureView = view
        }
        // `makeUIView` runs inside a SwiftUI view update, so the session must
        // not publish state changes synchronously from here.
        DispatchQueue.main.async { [weak self] in
            self?.start()
        }
    }

    /// Starts the session (requesting camera access if needed).
    func start() {
        guard arView != nil else { return }
        guard ARWorldTrackingConfiguration.isSupported else {
            phase = .failed("World tracking is not available on this device.")
            return
        }
        if phase != .starting {
            phase = .starting
        }
        startingDeadline = Date().addingTimeInterval(6)
        beginMonitoring()
        prepTask?.cancel()
        prepTask = Task { [weak self] in
            await self?.prepareCamera()
        }
    }

    /// Restores the session when the view reappears.
    func resume() {
        guard arView != nil else { return }
        switch phase {
        case .starting:
            start()
        case .scanning, .ready, .placed:
            runSession(reset: false)
        case .permissionDenied, .failed:
            break
        }
    }

    /// Pauses the session when the view disappears.
    func pause() {
        prepTask?.cancel()
        prepTask = nil
        arView?.session.pause()
        monitor?.cancel()
        monitor = nil
    }

    // MARK: Session

    private func prepareCamera() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            guard !Task.isCancelled else { return }
            runSession(reset: true)
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard !Task.isCancelled else { return }
            if granted {
                runSession(reset: true)
            } else {
                phase = .permissionDenied
            }
        case .denied, .restricted:
            phase = .permissionDenied
        @unknown default:
            phase = .permissionDenied
        }
    }

    private func runSession(reset: Bool) {
        guard let arView else { return }

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        arView.session.run(configuration, options: reset ? [.resetTracking, .removeExistingAnchors] : [])

        startingDeadline = Date().addingTimeInterval(6)
        if reset && rootEntity == nil {
            isSurfaceDetected = false
            phase = .scanning
        }
        beginMonitoring()
    }

    /// Polls the session for tracking quality and surface availability.
    ///
    /// `ARView` owns its session delegate, so the session is observed by
    /// reading its current frame instead of replacing the delegate.
    private func beginMonitoring() {
        monitor?.cancel()
        monitor = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                self.poll()
                try? await Task.sleep(for: .milliseconds(400))
            }
        }
    }

    private func poll() {
        guard let arView else { return }
        let bounds = arView.bounds
        guard bounds.width > 1, bounds.height > 1 else { return }

        switch phase {
        case .starting:
            if arView.session.currentFrame != nil {
                phase = .scanning
            } else if let deadline = startingDeadline, Date() > deadline {
                phase = .failed("The camera session could not be started. Check camera access in Settings.")
            }
            return
        case .permissionDenied, .failed:
            return
        case .scanning, .ready, .placed:
            break
        }

        if let camera = arView.session.currentFrame?.camera {
            if case .limited = camera.trackingState {
                isTrackingLimited = true
            } else {
                isTrackingLimited = false
            }
        }

        guard phase == .scanning || phase == .ready else { return }

        let centre = CGPoint(x: bounds.midX, y: bounds.midY)
        let detected = !arView.raycast(from: centre,
                                       allowing: .existingPlaneInfinite,
                                       alignment: .horizontal).isEmpty
        guard detected != isSurfaceDetected else { return }
        isSurfaceDetected = detected
        phase = detected ? .ready : .scanning
    }

    // MARK: Placement

    func place(at point: CGPoint) {
        guard phase == .scanning || phase == .ready,
              rootEntity == nil,
              let arView,
              let makeContent,
              let hit = raycast(at: point)
        else { return }

        let content = makeContent()
        content.generateCollisionShapes(recursive: true)

        let anchor = AnchorEntity(world: position(of: hit))
        anchor.addChild(content)
        arView.scene.addAnchor(anchor)

        rootEntity = anchor
        isSurfaceDetected = true
        phase = .placed
    }

    /// Removes the placed content but keeps tracking running.
    func removeContent() {
        guard let arView, let root = rootEntity else { return }
        arView.scene.removeAnchor(root)
        rootEntity = nil
        phase = isSurfaceDetected ? .ready : .scanning
    }

    /// Clears the content and restarts tracking from scratch.
    func reset() {
        removeContent()
        runSession(reset: true)
    }

    // MARK: Gestures

    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        guard let arView else { return }
        let point = recognizer.location(in: arView)
        switch phase {
        case .scanning, .ready:
            place(at: point)
        case .placed:
            onEntitySelected?(arView.entity(at: point))
        case .starting, .permissionDenied, .failed:
            break
        }
    }

    @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        guard phase == .placed, let arView, let root = rootEntity else { return }
        let point = recognizer.location(in: arView)

        switch recognizer.state {
        case .began:
            dragOffset = raycast(at: point).map { root.position - position(of: $0) } ?? .zero
        case .changed:
            if let hit = raycast(at: point) {
                root.position = position(of: hit) + dragOffset
            }
        default:
            break
        }
    }

    @objc private func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        guard phase == .placed, let root = rootEntity else { return }

        switch recognizer.state {
        case .began:
            scaleAtGestureStart = root.scale.x
        case .changed:
            let factor = Float(min(max(recognizer.scale, 0.3), 3.0))
            root.scale = SIMD3<Float>(repeating: scaleAtGestureStart * factor)
        default:
            break
        }
    }

    @objc private func handleRotate(_ recognizer: UIRotationGestureRecognizer) {
        guard phase == .placed, let root = rootEntity else { return }

        switch recognizer.state {
        case .began:
            rotationAtGestureStart = root.orientation
        case .changed:
            let delta = simd_quatf(angle: Float(recognizer.rotation),
                                   axis: SIMD3<Float>(0, 1, 0))
            root.orientation = simd_normalize(rotationAtGestureStart * delta)
        default:
            break
        }
    }

    private func installGestures(on view: ARView) {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        let rotate = UIRotationGestureRecognizer(target: self, action: #selector(handleRotate(_:)))

        for recognizer in [tap, pan, pinch, rotate] as [UIGestureRecognizer] {
            recognizer.delegate = self
            view.addGestureRecognizer(recognizer)
        }
    }

    // MARK: Helpers

    private func raycast(at point: CGPoint) -> simd_float4x4? {
        guard let arView else { return nil }
        let detected = arView.raycast(from: point,
                                      allowing: .existingPlaneInfinite,
                                      alignment: .horizontal)
        if let hit = detected.first { return hit.worldTransform }
        return arView.raycast(from: point,
                              allowing: .estimatedPlane,
                              alignment: .horizontal).first?.worldTransform
    }

    private func position(of transform: simd_float4x4) -> SIMD3<Float> {
        SIMD3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }
}

extension ARController: UIGestureRecognizerDelegate {
    /// Placement, movement, scaling and rotation are independent gestures.
    nonisolated func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                       shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}
