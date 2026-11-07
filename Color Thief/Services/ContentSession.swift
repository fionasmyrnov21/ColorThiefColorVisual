import Foundation
import Security
import WebKit
import UIKit

@MainActor
private struct CookieVault: CookieSnapshotStorage {
    private var query: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: (Bundle.main.bundleIdentifier ?? "ColorThief") + ".contentCookies",
            kSecAttrAccount as String: "primary"
        ]
    }

    func read() throws -> Data? {
        var request = query
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(request as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw VaultFailure(status: status) }
        return result as? Data
    }

    func write(_ data: Data) throws {
        let values: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        var status = SecItemUpdate(query as CFDictionary, values as CFDictionary)
        if status == errSecItemNotFound {
            status = SecItemAdd(query.merging(values) { _, replacement in replacement } as CFDictionary, nil)
        }
        guard status == errSecSuccess else { throw VaultFailure(status: status) }
    }
}

private struct VaultFailure: Error { let status: OSStatus }

@MainActor
private final class PlatformCookieJar: ContentCookieJar {
    let store: WKHTTPCookieStore

    init(store: WKHTTPCookieStore) { self.store = store }

    func allCookies() async -> [HTTPCookie] {
        await withCheckedContinuation { continuation in
            store.getAllCookies { continuation.resume(returning: $0) }
        }
    }

    func setCookie(_ cookie: HTTPCookie) async {
        await withCheckedContinuation { continuation in
            store.setCookie(cookie) { continuation.resume() }
        }
    }
}

@MainActor
final class ContentSession: NSObject, WKHTTPCookieStoreObserver {
    static let shared = ContentSession()
    let dataStore: WKWebsiteDataStore
    private let cookies: CookieSession
    private var observing = false
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    private override init() {
        let store = WKWebsiteDataStore.default()
        dataStore = store
        cookies = CookieSession(jar: PlatformCookieJar(store: store.httpCookieStore), storage: CookieVault())
        super.init()
    }

    func prepare() async {
        await cookies.prepare()
        if !observing {
            dataStore.httpCookieStore.add(self)
            observing = true
        }
    }

    func capture() async {
        await prepare()
        await cookies.capture()
    }

    func cookiesDidChange(in cookieStore: WKHTTPCookieStore) {
        Task { await cookies.capture() }
    }

    func saveForBackground() {
        guard backgroundTask == .invalid else { return }
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "Save site preferences") { [weak self] in
            Task { @MainActor in self?.finishBackgroundSave() }
        }
        Task {
            await capture()
            finishBackgroundSave()
        }
    }

    private func finishBackgroundSave() {
        guard backgroundTask != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }
}
