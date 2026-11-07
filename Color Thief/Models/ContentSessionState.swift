import Foundation

nonisolated enum CookieSnapshot {
    private struct Identity: Hashable {
        let domain: String
        let path: String
        let name: String

        init(_ cookie: HTTPCookie) {
            domain = cookie.domain.lowercased()
            path = cookie.path
            name = cookie.name
        }
    }

    static func encode(_ cookies: [HTTPCookie], now: Date = Date()) throws -> Data {
        let records: [[String: Any]] = cookies.filter { $0.expiresDate.map { $0 > now } ?? true }.map { cookie in
            var properties = cookie.properties ?? [:]
            if let expiry = cookie.expiresDate {
                properties[.expires] = expiry
                properties.removeValue(forKey: .maximumAge)
            }
            return properties.reduce(into: [:]) { result, pair in
                let value = (pair.value as? URL)?.absoluteString ?? pair.value
                if PropertyListSerialization.propertyList([value], isValidFor: .binary) {
                    result[pair.key.rawValue] = value
                }
            }
        }
        return try PropertyListSerialization.data(fromPropertyList: records, format: .binary, options: 0)
    }

    static func decode(_ data: Data?, now: Date = Date()) -> [HTTPCookie] {
        guard let data, let records = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [[String: Any]] else { return [] }
        return records.compactMap { record in
            let properties = Dictionary(uniqueKeysWithValues: record.map { (HTTPCookiePropertyKey(rawValue: $0.key), $0.value) })
            guard let cookie = HTTPCookie(properties: properties), cookie.expiresDate.map({ $0 > now }) ?? true else { return nil }
            return cookie
        }
    }

    static func missing(saved: [HTTPCookie], current: [HTTPCookie]) -> [HTTPCookie] {
        let existing = Set(current.map(Identity.init))
        return saved.filter { !existing.contains(Identity($0)) }
    }
}

@MainActor
protocol CookieSnapshotStorage {
    func read() throws -> Data?
    func write(_ data: Data) throws
}

@MainActor
protocol ContentCookieJar: AnyObject {
    func allCookies() async -> [HTTPCookie]
    func setCookie(_ cookie: HTTPCookie) async
}

@MainActor
final class CookieSession {
    private let jar: any ContentCookieJar
    private let storage: any CookieSnapshotStorage
    private var preparation: Task<Void, Never>?
    private var snapshotGeneration = 0

    init(jar: any ContentCookieJar, storage: any CookieSnapshotStorage) {
        self.jar = jar
        self.storage = storage
    }

    func prepare() async {
        if let preparation { await preparation.value; return }
        let task = Task { @MainActor in
            let saved = CookieSnapshot.decode(try? storage.read())
            let current = await jar.allCookies()
            for cookie in CookieSnapshot.missing(saved: saved, current: current) {
                await jar.setCookie(cookie)
            }
        }
        preparation = task
        await task.value
    }

    func capture() async {
        await prepare()
        snapshotGeneration += 1
        let generation = snapshotGeneration
        let cookies = await jar.allCookies()
        guard generation == snapshotGeneration, let data = try? CookieSnapshot.encode(cookies) else { return }
        try? storage.write(data)
    }
}

@MainActor
final class ContentLocationStore {
    private let storage: UserDefaults
    private let initialAddress: String
    private let key: String

    init(initialAddress: String, storage: UserDefaults = .standard) {
        self.initialAddress = initialAddress
        self.storage = storage
        key = "contentLocation." + Data(initialAddress.utf8).base64EncodedString()
    }

    func restore() -> String {
        guard let saved = storage.string(forKey: key), let address = accepted(saved) else { return initialAddress }
        return address
    }

    @discardableResult
    func remember(_ value: String) -> String? {
        guard let address = accepted(value) else { return nil }
        storage.set(address, forKey: key)
        return address
    }

    private func accepted(_ value: String) -> String? {
        guard let initial = URLComponents(string: initialAddress), var candidate = URLComponents(string: value),
              candidate.scheme?.lowercased() == "https", let host = candidate.host,
              host.lowercased() == initial.host?.lowercased(),
              (candidate.port ?? 443) == (initial.port ?? 443) else { return nil }
        candidate.query = nil
        candidate.fragment = nil
        candidate.user = nil
        candidate.password = nil
        return candidate.url?.absoluteString
    }
}
