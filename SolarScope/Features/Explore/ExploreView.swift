import SwiftUI

/// Lists the three AR experiences with an introduction and a launch action.
struct ExploreView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Layout.spacing) {
                    SectionHeader(
                        "Explore",
                        subtitle: "Choose an experience to launch in augmented reality"
                    )

                    ForEach(Experience.allCases) { experience in
                        ExperienceCard(experience: experience, style: .detailed)
                    }

                    preparationNote
                }
                .padding(Layout.spacing)
                .constrainedWidth()
            }
            .screenBackground()
            .learnDestinations()
        }
    }

    private var preparationNote: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.max.fill")
                .foregroundStyle(Theme.accent)
            VStack(alignment: .leading, spacing: 4) {
                Text("Before you start")
                    .font(.subheadline.weight(.semibold))
                Text("Point your iPad at a well-lit, textured flat surface and move it slowly so the scene can be detected. A table or the floor works well.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Layout.spacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground(Theme.surfaceRaised)
    }
}

#Preview {
    ExploreView()
}
