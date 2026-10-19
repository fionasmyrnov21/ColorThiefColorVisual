import Foundation
import Combine
import UIKit

@MainActor
final class GameViewModel: ObservableObject {
    @Published private(set) var session: PuzzleSession?
    @Published var message = "Tap a colored object to collect its color."
    @Published var showHint = false
    private let storage: UserDefaults
    var hapticsEnabled = true
    var onComplete: ((PuzzleSession, Int) -> Void)?

    init(storage: UserDefaults = .standard) {
        self.storage = storage
        if let data = storage.data(forKey: "activePuzzle"), let saved = try? JSONDecoder().decode(PuzzleSession.self, from: data), let level = LevelLibrary.levels.first(where: { $0.id == saved.levelID }), !saved.won {
            if saved.designRevision == LevelLibrary.revision {
                session = saved
            } else {
                session = PuzzleSession(levelID: level.id, timed: saved.timed, objects: level.objects, designRevision: LevelLibrary.revision)
                message = "This place has a new design. Explore its new route."
                persist()
            }
        }
    }

    var level: PuzzleLevel { LevelLibrary.levels.first { $0.id == session?.levelID } ?? LevelLibrary.levels[0] }
    var ready: Bool { (session?.stage ?? 0) >= level.stages.count }
    var currentStage: PuzzleStage { level.stages[min(session?.stage ?? 0, level.stages.count - 1)] }
    var remaining: Int { max(0, 150 - (session?.elapsed ?? 0)) }
    var stars: Int {
        let moves = session?.moves ?? 0
        return moves <= level.par ? 3 : moves <= level.par + 4 ? 2 : 1
    }

    func start(_ level: PuzzleLevel, timed: Bool = false) {
        session = PuzzleSession(levelID: level.id, timed: timed, objects: level.objects, designRevision: LevelLibrary.revision)
        message = "Tap a colored object to collect its color."
        showHint = false
        persist()
    }

    func tap(_ id: String) {
        guard var value = session else { return }
        let result = PuzzleRules.transfer(id, in: &value, level: level)
        message = result.message
        guard result.changed else { return }
        session = value
        if hapticsEnabled { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
        persist()
    }

    func undo() {
        guard var value = session, !value.won, !value.expired, let snapshot = value.history.popLast() else { return }
        value.objects = snapshot.objects
        value.held = snapshot.held
        value.stage = snapshot.stage
        value.moves = snapshot.moves
        session = value
        message = "One step back. A new possibility."
        persist()
    }

    func restart() { start(level, timed: session?.timed ?? false) }

    func tick() {
        guard var value = session, !value.won, !value.expired else { return }
        value.elapsed += 1
        if value.timed && value.elapsed >= 150 { value.expired = true }
        session = value
        if value.elapsed % 5 == 0 || value.expired { persist() }
    }

    func finish() {
        guard var value = session, ready, !value.won, !value.expired else { return }
        let requirements = level.stages.last?.requirements ?? []
        guard PuzzleRules.matches(requirements, objects: value.objects) else {
            message = "The route changed. Restore the colors shown in your objective."
            value.stage = max(0, level.stages.count - 1)
            session = value
            return
        }
        value.won = true
        session = value
        onComplete?(value, stars)
        storage.removeObject(forKey: "activePuzzle")
        if hapticsEnabled { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    }

    func persist() {
        guard let session, !session.won, let data = try? JSONEncoder().encode(session) else { return }
        storage.set(data, forKey: "activePuzzle")
    }

    func discard() {
        session = nil
        storage.removeObject(forKey: "activePuzzle")
    }
}

@MainActor
final class AppViewModel: ObservableObject {
    @Published var records: [Int: LevelRecord] = [:]
    @Published var challengeRecord: LevelRecord?
    @Published var selectedTab = 0
    @Published var isPlaying = false
    @Published var showSettings = false
    @Published var showProfile = false
    @Published var haptics: Bool { didSet { storage.set(haptics, forKey: "haptics"); game.hapticsEnabled = haptics } }
    @Published var reduceEffects: Bool { didSet { storage.set(reduceEffects, forKey: "reduceEffects") } }
    let game: GameViewModel
    let profile = ProfileViewModel()
    private let storage: UserDefaults

    init(storage: UserDefaults = .standard) {
        self.storage = storage
        haptics = storage.object(forKey: "haptics") as? Bool ?? true
        reduceEffects = storage.bool(forKey: "reduceEffects")
        game = GameViewModel(storage: storage)
        game.hapticsEnabled = haptics
        if let data = storage.data(forKey: "journeyRecords"), let saved = try? JSONDecoder().decode([Int: LevelRecord].self, from: data) { records = saved }
        if let data = storage.data(forKey: "challengeRecord") { challengeRecord = try? JSONDecoder().decode(LevelRecord.self, from: data) }
        game.onComplete = { [weak self] session, stars in self?.record(session, stars: stars) }
    }

    var totalStars: Int { records.values.reduce(0) { $0 + $1.stars } }
    var nextLevel: PuzzleLevel { LevelLibrary.levels.first { records[$0.id] == nil } ?? LevelLibrary.levels[7] }
    var unlocked: Int { min(8, (records.keys.max() ?? 0) + 1) }

    func play(_ level: PuzzleLevel, timed: Bool = false) {
        game.start(level, timed: timed)
        isPlaying = true
    }

    func resume() { isPlaying = true }

    func reset() {
        records = [:]
        challengeRecord = nil
        storage.removeObject(forKey: "journeyRecords")
        storage.removeObject(forKey: "challengeRecord")
        game.discard()
    }

    private func record(_ session: PuzzleSession, stars: Int) {
        let result = LevelRecord(stars: stars, moves: session.moves, seconds: session.elapsed, designRevision: LevelLibrary.revision)
        if session.timed {
            if challengeRecord?.designRevision != LevelLibrary.revision || session.moves < (challengeRecord?.moves ?? Int.max) { challengeRecord = result }
            if let data = try? JSONEncoder().encode(challengeRecord) { storage.set(data, forKey: "challengeRecord") }
        } else {
            if let previous = records[session.levelID], previous.designRevision == LevelLibrary.revision {
                records[session.levelID] = .init(stars: max(previous.stars, stars), moves: min(previous.moves, session.moves), seconds: min(previous.seconds, session.elapsed), designRevision: LevelLibrary.revision)
            } else { records[session.levelID] = result }
            if let data = try? JSONEncoder().encode(records) { storage.set(data, forKey: "journeyRecords") }
        }
    }
}
