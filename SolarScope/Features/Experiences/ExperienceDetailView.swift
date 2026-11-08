import SwiftUI

/// Introduction page for an experience, with the action that launches AR.
struct ExperienceDetailView: View {
    let experience: Experience

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.spacing) {
                ZStack {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [experience.tint.opacity(0.35), experience.tint.opacity(0.10)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: experience.iconName)
                        .font(.system(size: 54, weight: .semibold))
                        .foregroundStyle(experience.tint)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 170)

                VStack(alignment: .leading, spacing: 6) {
                    Text(experience.title)
                        .font(.title.bold())
                    Text(experience.tagline)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(experience.summary)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: Layout.spacing) {
                    SectionHeader("What you'll explore")
                    ForEach(experience.highlights, id: \.self) { highlight in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(experience.tint)
                            Text(highlight)
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(.top, 4)

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "camera.fill")
                        .foregroundStyle(.secondary)
                    Text("Uses the rear camera with world tracking. No LiDAR or special hardware is required.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(Layout.spacing)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardBackground(Theme.surfaceRaised)
            }
            .padding(Layout.spacing)
            .constrainedWidth()
            .padding(.bottom, 96)
        }
        .screenBackground()
        .navigationTitle(experience.title)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { launchBar }
    }

    private var launchBar: some View {
        HStack {
            NavigationLink {
                experienceDestination
            } label: {
                Label("Launch AR Experience", systemImage: "arkit")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(experience.tint)
        }
        .padding(.horizontal, Layout.spacing)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: Rectangle())
    }

    /// Experiences with a dedicated scene provide their own view; the
    /// remaining ones currently launch the shared shell with preview content.
    @ViewBuilder
    private var experienceDestination: some View {
        switch experience {
        case .solarSystem:
            SolarSystemExperienceView()
        case .marsExploration, .earthAndISS:
            ARExperienceView(
                title: experience.title,
                makeContent: { ExperienceContent.make(for: experience) }
            )
        }
    }
}

#Preview {
    NavigationStack {
        ExperienceDetailView(experience: .solarSystem)
    }
    .preferredColorScheme(.dark)
}
