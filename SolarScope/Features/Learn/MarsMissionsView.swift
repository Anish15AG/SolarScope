import SwiftUI

/// List of Mars exploration missions.
struct MarsMissionsView: View {
    var body: some View {
        List(MarsMissionData.missions) { mission in
            NavigationLink(value: mission) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(mission.name)
                            .font(.subheadline.weight(.semibold))
                        Text(mission.year)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 6) {
                        Text(mission.agency)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text("·")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text(mission.status)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(mission.status == "Active" ? Theme.accent : .gray)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Mars Missions")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Mission detail with summary and key facts.
struct MissionDetailView: View {
    let mission: MarsMission

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.spacing) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(mission.name)
                        .font(.title.bold())
                    HStack(spacing: 8) {
                        chip(mission.year, icon: "calendar")
                        chip(mission.agency, icon: "flag.fill")
                        chip(mission.status, icon: "circle.fill")
                    }
                }

                Text(mission.summary)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader("Key facts")
                    ForEach(mission.highlights, id: \.self) { highlight in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Theme.accent)
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
        .navigationTitle(mission.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func chip(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Theme.surfaceRaised))
    }
}

#Preview {
    NavigationStack {
        MissionDetailView(mission: MarsMissionData.missions[5])
    }
    .preferredColorScheme(.dark)
}
