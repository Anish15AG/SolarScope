import SwiftUI

/// Landing screen: branding, a short introduction and the featured experiences.
struct HomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                    brandHeader

                    VStack(alignment: .leading, spacing: Layout.spacing) {
                        SectionHeader(
                            "Featured Experiences",
                            subtitle: "Three ways to explore in augmented reality"
                        )
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 300), spacing: Layout.spacing)],
                            spacing: Layout.spacing
                        ) {
                            ForEach(Experience.allCases) { experience in
                                ExperienceCard(experience: experience)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: Layout.spacing) {
                        SectionHeader(
                            "Learning Catalogue",
                            subtitle: "Read up before you launch"
                        )
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 300), spacing: Layout.spacing)],
                            spacing: Layout.spacing
                        ) {
                            NavigationLink { PlanetsGalleryView() } label: {
                                CatalogueCard(
                                    title: "The Sun & Planets",
                                    subtitle: "Nine bodies, key facts and figures",
                                    iconName: "globe.americas.fill",
                                    tint: Theme.orbital
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink { MarsMissionsView() } label: {
                                CatalogueCard(
                                    title: "Mars Missions",
                                    subtitle: "Landers and rovers since 1976",
                                    iconName: "car.fill",
                                    tint: Experience.marsExploration.tint
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink { ISSView() } label: {
                                CatalogueCard(
                                    title: "Space Station",
                                    subtitle: "The ISS in low Earth orbit",
                                    iconName: "antenna.radiowaves.left.and.right",
                                    tint: Theme.accent
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("SolarScope · Built for iPad · Markerless AR")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
                .padding(Layout.spacing)
                .constrainedWidth()
            }
            .screenBackground()
            .learnDestinations()
        }
    }

    private var brandHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Theme.accent, Theme.accent.opacity(0.55)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Color.black.opacity(0.75))
                }
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 2) {
                    Text("SolarScope")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    Text("Augmented reality space exploration")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Text("Bring the Solar System, Mars exploration and the International Space Station into your own space with interactive 3D models you can place, move and inspect.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Compact navigation tile used in the Home catalogue section.
private struct CatalogueCard: View {
    let title: String
    let subtitle: String
    let iconName: String
    let tint: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tint.opacity(0.18))
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tint)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(Layout.spacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground()
    }
}

#Preview {
    HomeView()
}
