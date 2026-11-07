import Foundation

enum Pigment: String, CaseIterable, Codable, Identifiable {
    case red, blue, yellow, green
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var symbol: String {
        switch self {
        case .red: return "bolt.fill"
        case .blue: return "lock.fill"
        case .yellow: return "sun.max.fill"
        case .green: return "leaf.fill"
        }
    }
    var property: String {
        switch self {
        case .red: return "Activate"
        case .blue: return "Anchor"
        case .yellow: return "Illuminate"
        case .green: return "Grow"
        }
    }
    var state: String {
        switch self {
        case .red: return "Active"
        case .blue: return "Anchored"
        case .yellow: return "Glowing"
        case .green: return "Growing"
        }
    }
    var explanation: String {
        switch self {
        case .red: return "Bring a quiet mechanism to life. Take red away, and it stops working."
        case .blue: return "Hold an object firmly in place. A bridge needs blue to stay steady."
        case .yellow: return "Give an object its own light. A lantern can reveal a path through the dark."
        case .green: return "Help living things reach further. A small vine becomes a way forward."
        }
    }
}

enum ObjectKind: String, Codable {
    case button, door, bridge, lantern, vine, lift, reservoir
    var symbol: String {
        switch self {
        case .button: return "power"
        case .door: return "door.left.hand.open"
        case .bridge: return "line.3.horizontal"
        case .lantern: return "lightbulb.fill"
        case .vine: return "leaf.fill"
        case .lift: return "arrow.up.square.fill"
        case .reservoir: return "drop.fill"
        }
    }
}

struct PuzzleObject: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var kind: ObjectKind
    var pigment: Pigment?
    var x: Double
    var y: Double
}

struct Requirement: Codable, Equatable {
    let objectID: String
    let pigment: Pigment
}

struct PuzzleStage: Codable {
    let title: String
    let detail: String
    let requirements: [Requirement]
}

enum BoardScene: String {
    case courtyard, causeway, night, terraces, foundry, signals, orchard, compass
}

struct PuzzleLevel: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let chapter: String
    let par: Int
    let scene: BoardScene
    let objects: [PuzzleObject]
    let stages: [PuzzleStage]
    var colors: [Pigment] { Pigment.allCases.filter { color in objects.contains { $0.pigment == color } } }
}

struct PuzzleSnapshot: Codable {
    var objects: [PuzzleObject]
    var held: Pigment?
    var stage: Int
    var moves: Int
}

struct PuzzleSession: Codable {
    var levelID: Int
    var timed: Bool
    var objects: [PuzzleObject]
    var held: Pigment?
    var stage: Int = 0
    var moves: Int = 0
    var elapsed: Int = 0
    var history: [PuzzleSnapshot] = []
    var won: Bool = false
    var expired: Bool = false
    var designRevision: Int?
}

struct LevelRecord: Codable {
    var stars: Int
    var moves: Int
    var seconds: Int
    var designRevision: Int?
}

enum LevelLibrary {
    static let revision = 2

    private static func item(_ id: String, _ name: String, _ kind: ObjectKind, _ pigment: Pigment?, _ x: Double, _ y: Double) -> PuzzleObject {
        .init(id: id, name: name, kind: kind, pigment: pigment, x: x, y: y)
    }

    private static func step(_ title: String, _ detail: String, _ needs: [(String, Pigment)]) -> PuzzleStage {
        .init(title: title, detail: detail, requirements: needs.map { .init(objectID: $0.0, pigment: $0.1) })
    }

