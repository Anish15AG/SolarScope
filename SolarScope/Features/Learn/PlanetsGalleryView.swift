import SwiftUI

/// Grid of the Sun and the eight planets.
struct PlanetsGalleryView: View {
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: Layout.spacing)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.spacing) {
                SectionHeader(
                    "The Sun & Eight Planets",
                    subtitle: "Tap a body for its vital statistics"
                )

                LazyVGrid(columns: columns, spacing: Layout.spacing) {
                    ForEach(PlanetData.all) { planet in
                        NavigationLink(value: planet) {
                            planetTile(planet)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(Layout.spacing)
            .constrainedWidth()
        }
        .screenBackground()
        .navigationTitle("Planets")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func planetTile(_ planet: Planet) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(planet.tint.opacity(0.20))
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [planet.tint, planet.tint.opacity(0.45)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 46, height: 46)
            }
            .frame(width: 74, height: 74)

            Text(planet.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            Text(planet.classification)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Layout.spacing)
        .cardBackground()
    }
}

/// Detailed data for a single Sun or planet entry.
struct PlanetDetailView: View {
    let planet: Planet

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: Layout.spacing)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.spacing) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(planet.tint.opacity(0.20))
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [planet.tint, planet.tint.opacity(0.45)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 54, height: 54)
                    }
                    .frame(width: 84, height: 84)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(planet.name)
                            .font(.title.bold())
                        Text(planet.classification)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                LazyVGrid(columns: columns, spacing: Layout.spacing) {
                    InfoRow(label: "Diameter", value: planet.diameterText)
                    InfoRow(label: "Distance from Sun", value: planet.distanceFromSun)
                    InfoRow(label: "Orbital period", value: planet.orbitalPeriod)
                    InfoRow(label: "Length of day", value: planet.dayLength)
                    InfoRow(label: "Moons", value: planet.moons.map(String.init) ?? "—")
                    InfoRow(label: "Composition", value: planet.composition)
                }
                .padding(Layout.spacing)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardBackground()

                FactCallout(text: planet.fact)
            }
            .padding(Layout.spacing)
            .constrainedWidth()
        }
        .screenBackground()
        .navigationTitle(planet.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PlanetDetailView(planet: PlanetData.planets[2])
    }
    .preferredColorScheme(.dark)
}
