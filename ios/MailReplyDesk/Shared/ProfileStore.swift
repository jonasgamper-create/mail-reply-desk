import Combine
import Foundation

struct UserProfile: Codable, Equatable {
    var firstName: String
    var lastName: String
    var gender: String
    var appName: String
    var formalSender: String
    var casualSender: String
    var mailAccounts: String
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
    var learningNotes: String
    var backendURL: String
    var aiBackendURL: String
    var gmailQuery: String

    static let `default` = UserProfile(
        firstName: "Creator",
        lastName: "Profil",
        gender: "neutral",
        appName: "Mail Reply Desk",
        formalSender: "Creator Team",
        casualSender: "Creator",
        mailAccounts: "",
        roleTitle: "Creator / Social Media Manager",
        niche: "Content Creation, Social Media, Brand-Kooperationen",
        services: "Reels, Stories, UGC, Shootings, Kampagnenkonzepte, Content-Kalender",
        mediaKitURL: "",
        socialLinks: "",
        rateCardNote: "Preise erst nach Briefing, Deliverables, Nutzungsrechten, Laufzeit und Budgetrahmen fixieren.",
        usageRightsPolicy: "Whitelisting/Spark Ads, Paid Usage, Exklusivität und Laufzeit immer separat klären.",
        briefingChecklist: "Kampagnenziel\nDeliverables\nTiming/Deadline\nBudgetrahmen\nNutzungsrechte/Laufzeit\nExklusivität\nFreigabeschleifen\nReporting",
        brandSafetyNoGos: "keine unbefristeten Nutzungsrechte ohne Vergütung, keine automatischen Zusagen, keine Preise ohne Scope",
        styleVoice: "klar, warm, professionell, kurz, nicht künstlich",
        learningNotes: "Antworten kurz halten. Erst Briefing, Scope, Timing, Budget und Nutzungsrechte klären. Keine Preise ohne vollständigen Scope zusagen.",
        backendURL: "",
        aiBackendURL: "",
        gmailQuery: "to:info@jonnyandlinda.com newer_than:30d"
    )

    static let linda = UserProfile(
        firstName: "Linda",
        lastName: "Hiller",
        gender: "female",
        appName: "Mail Reply Desk",
        formalSender: "Frau Hiller",
        casualSender: "Linda",
        mailAccounts: "info@jonnyandlinda.com\nlinda.hiller@skinfit.eu\nhillerlinda@icloud.com\nlindas.contentfactory@gmail.com",
        roleTitle: "Influencerin / Social Media Managerin",
        niche: "Lifestyle, Sport, Content Creation, Brand-Kooperationen",
        services: "Reels, Stories, UGC, Shootings, Kampagnenkonzepte, Content-Kalender",
        mediaKitURL: "",
        socialLinks: "",
        rateCardNote: "Preise erst nach Briefing, Deliverables, Nutzungsrechten, Laufzeit und Budgetrahmen fixieren.",
        usageRightsPolicy: "Whitelisting/Spark Ads, Paid Usage, Exklusivität und Laufzeit immer separat klären.",
        briefingChecklist: "Kampagnenziel\nDeliverables\nTiming/Deadline\nBudgetrahmen\nNutzungsrechte/Laufzeit\nExklusivität\nFreigabeschleifen\nReporting",
        brandSafetyNoGos: "keine unbefristeten Nutzungsrechte ohne Vergütung, keine automatischen Zusagen, keine Preise ohne Scope",
        styleVoice: "klar, warm, professionell, kurz, nicht künstlich",
        learningNotes: "Linda klingt freundlich, direkt und professionell. Kurz antworten, nie automatisch zusagen, bei Kooperationen zuerst Briefing, Budget und Nutzungsrechte klären.",
        backendURL: "",
        aiBackendURL: "",
        gmailQuery: "to:info@jonnyandlinda.com newer_than:30d"
    )

    init(
        firstName: String,
        lastName: String,
        gender: String,
        appName: String,
        formalSender: String,
        casualSender: String,
        mailAccounts: String,
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
        learningNotes: String,
        backendURL: String,
        aiBackendURL: String,
        gmailQuery: String
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.gender = gender
        self.appName = appName
        self.formalSender = formalSender
        self.casualSender = casualSender
        self.mailAccounts = mailAccounts
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
        self.learningNotes = learningNotes
        self.backendURL = backendURL
        self.aiBackendURL = aiBackendURL
        self.gmailQuery = gmailQuery
    }

    enum CodingKeys: String, CodingKey {
        case firstName
        case lastName
        case gender
        case appName
        case formalSender
        case casualSender
        case mailAccounts
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
        case learningNotes
        case backendURL
        case aiBackendURL
        case gmailQuery
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
        mailAccounts = try values.decodeIfPresent(String.self, forKey: .mailAccounts) ?? fallback.mailAccounts
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
        learningNotes = try values.decodeIfPresent(String.self, forKey: .learningNotes) ?? fallback.learningNotes
        backendURL = try values.decodeIfPresent(String.self, forKey: .backendURL) ?? fallback.backendURL
        aiBackendURL = try values.decodeIfPresent(String.self, forKey: .aiBackendURL) ?? fallback.aiBackendURL
        gmailQuery = try values.decodeIfPresent(String.self, forKey: .gmailQuery) ?? fallback.gmailQuery
    }

    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var initials: String {
        let first = firstName.first.map(String.init) ?? "M"
        let last = lastName.first.map(String.init) ?? "D"
        return first + last
    }

    var normalizedMailAccounts: [String] {
        mailAccounts
            .split(whereSeparator: { "\n,; ".contains($0) })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { $0.contains("@") }
    }

    var suggestedGmailQuery: String {
        let accounts = normalizedMailAccounts
        guard !accounts.isEmpty else { return gmailQuery.isEmpty ? UserProfile.default.gmailQuery : gmailQuery }
        let recipients = accounts.map { "to:\($0)" }.joined(separator: " OR ")
        return "(\(recipients)) newer_than:30d"
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
        Self.defaults.synchronize()
        UserDefaults.standard.synchronize()
    }

    func resetToDefault() {
        profile = .default
        save()
    }

    func loadLindaPreset() {
        profile = .linda
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

    static func saveProfile(_ profile: UserProfile) {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        defaults.set(data, forKey: profileKey)
        UserDefaults.standard.set(data, forKey: profileKey)
        defaults.synchronize()
        UserDefaults.standard.synchronize()
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
