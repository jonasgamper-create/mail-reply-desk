import Foundation
import UIKit

enum MessageContextStore {
    private static let contextKey = "mailReplyDesk.sharedContext.v1"
    private static let savedAtKey = "mailReplyDesk.sharedContext.savedAt.v1"
    private static let maxAge: TimeInterval = 60 * 30
    static let clipboardPrefix = "Mail Reply Desk Context"

    static func save(_ text: String) {
        let cleaned = clean(text)
        guard !cleaned.isEmpty else { return }

        let defaults = UserDefaults(suiteName: ProfileStore.appGroupID) ?? .standard
        defaults.set(cleaned, forKey: contextKey)
        defaults.set(Date().timeIntervalSince1970, forKey: savedAtKey)
        defaults.synchronize()

        UserDefaults.standard.set(cleaned, forKey: contextKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: savedAtKey)
        UserDefaults.standard.synchronize()

        UIPasteboard.general.string = "\(clipboardPrefix)\n\(cleaned)"
    }

    static func loadRecent() -> String? {
        let defaults = UserDefaults(suiteName: ProfileStore.appGroupID) ?? .standard
        if let text = loadRecent(from: defaults) {
            return text
        }
        if let text = loadRecent(from: .standard) {
            return text
        }
        return decodeClipboardContext(UIPasteboard.general.string)
    }

    static func decodeClipboardContext(_ text: String?) -> String? {
        guard let text else { return nil }
        let cleaned = clean(text)
        guard cleaned.hasPrefix(clipboardPrefix) else { return nil }
        let context = cleaned
            .dropFirst(clipboardPrefix.count)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return context.isEmpty ? nil : String(context)
    }

    static func clear() {
        [UserDefaults(suiteName: ProfileStore.appGroupID), .standard].compactMap { $0 }.forEach {
            $0.removeObject(forKey: contextKey)
            $0.removeObject(forKey: savedAtKey)
            $0.synchronize()
        }
    }

    private static func loadRecent(from defaults: UserDefaults) -> String? {
        let savedAt = defaults.double(forKey: savedAtKey)
        guard savedAt > 0, Date().timeIntervalSince1970 - savedAt <= maxAge else {
            return nil
        }
        guard let text = defaults.string(forKey: contextKey) else { return nil }
        let cleaned = clean(text)
        return cleaned.isEmpty ? nil : cleaned
    }

    private static func clean(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\u{00a0}", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