    static let levels: [PuzzleLevel] = [
        .init(id: 1, title: "The first spark", subtitle: "One gift opens a new beginning.", chapter: "The quiet quarter", par: 2, scene: .courtyard, objects: [
            item("switch", "Switch", .button, .red, 0.22, 0.72),
            item("bridge", "Bridge", .bridge, .blue, 0.50, 0.55),
            item("door", "Exit", .door, nil, 0.78, 0.28)
        ], stages: [
            step("A color for the doorway", "Take red from the switch and give it to the exit. Leave the bridge anchored with blue.", [("door", .red), ("bridge", .blue)])
        ]),
        .init(id: 2, title: "Two distant shores", subtitle: "One anchor. Two crossings.", chapter: "The quiet quarter", par: 6, scene: .causeway, objects: [
            item("stone", "Stone", .reservoir, .blue, 0.18, 0.27),
            item("near", "Near span", .bridge, nil, 0.32, 0.61),
            item("far", "Far span", .bridge, nil, 0.66, 0.35),
            item("switch", "Beacon", .button, .red, 0.18, 0.96),
            item("door", "Exit", .door, nil, 0.84, 0.78)
        ], stages: [
            step("Reach the first shore", "Borrow blue from the stone to anchor the near span. The beacon stays active until you cross.", [("near", .blue), ("switch", .red)]),
            step("Move your anchor", "The first crossing is behind you. Take its blue and steady the far span instead.", [("far", .blue)]),
            step("Leave a light behind", "The beacon has done its job. Give its red to the exit and leave the far span anchored.", [("far", .blue), ("door", .red)])
        ]),
        .init(id: 3, title: "The night watch", subtitle: "Carry a single light through the dark.", chapter: "The quiet quarter", par: 8, scene: .night, objects: [
            item("west", "Dusk", .lantern, .yellow, 0.18, 0.56),
            item("middle", "Midnight", .lantern, nil, 0.50, 0.27),
            item("east", "Dawn", .lantern, nil, 0.82, 0.56),
            item("switch", "Switch", .button, .red, 0.30, 0.92),
            item("door", "Exit", .door, nil, 0.70, 0.92)
        ], stages: [
            step("Find midnight", "Move yellow from Dusk to Midnight. One light must go dark for another to glow.", [("middle", .yellow)]),
            step("Greet the dawn", "Carry the same yellow onward to Dawn to reveal the last part of the route.", [("east", .yellow)]),
            step("Close the circle", "Return yellow to Dusk, then power the exit with red from the switch.", [("west", .yellow), ("door", .red)])
        ]),
        .init(id: 4, title: "A stair of ivy", subtitle: "Grow, hold, and reach a little higher.", chapter: "The quiet quarter", par: 8, scene: .terraces, objects: [
            item("root", "Root", .vine, .green, 0.17, 0.91),
            item("lower", "Low ivy", .vine, nil, 0.49, 0.74),
            item("upper", "High ivy", .vine, nil, 0.81, 0.56),
            item("stone", "Stone", .reservoir, .blue, 0.17, 0.55),
            item("switch", "Switch", .button, .red, 0.49, 0.38),
            item("door", "Exit", .door, nil, 0.81, 0.20)
        ], stages: [
            step("Grow the first step", "Give the root's green to the low ivy. Its new growth becomes your first step.", [("lower", .green)]),
            step("Build a living stair", "Move green to the high ivy. Then give blue from the stone to the low ivy to hold the lower step in place.", [("upper", .green), ("lower", .blue)]),
            step("Open the upper terrace", "Keep both steps in place and move red from the switch to the exit.", [("upper", .green), ("lower", .blue), ("door", .red)])
        ]),
        .init(id: 5, title: "The counterweight", subtitle: "An empty space can change everything.", chapter: "The shifting gardens", par: 10, scene: .foundry, objects: [
            item("lift", "Lift", .lift, .red, 0.25, 0.30),
            item("span", "Span", .bridge, .blue, 0.75, 0.30),
            item("rest", "Rest", .reservoir, nil, 0.25, 0.83),
            item("door", "Exit", .door, nil, 0.75, 0.83)
        ], stages: [
            step("Exchange their roles", "Anchor the lift with blue and activate the span with red. Both are occupied: use Rest or the exit to hold a color while you exchange them.", [("lift", .blue), ("span", .red)]),
            step("Release the counterweight", "The span has moved. Give its red to the exit, then return blue from the lift to the span.", [("door", .red), ("span", .blue)])
        ]),
        .init(id: 6, title: "The signal house", subtitle: "A signal must be seen before it can act.", chapter: "The shifting gardens", par: 14, scene: .signals, objects: [
            item("light", "Lantern", .lantern, .yellow, 0.17, 0.24),
            item("relay", "Signal", .button, nil, 0.50, 0.24),
            item("door", "Exit", .door, nil, 0.83, 0.24),
            item("switch", "Switch", .button, .red, 0.17, 0.81),
            item("stone", "Stone", .reservoir, .blue, 0.50, 0.81),
            item("bridge", "Bridge", .bridge, nil, 0.83, 0.81)
        ], stages: [
            step("Read the silent signal", "Light the signal with the lantern's yellow and anchor the bridge using blue from the stone.", [("relay", .yellow), ("bridge", .blue)]),
            step("Send your reply", "The signal now needs red, while the switch must glow yellow. Use an empty object to exchange the two colors.", [("relay", .red), ("switch", .yellow), ("bridge", .blue)]),
            step("Return to the lantern", "Give red from the signal to the exit. Return yellow from the switch to the lantern and keep the bridge anchored.", [("door", .red), ("light", .yellow), ("bridge", .blue)])
        ]),
        .init(id: 7, title: "The wandering orchard", subtitle: "A living route changes as you cross it.", chapter: "The shifting gardens", par: 18, scene: .orchard, objects: [
            item("root", "Root", .vine, .green, 0.17, 0.24),
            item("light", "Lantern", .lantern, .yellow, 0.50, 0.24),
            item("stone", "Stone", .reservoir, .blue, 0.83, 0.24),
            item("first", "Old ivy", .vine, nil, 0.30, 0.59),
            item("second", "New ivy", .vine, nil, 0.70, 0.59),
            item("switch", "Switch", .button, .red, 0.25, 0.94),
            item("door", "Exit", .door, nil, 0.75, 0.94)
        ], stages: [
            step("Find the hidden branch", "Grow the old ivy with green and illuminate the new ivy with yellow from the lantern.", [("first", .green), ("second", .yellow)]),
            step("Cross into new growth", "Anchor the old ivy with blue and grow the new ivy with green. Find temporary homes for the colors you displace.", [("first", .blue), ("second", .green)]),
            step("Let the orchard rest", "Grow the old ivy again, anchor the new ivy, restore yellow to the lantern, and give red to the exit.", [("first", .green), ("second", .blue), ("light", .yellow), ("door", .red)])
        ]),
        .init(id: 8, title: "The color compass", subtitle: "Four colors. Two directions. One way home.", chapter: "The shifting gardens", par: 20, scene: .compass, objects: [
            item("north", "North", .bridge, .blue, 0.50, 0.20),
            item("east", "East", .lantern, .yellow, 0.83, 0.53),
            item("south", "South", .vine, .green, 0.50, 0.86),
            item("west", "West", .lift, nil, 0.17, 0.53),
            item("core", "Core", .button, .red, 0.17, 0.92),
            item("door", "Exit", .door, nil, 0.83, 0.92)
        ], stages: [
            step("Turn the compass", "Grow West with green, anchor South with blue, light North with yellow, and activate East with red. Start with the empty western platform.", [("west", .green), ("south", .blue), ("north", .yellow), ("east", .red)]),
            step("Reverse the current", "Now activate West, anchor North, light East, and grow South. Every destination is occupied: use the quiet core or exit as a temporary home.", [("west", .red), ("north", .blue), ("east", .yellow), ("south", .green)]),
            step("The final gift", "Move red from West to the exit. Leave the other three compass points restored.", [("door", .red), ("north", .blue), ("east", .yellow), ("south", .green)])
        ])
    ]
}
