import SwiftUI

/// Placeholder shown until the AR session is wired up in a later phase.
struct PlaceholderARView: View {
    let experience: Experience

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Theme.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .strokeBorder(Theme.hairline, lineWidth: 1)
                        .background(Circle().fill(Theme.surface.opacity(0.6)))
                    Image(systemName: experience.iconName)
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(experience.tint)
                }
                .frame(width: 130, height: 130)

                Text(experience.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("Live camera tracking starts here. This build includes the interface only — the augmented reality scene arrives with the next update.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Label("Scan a flat surface to place the scene", systemImage: "plus.circle.dashed")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(.thinMaterial))
            }
            .padding(28)
            .frame(maxWidth: 520)
            .cardBackground(Theme.surface.opacity(0.85))
            .padding(Layout.spacing)
        }
        .navigationTitle(experience.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PlaceholderARView(experience: .marsExploration)
    }
    .preferredColorScheme(.dark)
}
