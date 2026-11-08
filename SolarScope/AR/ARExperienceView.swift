import RealityKit
import SwiftUI
import UIKit

/// Full-screen AR shell shared by every experience.
///
/// The shell owns no scene details: content arrives through `makeContent`,
/// and experience-specific controls can be added through `toolbar`.
struct ARExperienceView<Toolbar: View>: View {
    let title: String
    let makeContent: @MainActor () -> Entity
    let onEntitySelected: (@MainActor (Entity?) -> Void)?
    let toolbar: Toolbar

    @StateObject private var controller = ARController()
    @State private var showsGestureHint = false
    @AppStorage(SettingsKey.showPlacementHints) private var showPlacementHints = true

    init(title: String,
         makeContent: @escaping @MainActor () -> Entity,
         onEntitySelected: (@MainActor (Entity?) -> Void)? = nil,
         @ViewBuilder toolbar: () -> Toolbar) {
        self.title = title
        self.makeContent = makeContent
        self.onEntitySelected = onEntitySelected
        self.toolbar = toolbar()
    }

    var body: some View {
        ZStack {
            ARViewRepresentable(controller: controller,
                                makeContent: makeContent,
                                onEntitySelected: onEntitySelected)
                .ignoresSafeArea()

            if controller.phase == .scanning || controller.phase == .ready {
                ReticleView(isReady: controller.phase == .ready)
            }

            guidanceLayer
            statusOverlay
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: controller.phase) { await runGestureHint() }
        .onAppear { controller.resume() }
        .onDisappear { controller.pause() }
    }

    // MARK: Overlays

    @ViewBuilder
    private var statusOverlay: some View {
        switch controller.phase {
        case .starting:
            ZStack {
                Color.black.opacity(0.55).ignoresSafeArea()
                VStack(spacing: 14) {
                    ProgressView()
                        .tint(.white)
                    Text("Starting the camera…")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
            }
            .transition(.opacity)
        case .permissionDenied:
            messagePanel(
                icon: "camera.fill",
                title: "Camera Access Needed",
                message: "SolarScope uses the camera to place models in your space. Allow camera access in Settings, then return to this screen.",
                buttonTitle: "Open Settings",
                action: openSettings
            )
            .transition(.opacity)
        case .failed(let message):
            messagePanel(
                icon: "exclamationmark.triangle.fill",
                title: "AR Unavailable",
                message: message,
                buttonTitle: "Try Again",
                action: { controller.start() }
            )
            .transition(.opacity)
        case .scanning, .ready, .placed:
            EmptyView()
        }
    }

    @ViewBuilder
    private var guidanceLayer: some View {
        switch controller.phase {
        case .starting, .permissionDenied, .failed:
            EmptyView()
        case .scanning, .ready, .placed:
            VStack(spacing: 12) {
                topChips
                Spacer()
                if controller.phase != .placed, showPlacementHints {
                    Text(controller.phase == .scanning
                         ? "Move your iPad slowly to find a flat surface"
                         : "Tap the centre of the screen to place the scene")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                        .transition(.opacity)
                }
                if showsGestureHint {
                    Text("Drag to move · Pinch to scale · Twist to rotate")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(.ultraThinMaterial, in: Capsule())
                        .transition(.opacity)
                }
                bottomBar
            }
            .padding(Layout.spacing)
            .animation(.easeInOut(duration: 0.25), value: showsGestureHint)
            .animation(.easeInOut(duration: 0.25), value: controller.phase)
        }
    }

    private var topChips: some View {
        HStack {
            if controller.isTrackingLimited {
                Label("Tracking limited", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.yellow)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(.ultraThinMaterial, in: Capsule())
                    .transition(.opacity)
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var bottomBar: some View {
        if controller.phase == .placed {
            HStack(spacing: 12) {
                Button {
                    controller.removeContent()
                } label: {
                    Label("Remove", systemImage: "trash")
                }
                Button {
                    controller.reset()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }
                toolbar
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .tint(Theme.accent)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func messagePanel(icon: String,
                              title: String,
                              message: String,
                              buttonTitle: String,
                              action: @escaping () -> Void) -> some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                Text(title)
                    .font(.title3.bold())
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button(buttonTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
            }
            .padding(28)
            .frame(maxWidth: 440)
            .cardBackground(Theme.surface)
            .padding(Layout.spacing)
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: Hints

    private func runGestureHint() async {
        guard controller.phase == .placed else {
            showsGestureHint = false
            return
        }
        showsGestureHint = true
        try? await Task.sleep(for: .seconds(4))
        guard !Task.isCancelled else { return }
        showsGestureHint = false
    }
}

/// Centre-of-screen placement marker: dashed while scanning, solid once a
/// surface is found.
private struct ReticleView: View {
    let isReady: Bool

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    isReady ? Theme.accent : Color.white.opacity(0.7),
                    style: StrokeStyle(lineWidth: 2, dash: isReady ? [] : [7, 7])
                )
            Circle()
                .fill(isReady ? Theme.accent : Color.white.opacity(0.7))
                .frame(width: 6, height: 6)
        }
        .frame(width: 56, height: 56)
        .shadow(color: .black.opacity(0.35), radius: 3)
        .animation(.easeInOut(duration: 0.2), value: isReady)
    }
}

/// Convenience entry point for experiences without extra controls.
extension ARExperienceView where Toolbar == EmptyView {
    init(title: String,
         makeContent: @escaping @MainActor () -> Entity,
         onEntitySelected: (@MainActor (Entity?) -> Void)? = nil) {
        self.init(title: title,
                  makeContent: makeContent,
                  onEntitySelected: onEntitySelected) { EmptyView() }
    }
}
