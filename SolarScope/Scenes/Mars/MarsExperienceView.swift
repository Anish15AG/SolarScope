import SwiftUI

/// Mars Exploration: the shared AR shell plus the scene-specific controls
/// and the selected-mission info panel.
struct MarsExperienceView: View {
    @StateObject private var scene = MarsScene()

    var body: some View {
        ZStack {
            ARExperienceView(
                title: Experience.marsExploration.title,
                makeContent: { scene.makeRoot() },
                onEntitySelected: { scene.handleSelection($0) },
                toolbar: { controls }
            )

            if let mission = scene.selectedMission {
                VStack {
                    Spacer(minLength: 0)
                    MarsInfoPanel(mission: mission) { scene.clearSelection() }
                        .padding(.horizontal, Layout.spacing)
                        // Clears the AR bottom bar (Remove · Reset · controls).
                        .padding(.bottom, 96)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: scene.selectedMission)
        .onAppear {
            // Pre-build the scene while the camera starts, so tapping a
            // surface to place it never stalls on asset loading.
            _ = scene.makeRoot()
            scene.startAnimating()
        }
        .onDisappear { scene.stopAnimating() }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button {
                scene.togglePaused()
            } label: {
                Label(scene.isPaused ? "Play" : "Pause",
                      systemImage: scene.isPaused ? "play.fill" : "pause.fill")
            }

            Button {
                scene.toggleCuriosity()
            } label: {
                Label(scene.showsCuriosity ? "Hide Curiosity" : "Show Curiosity",
                      systemImage: "car.fill")
            }
        }
    }
}

#Preview {
    NavigationStack {
        MarsExperienceView()
    }
    .preferredColorScheme(.dark)
}
