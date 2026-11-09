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
            PlanetThumb(planet: planet, size: 80)

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

/// Miniature fixed thumbnail rendered from the body's own USDZ model,
/// falling back to a tinted sphere while loading or if it cannot load.
struct PlanetThumb: View {
    let planet: Planet
    var size: CGFloat = 80

    var body: some View {
        ModelThumbnail(assetName: planet.assetName, fallbackTint: UIColor(planet.tint))
            // Thumbnails must never swallow the tile's navigation tap.
            .allowsHitTesting(false)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
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
                    PlanetThumb(planet: planet, size: 84)

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
