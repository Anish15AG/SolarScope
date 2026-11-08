import SwiftUI

/// Highlighted "did you know" fact block.
struct FactCallout: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.max.fill")
                .font(.body)
                .foregroundStyle(Theme.accent)
            VStack(alignment: .leading, spacing: 4) {
                Text("Did you know?")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(text)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Layout.spacing)
        .cardBackground(Theme.surfaceRaised)
    }
}

#Preview {
    FactCallout(text: "A day on Mercury lasts longer than its year.")
        .padding()
        .screenBackground()
}
