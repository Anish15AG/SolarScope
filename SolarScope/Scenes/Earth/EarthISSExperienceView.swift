import SwiftUI

/// Earth & ISS Explorer: the shared AR shell plus the scene-specific
/// controls and the selected-station info panel.
struct EarthISSExperienceView: View {
    @StateObject private var scene = EarthScene()

    var body: some View {
        ZStack {
            ARExperienceView(
                title: Experience.earthAndISS.title,
                makeContent: { scene.makeRoot() },
                onEntitySelected: { scene.handleSelection($0) },
                toolbar: { pauseButton }
            )

            if scene.issSelected {
                VStack {
                    Spacer(minLength: 0)
                    ISSInfoPanel { scene.clearSelection() }
                        .padding(.horizontal, Layout.spacing)
                        // Clears the AR bottom bar (Remove · Reset · Pause).
                        .padding(.bottom, 96)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: scene.issSelected)
        .onAppear {
            // Pre-build the scene while the camera starts, so tapping a
            // surface to place it never stalls on asset loading.
            _ = scene.makeRoot()
            scene.startAnimating()
        }
        .onDisappear { scene.stopAnimating() }
    }

    private var pauseButton: some View {
        Button {
            scene.togglePaused()
        } label: {
            Label(scene.isPaused ? "Play" : "Pause",
                  systemImage: scene.isPaused ? "play.fill" : "pause.fill")
        }
    }
}

#Preview {
    NavigationStack {
        EarthISSExperienceView()
    }
    .preferredColorScheme(.dark)
}
