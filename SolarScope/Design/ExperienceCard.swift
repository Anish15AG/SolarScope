import SwiftUI

/// Card used on Home and Explore to open an AR experience.
struct ExperienceCard: View {
    enum Style {
        /// Grid tile: icon, title and tagline.
        case compact
        /// Full-width row: adds a description and an explicit launch affordance.
        case detailed
    }

    let experience: Experience
    var style: Style = .compact

    var body: some View {
        NavigationLink(value: experience) {
            switch style {
            case .compact: compactContent
            case .detailed: detailedContent
            }
        }
        .buttonStyle(.plain)
    }

    private var compactContent: some View {
        VStack(alignment: .leading, spacing: Layout.compactSpacing) {
            badge
            Spacer(minLength: 0)
            Text(experience.title)
                .font(.headline)
                .multilineTextAlignment(.leading)
            Text(experience.tagline)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            HStack(spacing: 6) {
                Label("Launch AR", systemImage: "arkit")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(experience.tint)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.top, 4)
        }
        .padding(Layout.spacing)
        .frame(maxWidth: .infinity, minHeight: 168, alignment: .topLeading)
        .cardBackground()
    }

    private var detailedContent: some View {
        HStack(alignment: .top, spacing: 14) {
            badge
            VStack(alignment: .leading, spacing: 6) {
                Text(experience.title)
                    .font(.headline)
                Text(experience.tagline)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(experience.summary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                Label("Launch AR experience", systemImage: "arkit")
                    .font(.caption.bold())
                    .foregroundStyle(experience.tint)
                    .padding(.top, 4)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
        .padding(Layout.spacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground()
    }

    private var badge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [experience.tint, experience.tint.opacity(0.55)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(systemName: experience.iconName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white.opacity(0.95))
        }
        .frame(width: 48, height: 48)
    }
}
