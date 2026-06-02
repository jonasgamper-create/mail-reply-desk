import UIKit

final class KeyboardViewController: UIInputViewController {
    private var profile = ProfileStore.loadProfile()
    private let rootStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboard()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        profile = ProfileStore.loadProfile()
        rebuildKeyboard()
    }

    private func setupKeyboard() {
        view.backgroundColor = UIColor.systemGray6
        rootStack.axis = .vertical
        rootStack.spacing = 7
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootStack)

        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            rootStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            rootStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            rootStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8)
        ])

        rebuildKeyboard()
    }

    private func rebuildKeyboard() {
        rootStack.arrangedSubviews.forEach { view in
            rootStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        rootStack.addArrangedSubview(makeHeaderRow())
        rootStack.addArrangedSubview(makeActionRow())
        rootStack.addArrangedSubview(makeCreatorRow())
        rootStack.addArrangedSubview(makeDraftRow())
        rootStack.addArrangedSubview(makeKeyRow(["q", "w", "e", "r", "t", "z", "u", "i", "o", "p", "ue"]))
        rootStack.addArrangedSubview(makeKeyRow(["a", "s", "d", "f", "g", "h", "j", "k", "l", "oe", "ae"]))
        rootStack.addArrangedSubview(makeKeyRow(["y", "x", "c", "v", "b", "n", "m", ".", ",", "⌫"]))
        rootStack.addArrangedSubview(makeBottomRow())
    }

    private func makeHeaderRow() -> UIStackView {
        let row = horizontalRow()
        let title = UILabel()
        title.text = "\(profile.initials)  \(profile.appName)"
        title.font = .systemFont(ofSize: 13, weight: .semibold)
        title.textColor = .secondaryLabel

        let next = makeButton("🌐", weight: .regular)
        next.addTarget(self, action: #selector(nextKeyboard), for: .touchUpInside)

        row.addArrangedSubview(title)
        row.addArrangedSubview(next)
        next.widthAnchor.constraint(equalToConstant: 46).isActive = true
        return row
    }

    private func makeActionRow() -> UIStackView {
        let row = horizontalRow()
        [
            ("Antwort", #selector(insertReplyDraft)),
            ("Mail", #selector(insertNewMailDraft)),
            ("Termin", #selector(insertEventDraft))
        ].forEach { title, selector in
            let button = makeButton(title, weight: .semibold)
            button.backgroundColor = UIColor.systemTeal
            button.setTitleColor(.white, for: .normal)
            button.addTarget(self, action: selector, for: .touchUpInside)
            row.addArrangedSubview(button)
        }
        return row
    }

    private func makeCreatorRow() -> UIStackView {
        let row = horizontalRow()
        [
            ("Briefing", #selector(insertBriefingDraft)),
            ("Preis", #selector(insertPricingDraft)),
            ("Follow-up", #selector(insertFollowUpDraft)),
            ("MediaKit", #selector(insertMediaKitDraft))
        ].forEach { title, selector in
            let button = makeButton(title, weight: .medium)
            button.addTarget(self, action: selector, for: .touchUpInside)
            row.addArrangedSubview(button)
        }
        return row
    }

    private func makeDraftRow() -> UIStackView {
        let row = horizontalRow()
        [
            ("Kurz", #selector(insertShortDraft)),
            ("Warm", #selector(insertFriendlyDraft)),
            ("Profi", #selector(insertProfessionalDraft))
        ].forEach { title, selector in
            let button = makeButton(title, weight: .medium)
            button.addTarget(self, action: selector, for: .touchUpInside)
            row.addArrangedSubview(button)
        }
        return row
    }

    private func makeKeyRow(_ keys: [String]) -> UIStackView {
        let row = horizontalRow()
        keys.forEach { key in
            let display = displayTitle(for: key)
            let button = makeButton(display, weight: .regular)
            button.accessibilityIdentifier = key
            if key == "⌫" {
                button.addTarget(self, action: #selector(deleteBackward), for: .touchUpInside)
            } else {
                button.addTarget(self, action: #selector(insertKey(_:)), for: .touchUpInside)
            }
            row.addArrangedSubview(button)
        }
        return row
    }

    private func makeBottomRow() -> UIStackView {
        let row = horizontalRow()

        let numbers = makeButton("123", weight: .regular)
        numbers.addTarget(self, action: #selector(insertNumbersHint), for: .touchUpInside)

        let space = makeButton("Leerzeichen", weight: .regular)
        space.addTarget(self, action: #selector(insertSpace), for: .touchUpInside)

        let returnKey = makeButton("Return", weight: .regular)
        returnKey.addTarget(self, action: #selector(insertReturn), for: .touchUpInside)

        row.addArrangedSubview(numbers)
        row.addArrangedSubview(space)
        row.addArrangedSubview(returnKey)
        numbers.widthAnchor.constraint(equalToConstant: 56).isActive = true
        returnKey.widthAnchor.constraint(equalToConstant: 78).isActive = true
        return row
    }

    private func horizontalRow() -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 6
        row.distribution = .fillEqually
        return row
    }

    private func makeButton(_ title: String, weight: UIFont.Weight) -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.baseBackgroundColor = UIColor.white
        configuration.baseForegroundColor = UIColor.label
        configuration.cornerStyle = .medium
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6)

        let button = UIButton(configuration: configuration)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: weight)
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.08
        button.layer.shadowRadius = 1
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 38).isActive = true
        return button
    }

    private func displayTitle(for key: String) -> String {
        switch key {
        case "ue": return "ü"
        case "oe": return "ö"
        case "ae": return "ä"
        default: return key
        }
    }

    private func insertText(_ text: String) {
        textDocumentProxy.insertText(text)
    }

    private func currentContext() -> String {
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        let after = textDocumentProxy.documentContextAfterInput ?? ""
        return (before + " " + after).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func makeDraft(kind: DraftKind) -> String {
        let context = currentContext()
        let topic = context.isEmpty ? "deine Nachricht" : context
        let formal = kind.formal
        let greeting = formal ? "Guten Tag," : "Hallo,"
        let signoff = formal ? "Beste Gruesse\n\(profile.fullName)" : "Liebe Gruesse\n\(profile.casualSender)"

        let body: String
        switch kind {
        case .reply:
            body = "vielen Dank fuer die Nachricht. Ich melde mich gerne dazu und halte die naechsten Schritte klar fest."
        case .newMail:
            body = "ich melde mich wegen \(topic). Die wichtigsten Punkte habe ich unten kompakt zusammengefasst."
        case .event:
            body = "ich bereite gerne einen Termin dazu vor. Bitte gib mir kurz Bescheid, welcher Zeitpunkt fuer dich passt."
        case .short:
            body = "danke dir. Das passt grundsaetzlich. Gib mir gerne kurz Bescheid, wie wir weiter vorgehen."
        case .friendly:
            body = "danke dir fuer die Nachricht. Das klingt grundsaetzlich spannend, ich stimme die Details gerne sauber mit dir ab."
        case .professional:
            body = "vielen Dank fuer Ihre Nachricht. Ich pruefe die Details gerne und halte die naechsten Schritte verbindlich fest."
        case .briefing:
            body = "vielen Dank fuer die Anfrage. Grundsaetzlich klingt die Kooperation interessant. Fuer eine konkrete Einschaetzung brauche ich bitte noch:\n\n\(briefingList(limit: 6))"
        case .pricing:
            body = "zum Budget bzw. Preis kann ich eine serioese Einschaetzung geben, sobald der Scope klar ist. Relevant sind vor allem:\n\n\(briefingList(limit: 6))\n\n\(profile.rateCardNote)\n\n\(profile.usageRightsPolicy)"
        case .followUp:
            body = formal
                ? "ich wollte wegen der Anfrage kurz nachfragen. Wenn die Kooperation weiterhin relevant ist, senden Sie mir gerne noch die fehlenden Details:\n\n\(briefingList(limit: 5))"
                : "ich wollte wegen der Anfrage kurz nachfragen. Wenn die Kooperation weiterhin relevant ist, schick mir gerne noch die fehlenden Details:\n\n\(briefingList(limit: 5))"
        case .mediaKit:
            body = mediaKitBody(formal: formal)
        }

        return "\(greeting)\n\n\(body)\n\n\(signoff)"
    }

    private func briefingList(limit: Int) -> String {
        let items = profile.briefingChecklist
            .split(whereSeparator: { "\n,;".contains($0) })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(limit)
        let fallback = ["Kampagnenziel", "Deliverables", "Timing/Deadline", "Budgetrahmen", "Nutzungsrechte/Laufzeit", "Freigabeschleifen"].prefix(limit)
        let source = items.isEmpty ? Array(fallback) : Array(items)
        return source.map { "- \($0)" }.joined(separator: "\n")
    }

    private func mediaKitBody(formal: Bool) -> String {
        let links = [profile.mediaKitURL, profile.socialLinks]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        let services = profile.services.trimmingCharacters(in: .whitespacesAndNewlines)
        let linkBlock = links.isEmpty ? "[Media-Kit Link ergaenzen]" : links
        let serviceBlock = services.isEmpty ? "[Leistungen ergaenzen]" : services
        if formal {
            return "hier finden Sie die wichtigsten Infos fuer eine moegliche Zusammenarbeit:\n\n\(linkBlock)\n\nLeistungen:\n\(serviceBlock)\n\nFuer ein konkretes Angebot brauche ich bitte Briefing, Deliverables, Timing, Budget und Nutzungsrechte."
        }
        return "hier findest du die wichtigsten Infos fuer eine moegliche Zusammenarbeit:\n\n\(linkBlock)\n\nLeistungen:\n\(serviceBlock)\n\nFuer ein konkretes Angebot brauche ich bitte Briefing, Deliverables, Timing, Budget und Nutzungsrechte."
    }

    @objc private func nextKeyboard() {
        advanceToNextInputMode()
    }

    @objc private func insertReplyDraft() {
        insertText(makeDraft(kind: .reply))
    }

    @objc private func insertNewMailDraft() {
        insertText(makeDraft(kind: .newMail))
    }

    @objc private func insertEventDraft() {
        insertText(makeDraft(kind: .event))
    }

    @objc private func insertShortDraft() {
        insertText(makeDraft(kind: .short))
    }

    @objc private func insertFriendlyDraft() {
        insertText(makeDraft(kind: .friendly))
    }

    @objc private func insertProfessionalDraft() {
        insertText(makeDraft(kind: .professional))
    }

    @objc private func insertBriefingDraft() {
        insertText(makeDraft(kind: .briefing))
    }

    @objc private func insertPricingDraft() {
        insertText(makeDraft(kind: .pricing))
    }

    @objc private func insertFollowUpDraft() {
        insertText(makeDraft(kind: .followUp))
    }

    @objc private func insertMediaKitDraft() {
        insertText(makeDraft(kind: .mediaKit))
    }

    @objc private func insertKey(_ sender: UIButton) {
        guard let key = sender.accessibilityIdentifier else { return }
        insertText(displayTitle(for: key))
    }

    @objc private func deleteBackward() {
        textDocumentProxy.deleteBackward()
    }

    @objc private func insertSpace() {
        insertText(" ")
    }

    @objc private func insertReturn() {
        insertText("\n")
    }

    @objc private func insertNumbersHint() {
        insertText("123")
    }
}

private enum DraftKind {
    case reply
    case newMail
    case event
    case short
    case friendly
    case professional
    case briefing
    case pricing
    case followUp
    case mediaKit

    var formal: Bool {
        self == .professional || self == .briefing || self == .pricing || self == .followUp || self == .mediaKit
    }
}
