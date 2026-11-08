import SwiftUI

/// Sun and planet information used by the Learn catalogue and the AR scene.
///
/// Scene values (`visualRadius`, `orbitRadius`, `rotationPeriod`,
/// `revolutionPeriod`) describe an educational model: distances and sizes are
/// compressed so the whole system stays readable on a table top.
struct Planet: Identifiable, Hashable {
    enum Kind: Hashable {
        case sun
        case planet
    }

    let id: String
    let kind: Kind
    let name: String
    let classification: String
    let diameterKm: Double
    /// Average distance from the Sun, formatted for display.
    let distanceFromSun: String
    /// Time to complete one orbit around the Sun.
    let orbitalPeriod: String
    /// Length of one rotation on the body's axis.
    let dayLength: String
    /// Known natural satellites; `nil` for the Sun.
    let moons: Int?
    let composition: String
    let fact: String
    /// USDZ resource name without the file extension.
    let assetName: String

    // MARK: Scene configuration (educational scale)

    /// Model radius in metres.
    let visualRadius: Double
    /// Distance from the Sun in metres (0 for the Sun itself).
    let orbitRadius: Double
    /// Seconds per axial rotation.
    let rotationPeriod: Double
    /// Seconds per orbit. Values are hand-tuned, not proportional to reality.
    let revolutionPeriod: Double

    var diameterText: String {
        let formatted = Self.diameterFormatter.string(from: NSNumber(value: diameterKm))
            ?? String(Int(diameterKm))
        return "\(formatted) km"
    }

    private static let diameterFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}

enum PlanetData {
    static let sun = Planet(
        id: "sun",
        kind: .sun,
        name: "Sun",
        classification: "Star · G-type",
        diameterKm: 1_391_000,
        distanceFromSun: "Centre of the Solar System",
        orbitalPeriod: "—",
        dayLength: "About 25 days at the equator",
        moons: nil,
        composition: "Hydrogen and helium plasma",
        fact: "The Sun holds about 99.86% of the mass of the entire Solar System.",
        assetName: "Sun_1_1391000",
        visualRadius: 0.22,
        orbitRadius: 0,
        rotationPeriod: 60,
        revolutionPeriod: 1
    )

