import Foundation
import Combine

@MainActor
final class ContentViewModel: ObservableObject {
    let entryAddress: String
    private(set) var address: String
    private let location: ContentLocationStore
    @Published private(set) var loading = ContentLoadState()
    @Published private(set) var attempt = 0

    init(address: String, location: ContentLocationStore? = nil) {
        entryAddress = address
        let store = location ?? ContentLocationStore(initialAddress: address)
        self.location = store
        self.address = store.restore()
    }

    func begin() { loading.begin() }
    func complete(address: String? = nil) {
        if let address, let saved = location.remember(address) { self.address = saved }
        loading.complete()
    }
    func fail(cancelled: Bool = false) { loading.fail(cancelled: cancelled) }
    func dismissFailure() { loading.dismissFailure() }

    func retry() {
        loading.begin()
        attempt += 1
    }
}
