import SwiftUI

/// Sections of the educational catalogue.
enum LearnSection: String, CaseIterable, Identifiable {
    case planets
    case marsMissions
    case iss

    var id: String { rawValue }

    var title: String {
        switch self {
        case .planets: "The Sun & Planets"
        case .marsMissions: "Mars Missions"
        case .iss: "International Space Station"
        }
    }

    var iconName: String {
        switch self {
        case .planets: "globe.americas.fill"
        case .marsMissions: "car.fill"
        case .iss: "antenna.radiowaves.left.and.right"
        }
    }
}

/// Educational catalogue: planetary data, Mars missions and the ISS.
struct LearnView: View {
    @State private var selection: LearnSection? = .planets

    var body: some View {
        NavigationSplitView {
            List(LearnSection.allCases, id: \.self, selection: $selection) { section in
                Label(section.title, systemImage: section.iconName)
                    .tag(section)
            }
            .navigationTitle("Learn")
        } detail: {
            NavigationStack {
                detail(for: selection)
                    .learnDestinations()
            }
        }
    }

    @ViewBuilder
    private func detail(for section: LearnSection?) -> some View {
        switch section {
        case .planets:
            PlanetsGalleryView()
        case .marsMissions:
            MarsMissionsView()
        case .iss:
            ISSView()
        case nil:
            ContentUnavailableView(
                "Choose a topic",
                systemImage: "book.fill",
                description: Text("Select a section to start reading.")
            )
        }
    }
}

extension View {
    /// Registers the shared push destinations used by Home, Explore and Learn.
    func learnDestinations() -> some View {
        navigationDestination(for: Experience.self) { experience in
            ExperienceDetailView(experience: experience)
        }
        .navigationDestination(for: Planet.self) { planet in
            PlanetDetailView(planet: planet)
        }
        .navigationDestination(for: MarsMission.self) { mission in
            MissionDetailView(mission: mission)
        }
    }
}

#Preview {
    LearnView()
}
