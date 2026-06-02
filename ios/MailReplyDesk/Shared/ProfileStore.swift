import Combine
import Foundation

struct UserProfile: Codable, Equatable {
    var firstName: String
    var lastName: String
    var gender: String
    var appName: String
    var formalSender: String
    var casualSender: String
    var styleVoice: String
    var backendURL: String

    static let `default` = UserProfile(
        firstName: "Linda",
        lastName: "Hiller",
        gender: "female",
        appName: "Mail Reply Desk",
        formalSender: "Frau Hiller",
        casualSender: "Linda",
        styleVoice: "klar, warm, professionell, nicht kuenstlich",
        backendURL: ""
    )

    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var initials: String {
        let first = firstName.first.map(String.init) ?? "M"
        let last = lastName.first.map(String.init) ?? "D"
        return first + last
    }
}

final class ProfileStore: ObservableObject {
    static let appGroupID = "group.com.jonasgamper.mailreplydesk"
    private static let profileKey = "mailReplyDesk.profile.v1"

    @Published var profile: UserProfile {
        didSet { save() }
    }

    init() {
        profile = Self.loadProfile()
    }

    func save() {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        Self.defaults.set(data, forKey: Self.profileKey)
        UserDefaults.standard.set(data, forKey: Self.profileKey)
    }

    static func loadProfile() -> UserProfile {
        if let data = defaults.data(forKey: profileKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            return profile
        }
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            return profile
        }
        return .default
    }

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }
}
