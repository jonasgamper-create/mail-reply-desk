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
    @Published var messages: [GmailInboxMessage] = []
    @Published var selectedThreadId = ""
    @Published var isLoading = false
    @Published var importedSubject = ""

    func checkStatus(baseURL: String) async {
        await runLoading {
            let status: GmailInboxStatus = try await request(baseURL: baseURL, path: "/gmail/status")
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
            statusText = response.messages.isEmpty ? "Keine passenden Mails gefunden" : "\(response.messages.count) Mails geladen"
        }
    }

    func importThread(_ message: GmailInboxMessage, baseURL: String) async {
        await runLoading {
            let thread: GmailInboxThread = try await request(
                baseURL: baseURL,
                path: "/gmail/threads/\(message.threadId)"
            )
            MessageContextStore.save(thread.contextText)
            selectedThreadId = thread.id
            importedSubject = message.subjectLine
            statusText = "Thread für Tastatur übernommen"
        }
    }

    private func runLoading(_ operation: () async throws -> Void) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await operation()
        } catch {
            statusText = error.localizedDescription
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
            let serverMessage = (try? JSONDecoder().decode(ServerError.self, from: data))?.message
            throw GmailInboxError.server(serverMessage ?? "Backend meldet HTTP \(http.statusCode).")
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func makeURL(
        baseURL: String,
        path: String,
        queryItems: [URLQueryItem] = []
    ) throws -> URL {
        let cleaned = baseURL.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
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
    }
}
