import UIKit

final class KeyboardViewController: UIInputViewController {
    private enum KeyboardMode {
        case letters
        case numbers
        case tools
    }

    private enum OutputLanguage {
        case german
        case english

        mutating func toggle() {
            self = self == .german ? .english : .german
        }

        var shortTitle: String {
            self == .german ? "DE" : "EN"
        }
    }

    private enum Formality {
        case casual
        case formal

        mutating func toggle() {
            self = self == .casual ? .formal : .casual
        }

        var shortTitle: String {
            self == .casual ? "Du" : "Sie"
        }
    }

    private var profile = ProfileStore.loadProfile()
    private var keyboardMode: KeyboardMode = .letters
    private var language: OutputLanguage = .german
    private var formality: Formality = .formal
    private var isShifted = false
    private let rootStack = UIStackView()
    private var heightConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboard()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        profile = ProfileStore.loadProfile()
        rebuildKeyboard()
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()
        if heightConstraint == nil {
            let constraint = view.heightAnchor.constraint(equalToConstant: 306)
            constraint.priority = UILayoutPriority(999)
            constraint.isActive = true
            heightConstraint = constraint
        }
    }

    private func setupKeyboard() {
        view.backgroundColor = UIColor.systemGray6
        rootStack.axis = .vertical
        rootStack.spacing = 6
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootStack)

        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 7),
            rootStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -7),
            rootStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 7),
            rootStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -7)
        ])

        rebuildKeyboard()
    }

    private func rebuildKeyboard() {
        rootStack.arrangedSubviews.forEach { subview in
            rootStack.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }

        rootStack.addArrangedSubview(makeHeaderRow())

        switch keyboardMode {
        case .letters:
            rootStack.addArrangedSubview(makeQuickReplyRow())
            rootStack.addArrangedSubview(makeKeyRow(["q", "w", "e", "r", "t", "z", "u", "i", "o", "p"]))
            rootStack.addArrangedSubview(makeKeyRow(["a", "s", "d", "f", "g", "h", "j", "k", "l"]))
            rootStack.addArrangedSubview(makeKeyRow(["shift", "y", "x", "c", "v", "b", "n", "m", "delete"]))
            rootStack.addArrangedSubview(makeBottomRow())
        case .numbers:
            rootStack.addArrangedSubview(makeQuickReplyRow())
            rootStack.addArrangedSubview(makeKeyRow(["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]))
            rootStack.addArrangedSubview(makeKeyRow(["-", "/", ":", ";", "(", ")", "€", "&", "@"]))
            rootStack.addArrangedSubview(makeKeyRow(["#+=", ".", ",", "?", "!", "'", "\"", "delete"]))
            rootStack.addArrangedSubview(makeBottomRow())
        case .tools:
            rootStack.addArrangedSubview(makeToolRow([
                ("Antwort", #selector(insertReplyDraft)),
                ("Mail", #selector(insertNewMailDraft)),
                ("Termin", #selector(insertEventDraft))
            ]))
            rootStack.addArrangedSubview(makeToolRow([
                ("3 Entw.", #selector(insertThreeDrafts)),
                ("Kuerzer", #selector(insertShortDraft)),
                ("Freundl.", #selector(insertFriendlyDraft)),
                ("Profi", #selector(insertProfessionalDraft))
            ]))
            rootStack.addArrangedSubview(makeToolRow([
                ("Briefing", #selector(insertBriefingDraft)),
                ("Preis", #selector(insertPricingDraft)),
                ("Follow-up", #selector(insertFollowUpDraft)),
                ("MediaKit", #selector(insertMediaKitDraft))
            ]))
            rootStack.addArrangedSubview(makeToolRow([
                ("Absage", #selector(insertDeclineDraft)),
                ("Rechnung", #selector(insertInvoiceDraft)),
                ("Signatur", #selector(insertSignature)),
                ("Diktat", #selector(openDictationKeyboard))
            ]))
            rootStack.addArrangedSubview(makeToolsBottomRow())
        }
    }

    private func makeHeaderRow() -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 6
        row.alignment = .fill
        row.distribution = .fill

        let title = UILabel()
        title.text = "\(profile.initials) \(profile.appName)"
        title.font = .systemFont(ofSize: 13, weight: .semibold)
        title.textColor = .secondaryLabel
        title.adjustsFontSizeToFitWidth = true
        title.minimumScaleFactor = 0.72
        title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let mode = makeButton(keyboardMode == .tools ? "ABC" : "Tools", weight: .semibold)
        mode.addTarget(self, action: #selector(toggleTools), for: .touchUpInside)
        mode.widthAnchor.constraint(equalToConstant: 58).isActive = true

        let lang = makeButton(language.shortTitle, weight: .semibold)
        lang.addTarget(self, action: #selector(toggleLanguage), for: .touchUpInside)
        lang.widthAnchor.constraint(equalToConstant: 44).isActive = true

        let tone = makeButton(formality.shortTitle, weight: .semibold)
        tone.addTarget(self, action: #selector(toggleFormality), for: .touchUpInside)
        tone.widthAnchor.constraint(equalToConstant: 48).isActive = true

        let next = makeButton("Globus", weight: .regular)
        next.addTarget(self, action: #selector(nextKeyboard), for: .touchUpInside)
        next.widthAnchor.constraint(equalToConstant: 66).isActive = true

        row.addArrangedSubview(title)
        row.addArrangedSubview(mode)
        row.addArrangedSubview(lang)
        row.addArrangedSubview(tone)
        row.addArrangedSubview(next)
        return row
    }

    private func makeQuickReplyRow() -> UIStackView {
        makeToolRow([
            ("Antwort", #selector(insertReplyDraft)),
            ("Kuerzer", #selector(insertShortDraft)),
            ("Freundl.", #selector(insertFriendlyDraft)),
            ("Profi", #selector(insertProfessionalDraft))
        ])
    }

    private func makeToolRow(_ items: [(String, Selector)]) -> UIStackView {
        let row = horizontalRow()
        items.forEach { title, selector in
            let button = makeButton(title, weight: .medium)
            if title == "Antwort" || title == "Mail" || title == "Termin" {
                button.configuration?.baseBackgroundColor = UIColor.systemTeal
                button.configuration?.baseForegroundColor = UIColor.white
            }
            button.addTarget(self, action: selector, for: .touchUpInside)
            row.addArrangedSubview(button)
        }
        return row
    }

    private func makeKeyRow(_ keys: [String]) -> UIStackView {
        let row = horizontalRow()
        keys.forEach { key in
            let button = makeButton(displayTitle(for: key), weight: .regular)
            button.accessibilityIdentifier = key
            switch key {
            case "delete":
                button.addTarget(self, action: #selector(deleteBackward), for: .touchUpInside)
            case "shift":
                button.addTarget(self, action: #selector(toggleShift), for: .touchUpInside)
            case "#+=":
                button.addTarget(self, action: #selector(toggleNumbers), for: .touchUpInside)
            default:
                button.addTarget(self, action: #selector(insertKey(_:)), for: .touchUpInside)
            }
            row.addArrangedSubview(button)
        }
        return row
    }

    private func makeBottomRow() -> UIStackView {
        let row = horizontalRow()

        let numbers = makeButton(keyboardMode == .numbers ? "ABC" : "123", weight: .regular)
        numbers.addTarget(self, action: #selector(toggleNumbers), for: .touchUpInside)

        let dictation = makeButton("Diktat", weight: .regular)
        dictation.addTarget(self, action: #selector(openDictationKeyboard), for: .touchUpInside)

        let space = makeButton("Leerzeichen", weight: .regular)
        space.addTarget(self, action: #selector(insertSpace), for: .touchUpInside)

        let returnKey = makeButton("Return", weight: .regular)
        returnKey.addTarget(self, action: #selector(insertReturn), for: .touchUpInside)

        row.addArrangedSubview(numbers)
        row.addArrangedSubview(dictation)
        row.addArrangedSubview(space)
        row.addArrangedSubview(returnKey)
        numbers.widthAnchor.constraint(equalToConstant: 54).isActive = true
        dictation.widthAnchor.constraint(equalToConstant: 70).isActive = true
        returnKey.widthAnchor.constraint(equalToConstant: 72).isActive = true
        return row
    }

    private func makeToolsBottomRow() -> UIStackView {
        let row = horizontalRow()

        let abc = makeButton("ABC", weight: .semibold)
        abc.addTarget(self, action: #selector(showLetters), for: .touchUpInside)

        let lang = makeButton(language == .german ? "Deutsch" : "English", weight: .regular)
        lang.addTarget(self, action: #selector(toggleLanguage), for: .touchUpInside)

        let tone = makeButton(formality == .formal ? "Sie-Form" : "Du-Form", weight: .regular)
        tone.addTarget(self, action: #selector(toggleFormality), for: .touchUpInside)

        let delete = makeButton("⌫", weight: .regular)
        delete.addTarget(self, action: #selector(deleteBackward), for: .touchUpInside)

        row.addArrangedSubview(abc)
        row.addArrangedSubview(lang)
        row.addArrangedSubview(tone)
        row.addArrangedSubview(delete)
        return row
    }

    private func horizontalRow() -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 5
        row.distribution = .fillEqually
        return row
    }

    private func makeButton(_ title: String, weight: UIFont.Weight) -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.baseBackgroundColor = UIColor.white
        configuration.baseForegroundColor = UIColor.label
        configuration.cornerStyle = .medium
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 4, bottom: 6, trailing: 4)

        let button = UIButton(configuration: configuration)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: weight)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.68
        button.titleLabel?.lineBreakMode = .byClipping
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.06
        button.layer.shadowRadius = 1
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 34).isActive = true
        return button
    }

    private func displayTitle(for key: String) -> String {
        switch key {
        case "delete": return "⌫"
        case "shift": return isShifted ? "⇧" : "⇧"
        case "space": return "Leerzeichen"
        default:
            guard keyboardMode == .letters else { return key }
            return isShifted ? key.uppercased() : key
        }
    }

    private func insertText(_ text: String) {
        textDocumentProxy.insertText(text)
    }

    private func currentContext() -> String {
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        let after = textDocumentProxy.documentContextAfterInput ?? ""
        let combined = (before + " " + after).trimmingCharacters(in: .whitespacesAndNewlines)
        if combined.count <= 220 { return combined }
        return String(combined.suffix(220))
    }

    private func makeDraft(kind: DraftKind) -> String {
        let context = currentContext()
        let topic = context.isEmpty ? defaultTopic(for: kind) : context

        switch language {
        case .german:
            return makeGermanDraft(kind: kind, topic: topic)
        case .english:
            return makeEnglishDraft(kind: kind, topic: topic)
        }
    }

    private func makeGermanDraft(kind: DraftKind, topic: String) -> String {
        let formal = shouldUseFormalTone(for: kind)
        let greeting = formal ? "Guten Tag," : "Hallo,"
        let signoff = formal ? "Beste Gruesse\n\(profile.fullName)" : "Liebe Gruesse\n\(profile.casualSender)"

        let body: String
        switch kind {
        case .reply:
            body = formal
                ? "vielen Dank fuer Ihre Nachricht. Ich habe die Punkte aufgenommen und melde mich gerne mit einem klaren Vorschlag dazu.\n\nZum aktuellen Stand: \(topic)"
                : "danke dir fuer die Nachricht. Ich habe die Punkte aufgenommen und melde mich gerne mit einem klaren Vorschlag dazu.\n\nZum aktuellen Stand: \(topic)"
        case .newMail:
            body = "ich melde mich wegen \(topic). Die wichtigsten Punkte habe ich unten kompakt zusammengefasst."
        case .event:
            body = formal
                ? "gerne bereite ich einen Termin dazu vor. Senden Sie mir bitte zwei bis drei passende Zeitfenster, dann koordiniere ich den naechsten Schritt."
                : "gerne bereite ich einen Termin dazu vor. Schick mir bitte zwei bis drei passende Zeitfenster, dann koordiniere ich den naechsten Schritt."
        case .short:
            body = formal
                ? "vielen Dank, das passt grundsaetzlich. Bitte senden Sie mir noch die fehlenden Eckdaten, dann kann ich es final einschaetzen."
                : "danke dir, das passt grundsaetzlich. Schick mir bitte noch die fehlenden Eckdaten, dann kann ich es final einschaetzen."
        case .friendly:
            body = formal
                ? "vielen Dank fuer Ihre Nachricht. Das klingt grundsaetzlich spannend, ich wuerde die Details gerne sauber abstimmen und danach den passenden Vorschlag schicken."
                : "danke dir fuer die Nachricht. Das klingt grundsaetzlich spannend, ich wuerde die Details gerne sauber abstimmen und danach den passenden Vorschlag schicken."
        case .professional:
            body = "vielen Dank fuer Ihre Nachricht. Ich pruefe die Details gerne strukturiert und melde mich mit einer verbindlichen Rueckmeldung zu Scope, Timing und naechsten Schritten."
        case .briefing:
            body = "vielen Dank fuer die Anfrage. Grundsaetzlich klingt die Kooperation interessant. Fuer eine konkrete Einschaetzung brauche ich bitte noch:\n\n\(briefingList(limit: 7))"
        case .pricing:
            body = "zum Budget kann ich eine serioese Einschaetzung geben, sobald der Scope klar ist. Relevant sind vor allem:\n\n\(briefingList(limit: 6))\n\n\(profile.rateCardNote)\n\n\(profile.usageRightsPolicy)"
        case .followUp:
            body = formal
                ? "ich wollte wegen der Anfrage kurz nachfragen. Wenn die Kooperation weiterhin relevant ist, senden Sie mir gerne noch die fehlenden Details:\n\n\(briefingList(limit: 5))"
                : "ich wollte wegen der Anfrage kurz nachfragen. Wenn die Kooperation weiterhin relevant ist, schick mir gerne noch die fehlenden Details:\n\n\(briefingList(limit: 5))"
        case .mediaKit:
            body = mediaKitBody(formal: formal)
        case .decline:
            body = formal
                ? "vielen Dank fuer die Anfrage und das Interesse. Aktuell passt die Kooperation leider nicht sauber zu Profil, Timing oder Rahmenbedingungen. Ich wuensche Ihnen dennoch viel Erfolg bei der Umsetzung."
                : "danke dir fuer die Anfrage und das Interesse. Aktuell passt die Kooperation leider nicht sauber zu Profil, Timing oder Rahmenbedingungen. Ich wuensche euch dennoch viel Erfolg bei der Umsetzung."
        case .invoice:
            body = formal
                ? "fuer die weitere Abwicklung sende ich Ihnen gerne die Rechnungsdaten bzw. benoetigten Informationen. Bitte lassen Sie mich wissen, welche Angaben auf Ihrer Seite erforderlich sind."
                : "fuer die weitere Abwicklung schicke ich dir gerne die Rechnungsdaten bzw. benoetigten Informationen. Sag mir bitte kurz, welche Angaben ihr dafuer braucht."
        }

        return "\(greeting)\n\n\(body)\n\n\(signoff)"
    }

    private func makeEnglishDraft(kind: DraftKind, topic: String) -> String {
        let formal = shouldUseFormalTone(for: kind)
        let greeting = formal ? "Hello," : "Hi,"
        let signoff = formal ? "Best regards\n\(profile.fullName)" : "Best\n\(profile.casualSender)"

        let body: String
        switch kind {
        case .reply:
            body = "thank you for your message. I have noted the key points and will gladly come back with a clear next step.\n\nCurrent context: \(topic)"
        case .newMail:
            body = "I am reaching out regarding \(topic). I have summarized the key points below."
        case .event:
            body = "I am happy to prepare a meeting. Please send me two or three suitable time slots and I will coordinate the next step."
        case .short:
            body = "thank you, this generally works. Please send over the remaining key details so I can assess it properly."
        case .friendly:
            body = "thank you for your message. This sounds interesting, and I would be happy to align on the details before sending a clear proposal."
        case .professional:
            body = "thank you for your message. I will review the details carefully and come back with a structured response regarding scope, timing and next steps."
        case .briefing:
            body = "thank you for the request. The collaboration sounds interesting. To assess it properly, I would need:\n\n\(briefingList(limit: 7))"
        case .pricing:
            body = "I can give a reliable budget estimate once the scope is clear. The key points are:\n\n\(briefingList(limit: 6))\n\n\(profile.rateCardNote)\n\n\(profile.usageRightsPolicy)"
        case .followUp:
            body = "I wanted to follow up on the request. If the collaboration is still relevant, please send me the missing details:\n\n\(briefingList(limit: 5))"
        case .mediaKit:
            body = mediaKitBody(formal: formal)
        case .decline:
            body = "thank you for the request and your interest. At the moment, the collaboration is not the right fit in terms of profile, timing or conditions. I still wish you every success with the campaign."
        case .invoice:
            body = "for the next step, I am happy to send the billing details or any required information. Please let me know which details you need on your side."
        }

        return "\(greeting)\n\n\(body)\n\n\(signoff)"
    }

    private func defaultTopic(for kind: DraftKind) -> String {
        switch kind {
        case .event:
            return language == .german ? "den Termin" : "the meeting"
        case .newMail:
            return language == .german ? "die Anfrage" : "the request"
        default:
            return language == .german ? "die Nachricht" : "the message"
        }
    }

    private func shouldUseFormalTone(for kind: DraftKind) -> Bool {
        if kind == .professional { return true }
        return formality == .formal
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

        if language == .english {
            return "here are the key details for a potential collaboration:\n\n\(linkBlock)\n\nServices:\n\(serviceBlock)\n\nFor a concrete proposal, I would need the briefing, deliverables, timing, budget and usage rights."
        }

        if formal {
            return "hier finden Sie die wichtigsten Infos fuer eine moegliche Zusammenarbeit:\n\n\(linkBlock)\n\nLeistungen:\n\(serviceBlock)\n\nFuer ein konkretes Angebot brauche ich bitte Briefing, Deliverables, Timing, Budget und Nutzungsrechte."
        }
        return "hier findest du die wichtigsten Infos fuer eine moegliche Zusammenarbeit:\n\n\(linkBlock)\n\nLeistungen:\n\(serviceBlock)\n\nFuer ein konkretes Angebot brauche ich bitte Briefing, Deliverables, Timing, Budget und Nutzungsrechte."
    }

    @objc private func nextKeyboard() {
        advanceToNextInputMode()
    }

    @objc private func openDictationKeyboard() {
        advanceToNextInputMode()
    }

    @objc private func toggleTools() {
        keyboardMode = keyboardMode == .tools ? .letters : .tools
        rebuildKeyboard()
    }

    @objc private func showLetters() {
        keyboardMode = .letters
        rebuildKeyboard()
    }

    @objc private func toggleNumbers() {
        keyboardMode = keyboardMode == .numbers ? .letters : .numbers
        rebuildKeyboard()
    }

    @objc private func toggleLanguage() {
        language.toggle()
        rebuildKeyboard()
    }

    @objc private func toggleFormality() {
        formality.toggle()
        rebuildKeyboard()
    }

    @objc private func toggleShift() {
        isShifted.toggle()
        rebuildKeyboard()
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

    @objc private func insertThreeDrafts() {
        let drafts = [
            "1.\n\(makeDraft(kind: .short))",
            "2.\n\(makeDraft(kind: .friendly))",
            "3.\n\(makeDraft(kind: .professional))"
        ]
        insertText(drafts.joined(separator: "\n\n---\n\n"))
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

    @objc private func insertDeclineDraft() {
        insertText(makeDraft(kind: .decline))
    }

    @objc private func insertInvoiceDraft() {
        insertText(makeDraft(kind: .invoice))
    }

    @objc private func insertSignature() {
        if language == .english {
            insertText("Best regards\n\(profile.fullName)")
        } else if formality == .formal {
            insertText("Beste Gruesse\n\(profile.fullName)")
        } else {
            insertText("Liebe Gruesse\n\(profile.casualSender)")
        }
    }

    @objc private func insertKey(_ sender: UIButton) {
        guard let key = sender.accessibilityIdentifier else { return }
        let text = displayTitle(for: key)
        insertText(text)
        if keyboardMode == .letters && isShifted {
            isShifted = false
            rebuildKeyboard()
        }
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
    case decline
    case invoice
}
