import SwiftUI

/// Solar System Explorer: the shared AR shell plus the scene-specific
/// controls and the selected-planet info panel.
struct SolarSystemExperienceView: View {
    @StateObject private var scene = SolarSystemScene()

    var body: some View {
        ZStack {
            ARExperienceView(
                title: Experience.solarSystem.title,
                makeContent: { scene.makeRoot() },
                onEntitySelected: { scene.handleSelection($0) },
                toolbar: { pauseButton }
            )

            if let planet = scene.selectedPlanet {
                VStack {
                    Spacer(minLength: 0)
                    PlanetInfoPanel(planet: planet) { scene.clearSelection() }
                        .padding(.horizontal, Layout.spacing)
                        // Clears the AR bottom bar (Remove · Reset · Pause).
                        .padding(.bottom, 96)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: scene.selectedPlanet)
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
        SolarSystemExperienceView()
    }
    .preferredColorScheme(.dark)
}
