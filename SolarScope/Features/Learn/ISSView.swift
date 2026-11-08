import SwiftUI

/// International Space Station reference screen.
struct ISSView: View {
    private let columns = [GridItem(.adaptive(minimum: 160), spacing: Layout.spacing)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.spacing) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Theme.accent.opacity(0.18))
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                    }
                    .frame(width: 56, height: 56)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("International Space Station")
                            .font(.title3.bold())
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Low Earth orbit · 1998 – present")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(ISSData.summary)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: Layout.spacing) {
                    SectionHeader("By the numbers")
                    LazyVGrid(columns: columns, spacing: Layout.spacing) {
                        ForEach(ISSData.stats) { stat in
                            InfoRow(label: stat.label, value: stat.value)
                        }
                    }
                }
                .padding(Layout.spacing)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardBackground()

                FactCallout(text: ISSData.highlights[0])

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader("Good to know")
                    ForEach(ISSData.highlights.dropFirst(), id: \.self) { highlight in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Theme.orbital)
                            Text(highlight)
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
            .padding(Layout.spacing)
            .constrainedWidth()
        }
        .screenBackground()
        .navigationTitle("Space Station")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ISSView()
    }
    .preferredColorScheme(.dark)
}
