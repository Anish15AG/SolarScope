import SwiftUI

/// Bottom panel showing the data of the International Space Station.
///
/// Rendered over the AR feed once the station has been tapped; the close
/// button (or tapping the station again) dismisses it.
struct ISSInfoPanel: View {
    let onClose: () -> Void

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(ISSData.stats) { stat in
                    InfoRow(label: stat.label, value: stat.value)
                }
            }

            Text(ISSData.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(ISSData.highlights, id: \.self) { highlight in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Experience.earthAndISS.tint)
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
            Image(systemName: "globe.americas")
                .font(.title3)
                .foregroundStyle(Experience.earthAndISS.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text("International Space Station")
                    .font(.title3.bold())
                Text("Low Earth orbit · inhabited since 2000")
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
        ISSInfoPanel(onClose: {})
            .padding()
    }
}
