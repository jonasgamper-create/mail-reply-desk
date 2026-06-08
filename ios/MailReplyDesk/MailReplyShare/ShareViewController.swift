import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private let statusLabel = UILabel()
    private let detailLabel = UILabel()
    private let previewLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        Task { await importSharedContext() }
    }

    private func configureView() {
        view.backgroundColor = UIColor.systemBackground

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false

        statusLabel.text = "Kontext wird übernommen"
        statusLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0

        detailLabel.text = "Danach in Mail oder WhatsApp die Mail Reply Desk Tastatur öffnen und Antwort oder Check tippen."
        detailLabel.font = .systemFont(ofSize: 15, weight: .regular)
        detailLabel.textColor = .secondaryLabel
        detailLabel.textAlignment = .center
        detailLabel.numberOfLines = 0

        previewLabel.font = .systemFont(ofSize: 13, weight: .regular)
        previewLabel.textColor = .secondaryLabel
        previewLabel.numberOfLines = 6
        previewLabel.textAlignment = .left
        previewLabel.backgroundColor = UIColor.secondarySystemBackground
        previewLabel.layer.cornerRadius = 8
        previewLabel.layer.masksToBounds = true
        previewLabel.isHidden = true

        let done = UIButton(type: .system)
        done.setTitle("Fertig", for: .normal)
        done.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        done.addTarget(self, action: #selector(finish), for: .touchUpInside)

        stack.addArrangedSubview(statusLabel)
        stack.addArrangedSubview(detailLabel)
        stack.addArrangedSubview(previewLabel)
        stack.addArrangedSubview(done)
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func importSharedContext() async {
        let text = await extractSharedText()
        await MainActor.run {
            guard let text, !text.isEmpty else {
                statusLabel.text = "Kein Text erkannt"
                detailLabel.text = "Bitte markierten Text, eine Nachricht oder eine Mail an Mail Reply Desk teilen."
                return
            }

            MessageContextStore.save(text)
            statusLabel.text = "Kontext gespeichert"
            detailLabel.text = "Jetzt Antwortfeld öffnen, Mail Reply Desk Tastatur wählen und Antwort, 3x oder Check tippen. Die Tastatur zeigt oben Kontext an."
            previewLabel.text = previewText(text)
            previewLabel.isHidden = false
        }
    }

    private func previewText(_ text: String) -> String {
        let cleaned = text
            .replacingOccurrences(of: "\n\n\n", with: "\n\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.count <= 420 { return "  \(cleaned)  " }
        return "  \(cleaned.prefix(420))...  "
    }

    private func extractSharedText() async -> String? {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            return nil
        }

        var parts: [String] = []
        for item in extensionItems {
            guard let providers = item.attachments else { continue }
            for provider in providers {
                if let text = await loadText(from: provider) {
                    parts.append(text)
                }
            }
        }

        let joined = parts
            .joined(separator: "\n\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return joined.isEmpty ? nil : joined
    }

    private func loadText(from provider: NSItemProvider) async -> String? {
        if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            return await loadString(from: provider, typeIdentifier: UTType.plainText.identifier)
        }
        if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
            return await loadString(from: provider, typeIdentifier: UTType.text.identifier)
        }
        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier),
           let url = await loadURL(from: provider, typeIdentifier: UTType.url.identifier) {
            return url.absoluteString
        }
        return nil
    }

    private func loadString(from provider: NSItemProvider, typeIdentifier: String) async -> String? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, _ in
                if let string = item as? String {
                    continuation.resume(returning: string)
                } else if let data = item as? Data,
                          let string = String(data: data, encoding: .utf8) {
                    continuation.resume(returning: string)
                } else if let url = item as? URL {
                    continuation.resume(returning: url.absoluteString)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func loadURL(from provider: NSItemProvider, typeIdentifier: String) async -> URL? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, _ in
                if let url = item as? URL {
                    continuation.resume(returning: url)
                } else if let data = item as? Data,
                          let string = String(data: data, encoding: .utf8),
                          let url = URL(string: string) {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    @objc private func finish() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
