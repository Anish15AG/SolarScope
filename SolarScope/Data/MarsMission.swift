import Foundation

/// Mars exploration missions shown in the Learn catalogue.
struct MarsMission: Identifiable, Hashable {
    let id: String
    let name: String
    let year: String
    let agency: String
    let status: String
    let summary: String
    let highlights: [String]
    /// USDZ resource name without the file extension, when a model exists.
    let assetName: String?
}

enum MarsMissionData {
    static let missions: [MarsMission] = [
        MarsMission(
            id: "voyager",
            name: "Viking",
            year: "1976",
            agency: "NASA",
            status: "Completed",
            summary: "The first successful landing on Mars that operated on the surface, Viking 1 and 2 returned the first clear photographs of the Martian ground.",
            highlights: [
                "First fully successful Mars surface landings",
                "Ran the first experiments searching for life in Martian soil",
                "Returned over 55,000 images from the surface"
            ],
            assetName: nil
        ),
        MarsMission(
            id: "pathfinder",
            name: "Pathfinder & Sojourner",
            year: "1997",
            agency: "NASA",
            status: "Completed",
            summary: "Pathfinder demonstrated a low-cost landing system and deployed Sojourner, the first rover to drive on another planet.",
            highlights: [
                "First rover to operate on another world",
                "Tested airbag-assisted landing",
                "Analysed more than 15 rocks and soils"
            ],
            assetName: nil
        ),
        MarsMission(
            id: "spirit-opportunity",
            name: "Spirit & Opportunity",
            year: "2004",
            agency: "NASA",
            status: "Completed",
            summary: "Twin rovers designed for 90 days of operation. Opportunity lasted nearly 15 years and found decisive evidence that liquid water once flowed on Mars.",
            highlights: [
                "Opportunity travelled over 45 km across the surface",
                "Found mineral veins formed in standing water",
                "Both rovers exceeded their design lifetimes by years"
            ],
            assetName: nil
        ),
        MarsMission(
            id: "curiosity",
            name: "Curiosity",
            year: "2012",
            agency: "NASA",
            status: "Active",
            summary: "The car-sized Curiosity rover explores Gale Crater to learn whether Mars ever supported microbial life, climbing the slopes of Mount Sharp.",
            highlights: [
                "Landed with the famous sky-crane manoeuvre",
                "Carries 10 scientific instruments",
                "Confirmed ancient lakes once filled Gale Crater"
            ],
            assetName: "24584_Curiosity_static"
        ),
        MarsMission(
            id: "insight",
            name: "InSight",
            year: "2018",
            agency: "NASA",
            status: "Completed",
            summary: "InSight was the first mission dedicated to studying the interior of Mars, listening for marsquakes to map the planet's deep structure.",
            highlights: [
                "First seismometer placed on Mars",
                "Detected more than 1,300 marsquakes",
                "Revealed the size of Mars's core"
            ],
            assetName: nil
        ),
        MarsMission(
            id: "perseverance",
            name: "Perseverance",
            year: "2021",
            agency: "NASA",
            status: "Active",
            summary: "Perseverance explores Jezero Crater, an ancient river delta, caching rock and soil samples for a future return to Earth and testing technologies for human exploration.",
            highlights: [
                "Collects and seals samples for Mars Sample Return",
                "Studies sedimentary rocks of an ancient delta",
                "Carries the MOXIE experiment that makes oxygen from CO₂"
            ],
            assetName: "25042_Perseverance"
        ),
        MarsMission(
            id: "ingenuity",
            name: "Ingenuity",
            year: "2021 – 2024",
            agency: "NASA",
            status: "Completed",
            summary: "A small helicopter that proved powered, controlled flight is possible in Mars's thin atmosphere. It far outlived its planned five-test flights.",
            highlights: [
                "First powered flight on another planet",
                "72 flights covering more than 17 km",
                "Acted as a scout for the Perseverance rover"
            ],
            assetName: "25043_Ingenuity_v3"
        )
    ]
}
