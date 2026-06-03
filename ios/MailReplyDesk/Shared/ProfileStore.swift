import Combine
import Foundation

struct UserProfile: Codable, Equatable {
    var firstName: String
    var lastName: String
    var gender: String
    var appName: String
    var formalSender: String
    var casualSender: String
    var roleTitle: String
    var niche: String
    var services: String
    var mediaKitURL: String
    var socialLinks: String
    var rateCardNote: String
    var usageRightsPolicy: String
    var briefingChecklist: String
    var brandSafetyNoGos: String
    var styleVoice: String
    var backendURL: String

    static let `default` = UserProfile(
        firstName: "Linda",
        lastName: "Hiller",
        gender: "female",
        appName: "Mail Reply Desk",
        formalSender: "Frau Hiller",
        casualSender: "Linda",
        roleTitle: "Influencerin / Social Media Managerin",
        niche: "Lifestyle, Sport, Content Creation, Brand-Kooperationen",
        services: "Reels, Stories, UGC, Shootings, Kampagnenkonzepte, Content-Kalender",
        mediaKitURL: "",
        socialLinks: "",
        rateCardNote: "Preise erst nach Briefing, Deliverables, Nutzungsrechten, Laufzeit und Budgetrahmen fixieren.",
        usageRightsPolicy: "Whitelisting/Spark Ads, Paid Usage, Exklusivitaet und Laufzeit immer separat klaeren.",
        briefingChecklist: "Kampagnenziel\nDeliverables\nTiming/Deadline\nBudgetrahmen\nNutzungsrechte/Laufzeit\nExklusivitaet\nFreigabeschleifen\nReporting",
        brandSafetyNoGos: "keine unbefristeten Nutzungsrechte ohne Verguetung, keine automatischen Zusagen, keine Preise ohne Scope",
        styleVoice: "klar, warm, professionell, nicht kuenstlich",
        backendURL: ""
    )

    init(
        firstName: String,
        lastName: String,
        gender: String,
        appName: String,
        formalSender: String,
        casualSender: String,
        roleTitle: String,
        niche: String,
        services: String,
        mediaKitURL: String,
        socialLinks: String,
        rateCardNote: String,
        usageRightsPolicy: String,
        briefingChecklist: String,
        brandSafetyNoGos: String,
        styleVoice: String,
        backendURL: String
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.gender = gender
        self.appName = appName
        self.formalSender = formalSender
        self.casualSender = casualSender
        self.roleTitle = roleTitle
        self.niche = niche
        self.services = services
        self.mediaKitURL = mediaKitURL
        self.socialLinks = socialLinks
        self.rateCardNote = rateCardNote
        self.usageRightsPolicy = usageRightsPolicy
        self.briefingChecklist = briefingChecklist
        self.brandSafetyNoGos = brandSafetyNoGos
        self.styleVoice = styleVoice
        self.backendURL = backendURL
    }

    enum CodingKeys: String, CodingKey {
        case firstName
        case lastName
        case gender
        case appName
        case formalSender
        case casualSender
        case roleTitle
        case niche
        case services
        case mediaKitURL
        case socialLinks
        case rateCardNote
        case usageRightsPolicy
        case briefingChecklist
        case brandSafetyNoGos
        case styleVoice
        case backendURL
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = UserProfile.default
        firstName = try values.decodeIfPresent(String.self, forKey: .firstName) ?? fallback.firstName
        lastName = try values.decodeIfPresent(String.self, forKey: .lastName) ?? fallback.lastName
        gender = try values.decodeIfPresent(String.self, forKey: .gender) ?? fallback.gender
        appName = try values.decodeIfPresent(String.self, forKey: .appName) ?? fallback.appName
        formalSender = try values.decodeIfPresent(String.self, forKey: .formalSender) ?? fallback.formalSender
        casualSender = try values.decodeIfPresent(String.self, forKey: .casualSender) ?? fallback.casualSender
        roleTitle = try values.decodeIfPresent(String.self, forKey: .roleTitle) ?? fallback.roleTitle
        niche = try values.decodeIfPresent(String.self, forKey: .niche) ?? fallback.niche
        services = try values.decodeIfPresent(String.self, forKey: .services) ?? fallback.services
        mediaKitURL = try values.decodeIfPresent(String.self, forKey: .mediaKitURL) ?? fallback.mediaKitURL
        socialLinks = try values.decodeIfPresent(String.self, forKey: .socialLinks) ?? fallback.socialLinks
        rateCardNote = try values.decodeIfPresent(String.self, forKey: .rateCardNote) ?? fallback.rateCardNote
        usageRightsPolicy = try values.decodeIfPresent(String.self, forKey: .usageRightsPolicy) ?? fallback.usageRightsPolicy
        briefingChecklist = try values.decodeIfPresent(String.self, forKey: .briefingChecklist) ?? fallback.briefingChecklist
        brandSafetyNoGos = try values.decodeIfPresent(String.self, forKey: .brandSafetyNoGos) ?? fallback.brandSafetyNoGos
        styleVoice = try values.decodeIfPresent(String.self, forKey: .styleVoice) ?? fallback.styleVoice
        backendURL = try values.decodeIfPresent(String.self, forKey: .backendURL) ?? fallback.backendURL
    }

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

    func resetToDefault() {
        profile = .default
        save()
    }

    func importProfile(from text: String) -> Bool {
        guard let imported = Self.decodeProfile(from: text) else { return false }
        profile = imported
        save()
        return true
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

    static func exportString(for profile: UserProfile) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(profile),
              let json = String(data: data, encoding: .utf8) else {
            return ""
        }
        return "Mail Reply Desk Profile\n\(json)"
    }

    static func decodeProfile(from text: String) -> UserProfile? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let jsonText: String
        if let start = trimmed.firstIndex(of: "{"),
           let end = trimmed.lastIndex(of: "}") {
            jsonText = String(trimmed[start...end])
        } else {
            jsonText = trimmed
        }
        guard let data = jsonText.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(UserProfile.self, from: data)
    }

    static var isAppGroupAvailable: Bool {
        UserDefaults(suiteName: appGroupID) != nil
    }

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }
}
