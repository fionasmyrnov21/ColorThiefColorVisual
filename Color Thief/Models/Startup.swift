import Foundation

nonisolated struct EntryParameters: Equatable, Sendable {
    let systemVersion: String
    let language: String
    let deviceModel: String
    let country: String

    var payload: String {
        "p=GsdGsdGdsGdsGs&os=\(systemVersion)&lng=\(language)&devicemodel=\(deviceModel)&country=\(country)"
    }

    var encodedPayload: String {
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        return Data(payload.utf8).base64EncodedString().addingPercentEncoding(withAllowedCharacters: allowed)!
    }

    static func primaryLanguage(from languages: [String]) -> String {
        guard let first = languages.first?.components(separatedBy: "-").first, !first.isEmpty else { return "en" }
        return first.lowercased()
    }
}

nonisolated struct SavedEntry: Codable, Equatable, Sendable {
    let token: String
    let address: String
    var reviewRequested = false

    var isValid: Bool {
        guard !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let destination = URL(string: address),
              destination.scheme?.lowercased() == "https",
              let host = destination.host, !host.isEmpty else { return false }
        return true
    }

    static func parse(_ data: Data) -> SavedEntry? {
        guard let text = String(data: data, encoding: .utf8), let separator = text.firstIndex(of: "#") else { return nil }
        let token = String(text[..<separator]).trimmingCharacters(in: .whitespacesAndNewlines)
        let address = String(text[text.index(after: separator)...]).trimmingCharacters(in: .whitespacesAndNewlines)
        let entry = SavedEntry(token: token, address: address)
        return entry.isValid ? entry : nil
    }
}

nonisolated enum StartupRoute: Equatable, Sendable {
    case loading
    case game
    case content(String)
}

@MainActor
final class EntryStore {
    private let storage: UserDefaults
    private let key: String

    init(storage: UserDefaults = .standard, key: String = "savedEntry") {
        self.storage = storage
        self.key = key
    }

    func load() -> SavedEntry? {
        guard let data = storage.data(forKey: key),
              let entry = try? JSONDecoder().decode(SavedEntry.self, from: data), entry.isValid else { return nil }
        return entry
    }

    func save(_ entry: SavedEntry) throws {
        storage.set(try JSONEncoder().encode(entry), forKey: key)
    }
}
