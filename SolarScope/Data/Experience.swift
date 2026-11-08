import SwiftUI

/// The three AR exploration experiences offered by SolarScope.
enum Experience: String, CaseIterable, Identifiable, Hashable {
    case solarSystem
    case marsExploration
    case earthAndISS

    var id: String { rawValue }

    var title: String {
        switch self {
        case .solarSystem: "Solar System Explorer"
        case .marsExploration: "Mars Exploration"
        case .earthAndISS: "Earth & ISS Explorer"
        }
    }

    var tagline: String {
        switch self {
        case .solarSystem: "The Sun and eight planets on a table-top orbit"
        case .marsExploration: "Perseverance, Ingenuity and the search for ancient life"
        case .earthAndISS: "Our planet and the station that circles it"
        }
    }

    var summary: String {
        switch self {
        case .solarSystem:
            return "Place a living model of the Solar System on any flat surface. Watch the planets circle the Sun, tap any world to select it, and control the whole scene with your hands."
        case .marsExploration:
            return "Set down a miniature Martian surface and meet the rovers exploring it. Inspect Perseverance's science instruments, watch Ingenuity take flight and compare the mission with Curiosity."
        case .earthAndISS:
            return "Place Earth in your own space and follow the International Space Station as it traces a continuous orbit. Select the station to read its altitude, speed and orbital period."
        }
    }

    var highlights: [String] {
        switch self {
        case .solarSystem:
            return [
                "Sun at the centre with eight orbiting planets",
                "Generated orbital paths and continuous revolution",
                "Tap a planet to select it and open its data panel",
                "Pause, resume, resize and reposition the scene"
            ]
        case .marsExploration:
            return [
                "A generated Martian ground surface",
                "Select Perseverance for mission and instrument details",
                "Ingenuity take-off and landing animation",
                "Optional Curiosity rover comparison"
            ]
        case .earthAndISS:
            return [
                "Place a rotating Earth model",
                "Animated ISS orbit path around the planet",
                "Select the ISS for altitude, speed and period",
                "Illustrative orbit — not live tracking"
            ]
        }
    }

    var iconName: String {
        switch self {
        case .solarSystem: "sun.max.fill"
        case .marsExploration: "car.fill"
        case .earthAndISS: "globe.americas.fill"
        }
    }

    var tint: Color {
        switch self {
        case .solarSystem: Theme.accent
        case .marsExploration: Color(red: 0.91, green: 0.44, blue: 0.30)
        case .earthAndISS: Theme.orbital
        }
    }
}
