import Foundation
import Combine

@MainActor
final class StartupViewModel: ObservableObject {
    @Published private(set) var route: StartupRoute = .loading
    private let store: EntryStore
    private let client: any EntryFetching
    private let parameters: EntryParameters
    private let hadSavedEntryAtLaunch: Bool
    private var entry: SavedEntry?
    private var hasStarted = false

    init(store: EntryStore, client: any EntryFetching, parameters: EntryParameters) {
        self.store = store
        self.client = client
        self.parameters = parameters
        let saved = store.load()
        entry = saved
        hadSavedEntryAtLaunch = saved != nil
        if let saved { route = .content(saved.address) }
    }

    func start() async {
        guard !hasStarted else { return }
        hasStarted = true
        guard route == .loading else { return }
        do {
            if let received = try await client.fetch(parameters), received.isValid {
                try store.save(received)
                entry = received
                route = .content(received.address)
            } else {
                route = .game
            }
        } catch {
            route = .game
        }
    }

    func consumeReviewRequest() -> Bool {
        guard hadSavedEntryAtLaunch, case .content = route, var saved = entry, !saved.reviewRequested else { return false }
        saved.reviewRequested = true
        do {
            try store.save(saved)
            entry = saved
            return true
        } catch {
            return false
        }
    }

    func openGame() { route = .game }
}
