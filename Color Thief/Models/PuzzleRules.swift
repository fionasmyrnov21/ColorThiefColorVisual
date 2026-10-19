import Foundation

struct TransferResult {
    let changed: Bool
    let message: String
}

enum PuzzleRules {
    static func matches(_ requirements: [Requirement], objects: [PuzzleObject]) -> Bool {
        requirements.allSatisfy { requirement in objects.contains { $0.id == requirement.objectID && $0.pigment == requirement.pigment } }
    }

    static func transfer(_ id: String, in value: inout PuzzleSession, level: PuzzleLevel) -> TransferResult {
        guard !value.won, !value.expired, let index = value.objects.firstIndex(where: { $0.id == id }) else {
            return TransferResult(changed: false, message: "This place is resting.")
        }
        let object = value.objects[index]
        if let held = value.held, object.pigment != nil {
            return TransferResult(changed: false, message: "Your hand holds \(held.title.lowercased()). Choose a colorless object first.")
        }
        if value.held == nil && object.pigment == nil {
            return TransferResult(changed: false, message: "\(object.name) has no color. Collect a color from another object first.")
        }
        value.history.append(.init(objects: value.objects, held: value.held, stage: value.stage, moves: value.moves))
        var message: String
        if let held = value.held {
            value.objects[index].pigment = held
            value.held = nil
            message = "\(object.name) is now \(held.state.lowercased())."
        } else {
            value.held = object.pigment
            value.objects[index].pigment = nil
            message = "\(object.pigment?.title ?? "Color") collected. \(object.name) is now dormant."
        }
        value.moves += 1
        if value.stage < level.stages.count, matches(level.stages[value.stage].requirements, objects: value.objects) {
            value.stage += 1
            message = value.stage >= level.stages.count ? "The path is ready. Step through the exit." : "Path discovered. \(level.stages[value.stage].title)."
        }
        return TransferResult(changed: true, message: message)
    }
}
