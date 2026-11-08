import SwiftUI

/// Label/value pair used in detail screens and AR information panels.
struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 12) {
        InfoRow(label: "Diameter", value: "12,742 km")
        InfoRow(label: "Moons", value: "1")
    }
    .padding()
    .screenBackground()
}