    static let planets: [Planet] = [
        Planet(
            id: "mercury",
            kind: .planet,
            name: "Mercury",
            classification: "Terrestrial planet",
            diameterKm: 4_879,
            distanceFromSun: "57.9 million km",
            orbitalPeriod: "88 days",
            dayLength: "58.6 days",
            moons: 0,
            composition: "Large iron core under a rocky silicate crust",
            fact: "A single day on Mercury lasts longer than its entire year.",
            assetName: "Mercury_1_4878",
            visualRadius: 0.030,
            orbitRadius: 0.38,
            rotationPeriod: 90,
            revolutionPeriod: 10
        ),
        Planet(
            id: "venus",
            kind: .planet,
            name: "Venus",
            classification: "Terrestrial planet",
            diameterKm: 12_104,
            distanceFromSun: "108.2 million km",
            orbitalPeriod: "225 days",
            dayLength: "243 days (retrograde)",
            moons: 0,
            composition: "Rocky body under a thick carbon dioxide atmosphere",
            fact: "Venus spins backwards, so the Sun rises in the west.",
            assetName: "Venus_1_12103-1",
            visualRadius: 0.050,
            orbitRadius: 0.50,
            rotationPeriod: 120,
            revolutionPeriod: 15
        ),
        Planet(
            id: "earth",
            kind: .planet,
            name: "Earth",
            classification: "Terrestrial planet",
            diameterKm: 12_742,
            distanceFromSun: "149.6 million km",
            orbitalPeriod: "365.25 days",
            dayLength: "24 hours",
            moons: 1,
            composition: "Iron core, silicate rock and liquid water oceans",
            fact: "Earth is the only planet not named after a Greek or Roman god.",
            assetName: "EarthClouds_1_12756",
            visualRadius: 0.052,
            orbitRadius: 0.63,
            rotationPeriod: 20,
            revolutionPeriod: 22
        ),
        Planet(
            id: "mars",
            kind: .planet,
            name: "Mars",
            classification: "Terrestrial planet",
            diameterKm: 6_779,
            distanceFromSun: "227.9 million km",
            orbitalPeriod: "687 days",
            dayLength: "24.6 hours",
            moons: 2,
            composition: "Iron-rich rock covered in rusted dust",
            fact: "Olympus Mons on Mars is the tallest volcano in the Solar System.",
            assetName: "24881_Mars_1_6792",
            visualRadius: 0.035,
            orbitRadius: 0.76,
            rotationPeriod: 21,
            revolutionPeriod: 32
        ),
        Planet(
            id: "jupiter",
            kind: .planet,
            name: "Jupiter",
            classification: "Gas giant",
            diameterKm: 139_820,
            distanceFromSun: "778.5 million km",
            orbitalPeriod: "11.9 years",
            dayLength: "9.9 hours",
            moons: 95,
            composition: "Hydrogen and helium around a dense core",
            fact: "The Great Red Spot is a storm wider than Earth that has raged for centuries.",
            assetName: "Jupiter_1_142984",
            visualRadius: 0.160,
            orbitRadius: 1.00,
            rotationPeriod: 12,
            revolutionPeriod: 55
        ),
        Planet(
            id: "saturn",
            kind: .planet,
            name: "Saturn",
            classification: "Gas giant",
            diameterKm: 116_460,
            distanceFromSun: "1.43 billion km",
            orbitalPeriod: "29.5 years",
            dayLength: "10.7 hours",
            moons: 146,
            composition: "Hydrogen and helium with an extensive ring system",
            fact: "Saturn is less dense than water and would float in a large enough ocean.",
            assetName: "Saturn_1_120536",
            visualRadius: 0.140,
            orbitRadius: 1.22,
            rotationPeriod: 14,
            revolutionPeriod: 75
        ),
        Planet(
            id: "uranus",
            kind: .planet,
            name: "Uranus",
            classification: "Ice giant",
            diameterKm: 50_724,
            distanceFromSun: "2.87 billion km",
            orbitalPeriod: "84 years",
            dayLength: "17.2 hours (retrograde)",
            moons: 28,
            composition: "Icy mantle of water, ammonia and methane",
            fact: "Uranus rotates on its side, probably knocked over by a giant impact.",
            assetName: "Uranus_1_51118",
            visualRadius: 0.100,
            orbitRadius: 1.45,
            rotationPeriod: 18,
            revolutionPeriod: 100
        ),
        Planet(
            id: "neptune",
            kind: .planet,
            name: "Neptune",
            classification: "Ice giant",
            diameterKm: 49_244,
            distanceFromSun: "4.5 billion km",
            orbitalPeriod: "165 years",
            dayLength: "16.1 hours",
            moons: 16,
            composition: "Ice and rock beneath a hydrogen-helium atmosphere",
            fact: "Neptune has the fastest winds in the Solar System, up to 2,100 km/h.",
            assetName: "Neptune_1_49528",
            visualRadius: 0.100,
            orbitRadius: 1.65,
            rotationPeriod: 17,
            revolutionPeriod: 130
        )
    ]

    static var all: [Planet] { [sun] + planets }

    static func planet(withID id: String) -> Planet? {
        all.first { $0.id == id }
    }
}

extension Planet {
    /// Display colour used for catalogue tiles and orbit rings.
    var tint: Color {
        switch id {
        case "sun": Color(red: 1.00, green: 0.76, blue: 0.29)
        case "mercury": Color(red: 0.62, green: 0.60, blue: 0.58)
        case "venus": Color(red: 0.86, green: 0.72, blue: 0.45)
        case "earth": Color(red: 0.30, green: 0.62, blue: 0.90)
        case "mars": Color(red: 0.80, green: 0.42, blue: 0.28)
        case "jupiter": Color(red: 0.76, green: 0.62, blue: 0.47)
        case "saturn": Color(red: 0.85, green: 0.78, blue: 0.58)
        case "uranus": Color(red: 0.55, green: 0.83, blue: 0.85)
        case "neptune": Color(red: 0.32, green: 0.48, blue: 0.86)
        default: Color.white
        }
    }
}
