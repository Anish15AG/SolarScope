import SwiftUI

/// Bottom panel showing the data of the selected world.
///
/// Rendered over the AR feed once a body has been tapped; the close button
/// (or tapping the body again) dismisses it.
struct PlanetInfoPanel: View {
    let planet: Planet
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)],
                      spacing: 12) {
                InfoRow(label: "Diameter", value: planet.diameterText)
                InfoRow(label: "Distance from Sun", value: planet.distanceFromSun)
                InfoRow(label: "Orbital period", value: planet.orbitalPeriod)
                InfoRow(label: "Day length", value: planet.dayLength)
                if let moons = planet.moons {
                    InfoRow(label: "Moons", value: moons == 0 ? "None" : String(moons))
                }
            }

            InfoRow(label: "Composition", value: planet.composition)

            FactCallout(text: planet.fact)
        }
        .padding(Layout.spacing)
        .frame(maxWidth: 640)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
    }

    private var header: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(planet.tint)
                .frame(width: 14, height: 14)
            VStack(alignment: .leading, spacing: 2) {
                Text(planet.name)
                    .font(.title3.bold())
                Text(planet.classification)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            Button {
                onClose()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
    }
}

#Preview {
    ZStack {
        Color.black
        PlanetInfoPanel(planet: PlanetData.planets[2]) {}
            .padding()
    }
}
