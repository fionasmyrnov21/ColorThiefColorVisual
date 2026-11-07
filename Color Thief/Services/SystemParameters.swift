import UIKit

@MainActor
enum SystemParameters {
    static var current: EntryParameters {
        EntryParameters(
            systemVersion: UIDevice.current.systemVersion,
            language: EntryParameters.primaryLanguage(from: Locale.preferredLanguages),
            deviceModel: model,
            country: Locale.current.region?.identifier.uppercased() ?? ""
        )
    }

    private static var model: String {
        #if targetEnvironment(simulator)
        return "arm64"
        #else
        var information = utsname()
        uname(&information)
        let capacity = MemoryLayout.size(ofValue: information.machine)
        return withUnsafePointer(to: &information.machine) { pointer in
            pointer.withMemoryRebound(to: CChar.self, capacity: capacity) { String(cString: $0).lowercased() }
        }
        #endif
    }
}
