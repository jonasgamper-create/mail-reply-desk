import Foundation
import UIKit

struct GmailInboxStatus: Decodable {
    let configured: Bool
    let connected: Bool
    let message: String
    let authUrl: String?
}

struct GmailInboxListResponse: Decodable {
    let query: String
    let messages: [GmailInboxMessage]
}

struct GmailInboxThread: Decodable {
    let id: String
    let messages: [GmailInboxMessage]
    let latest: GmailInboxMessage?
    let contextText: String
}

struct GmailInboxMessage: Identifiable, Decodable, Equatable {
    let id: String
    let threadId: String
    let from: String
    let to: String
    let subject: String
    let date: String
    let snippet: String
    let body: String?

    var subjectLine: String {
        subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "(Ohne Betreff)" : subject
    }

    var senderLine: String {
        let parsed = Self.parseAddress(from)
        return parsed.name.isEmpty ? (parsed.email.isEmpty ? "Unbekannt" : parsed.email) : parsed.name
    }

    var previewLine: String {
        snippet.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func parseAddress(_ value: String) -> (name: String, email: String) {
        let email = value.range(of: #"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}"#, options: [.regularExpression, .caseInsensitive])
            .map { String(value[$0]) } ?? ""
        let name = value
            .replacingOccurrences(of: email, with: "")
            .replacingOccurrences(of: "<", with: "")
            .replacingOccurrences(of: ">", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (name, email)
    }
}

enum GmailInboxError: LocalizedError {
    case missingBackendURL
    case invalidURL
    case server(String)

    var errorDescription: String? {
        switch self {
        case .missingBackendURL:
            return "Backend-URL fehlt. Am iPhone die Mac-IP eintragen, z.B. http://192.168.1.20:8787."
        case .invalidURL:
            return "Backend-URL ist ungültig."
        case .server(let message):
            return message
        }
    }
}

@MainActor
final class GmailInboxViewModel: ObservableObject {
    @Published var statusText = "Nicht verbunden"
    @Published var isConfigured = false
    @Published var isConnected = false
    @Published var messages: [GmailInboxMessage] = []
    @Published var selectedThreadId = ""
    @Published var isLoading = false
    @Published var importedSubject = ""
    @Published var importedContextPreview = ""

    var statusBadge: String {
        if isConnected { return "Verbunden" }
        if isConfigured { return "OAuth offen" }
        return "Setup fehlt"
    }

    func checkStatus(baseURL: String) async {
        await runLoading {
            let status: GmailInboxStatus = try await request(baseURL: baseURL, path: "/gmail/status")
            isConfigured = status.configured
            isConnected = status.connected
            statusText = status.message
        }
    }

    func openOAuth(baseURL: String) {
        do {
            let url = try makeURL(baseURL: baseURL, path: "/auth/google")
            UIApplication.shared.open(url)
            statusText = "Google Login geöffnet"
        } catch {
            statusText = error.localizedDescription
        }
    }

    func loadMessages(baseURL: String, query: String) async {
        await runLoading {
            let response: GmailInboxListResponse = try await request(
                baseURL: baseURL,
                path: "/gmail/messages",
                queryItems: [
                    URLQueryItem(name: "max", value: "12"),
                    URLQueryItem(name: "q", value: query)
                ]
            )
            messages = response.messages
            selectedThreadId = ""
            importedSubject = ""
            importedContextPreview = ""
            statusText = response.messages.isEmpty ? "Keine passenden Mails gefunden" : "\(response.messages.count) Mails geladen"
        }
    }

    func importThread(_ message: GmailInboxMessage, baseURL: String) async {
        await runLoading {
            let thread: GmailInboxThread = try await request(
                baseURL: baseURL,
                path: "/gmail/threads/\(message.threadId)"
            )
            let context = thread.contextText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? formatFallbackContext(thread.messages)
                : thread.contextText
            MessageContextStore.save(context)
            selectedThreadId = thread.id
            importedSubject = message.subjectLine
            importedContextPreview = makePreview(context)
            statusText = "Thread übernommen. Jetzt Antwortfeld öffnen, Tastatur wählen und Antwort, 3x oder Check tippen."
        }
    }

    func copyImportedContextToClipboard() {
        guard let context = MessageContextStore.loadRecent(), !context.isEmpty else {
            statusText = "Kein aktueller Thread gespeichert."
            return
        }
        UIPasteboard.general.string = "\(MessageContextStore.clipboardPrefix)\n\(context)"
        statusText = "Thread-Kontext kopiert."
    }

    private func runLoading(_ operation: () async throws -> Void) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await operation()
        } catch {
            statusText = readableError(error)
        }
    }

    private func request<T: Decodable>(
        baseURL: String,
        path: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> T {
        let url = try makeURL(baseURL: baseURL, path: path, queryItems: queryItems)
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw GmailInboxError.server("Keine HTTP-Antwort vom Backend.")
        }
        guard (200..<300).contains(http.statusCode) else {
            let decoded = try? JSONDecoder().decode(ServerError.self, from: data)
            let serverMessage = decoded?.message ?? decoded?.error
            throw GmailInboxError.server(serverMessage ?? "Backend meldet HTTP \(http.statusCode).")
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func makeURL(
        baseURL: String,
        path: String,
        queryItems: [URLQueryItem] = []
    ) throws -> URL {
        let cleaned = normalizeBaseURL(baseURL)
        guard !cleaned.isEmpty else { throw GmailInboxError.missingBackendURL }
        guard var components = URLComponents(string: cleaned + path) else { throw GmailInboxError.invalidURL }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else { throw GmailInboxError.invalidURL }
        return url
    }

    private struct ServerError: Decodable {
        let message: String?
        let error: String?
    }

    private func normalizeBaseURL(_ value: String) -> String {
        var cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        while cleaned.hasSuffix("/") {
            cleaned.removeLast()
        }
        for suffix in ["/auth/google", "/gmail/status", "/gmail/messages"] where cleaned.hasSuffix(suffix) {
            cleaned.removeLast(suffix.count)
        }
        return cleaned
    }

    private func readableError(_ error: Error) -> String {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorCannotConnectToHost, NSURLErrorNotConnectedToInternet, NSURLErrorTimedOut:
                return "Backend nicht erreichbar. Mac und iPhone müssen im selben WLAN sein. Backend mit scripts/start-phone-backend.sh starten und die Mac-IP eintragen."
            case NSURLErrorAppTransportSecurityRequiresSecureConnection:
                return "iOS blockiert die HTTP-Verbindung. Bitte lokale Netzwerkfreigabe erlauben und die Backend-URL mit http://192.168... verwenden."
            default:
                break
            }
        }
        return error.localizedDescription
    }

    private func formatFallbackContext(_ messages: [GmailInboxMessage]) -> String {
        messages.map { message in
            [
                "From: \(message.from)",
                "To: \(message.to)",
                "Date: \(message.date)",
                "Subject: \(message.subject)",
                "",
                message.body ?? message.snippet
            ].joined(separator: "\n")
        }.joined(separator: "\n\n---\n\n")
    }

    private func makePreview(_ context: String) -> String {
        let cleaned = context
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.count <= 180 { return cleaned }
        return String(cleaned.prefix(180)).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
    }
}
