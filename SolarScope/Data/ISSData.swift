import Foundation

/// A labelled statistic about the International Space Station.
struct ISSStat: Identifiable, Hashable {
    let id: String
    let label: String
    let value: String
}

/// International Space Station reference data used by Learn and the AR scene.
///
/// Values are approximate educational figures. The AR orbit animation is
/// illustrative and does not represent live tracking.
enum ISSData {
    static let assetName = "ISS_stationary"

    static let altitude = "≈400 km"
    static let orbitalSpeed = "≈27,600 km/h"
    static let orbitalPeriod = "≈92 minutes"

    static let summary = """
    The International Space Station is a modular laboratory in low Earth orbit, \
    built and operated by five space agencies. It has been continuously \
    inhabited since November 2000 and completes one lap of Earth roughly every \
    92 minutes.
    """

    static let stats: [ISSStat] = [
        ISSStat(id: "altitude", label: "Altitude", value: altitude),
        ISSStat(id: "speed", label: "Orbital speed", value: orbitalSpeed),
        ISSStat(id: "period", label: "Orbital period", value: orbitalPeriod),
        ISSStat(id: "crew", label: "Crew", value: "Up to 7 astronauts"),
        ISSStat(id: "length", label: "Length", value: "≈109 m"),
        ISSStat(id: "mass", label: "Mass", value: "≈420,000 kg"),
        ISSStat(id: "diameter", label: "Solar array span", value: "≈73 m"),
        ISSStat(id: "first", label: "First module", value: "Zarya · 1998")
    ]

    static let highlights: [String] = [
        "Orbits Earth about 16 times every day",
        "Travels from London to New York in roughly 3 minutes",
        "Has hosted visitors from more than 20 countries",
        "Microgravity research spans medicine, biology and materials science"
    ]

    static func stat(withID id: String) -> ISSStat? {
        stats.first { $0.id == id }
    }
}
