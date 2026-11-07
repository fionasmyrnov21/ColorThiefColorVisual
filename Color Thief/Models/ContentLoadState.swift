import Foundation

nonisolated struct ContentLoadState: Equatable, Sendable {
    private(set) var hasCompletedInitialLoad = false
    private(set) var hasFailure = false

    var showsInitialCover: Bool { !hasCompletedInitialLoad && !hasFailure }
    var showsInitialError: Bool { !hasCompletedInitialLoad && hasFailure }
    var showsNavigationError: Bool { hasCompletedInitialLoad && hasFailure }

    mutating func begin() { hasFailure = false }

    mutating func complete() {
        hasCompletedInitialLoad = true
        hasFailure = false
    }

    mutating func fail(cancelled: Bool = false) {
        if !cancelled { hasFailure = true }
    }

    mutating func dismissFailure() { hasFailure = false }
}

nonisolated struct ContentRequestTracker {
    private var loadedAttempt: Int?

    mutating func shouldLoad(attempt: Int) -> Bool {
        guard loadedAttempt != attempt else { return false }
        loadedAttempt = attempt
        return true
    }
}
