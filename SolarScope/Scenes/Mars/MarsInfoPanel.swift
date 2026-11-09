import SwiftUI

/// Bottom panel showing the data of the selected Mars mission.
///
/// Rendered over the AR feed once a rover or helicopter has been tapped; the
/// close button (or tapping the item again) dismisses it.
struct MarsInfoPanel: View {
    let mission: MarsMission
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)],
                      spacing: 12) {
                InfoRow(label: "Year", value: mission.year)
                InfoRow(label: "Agency", value: mission.agency)
                InfoRow(label: "Status", value: mission.status)
            }

            Text(mission.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(mission.highlights, id: \.self) { highlight in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Experience.marsExploration.tint)
                        Text(highlight)
                            .font(.footnote)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                }
            }
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
                .fill(Experience.marsExploration.tint)
                .frame(width: 14, height: 14)
            VStack(alignment: .leading, spacing: 2) {
                Text(mission.name)
                    .font(.title3.bold())
                Text("\(mission.year) · \(mission.agency)")
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
        MarsInfoPanel(mission: MarsMissionData.missions[5]) {}
            .padding()
    }
}
