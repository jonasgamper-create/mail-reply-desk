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
    private let maximumNoteReplacementLength = 520

    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboard()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        profile = loadProfileForKeyboard()
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

    private func loadProfileForKeyboard() -> UserProfile {
        if hasFullAccess,
           let copied = UIPasteboard.general.string,
           let pastedProfile = ProfileStore.decodeProfile(from: copied) {
            ProfileStore.saveProfile(pastedProfile)
            return pastedProfile
        }
        return ProfileStore.loadProfile()
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
                ("Koop", #selector(insertCollaborationDraft)),
                ("Termin", #selector(insertEventDraft)),
                ("Mail", #selector(insertNewMailDraft))
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

    private func currentContext(maxLength: Int = 720) -> String {
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        let after = textDocumentProxy.documentContextAfterInput ?? ""
        let combined = (before + " " + after).trimmingCharacters(in: .whitespacesAndNewlines)
        if combined.count <= maxLength { return combined }
        return String(combined.suffix(maxLength))
    }

    private func makeDraft(kind: DraftKind, contextOverride: String? = nil) -> String {
        let context = contextOverride?.trimmingCharacters(in: .whitespacesAndNewlines) ?? currentContext()
        let topic = context.isEmpty ? defaultTopic(for: kind) : context

        switch language {
        case .german:
            return makeGermanDraft(kind: kind, topic: topic)
        case .english:
            return makeEnglishDraft(kind: kind, topic: topic)
        }
    }

    private func makeGermanDraft(kind: DraftKind, topic: String) -> String {
        let formal = shouldUseFormalTone(for: kind, topic: topic)
        let greeting = formal ? "Guten Tag," : "Hallo,"
        let signoff = formal ? "Beste Gruesse\n\(senderName(formal: true))" : "Liebe Gruesse\n\(senderName(formal: false))"
        let focus = focusLine(topic: topic, formal: formal)

        let body: String
        switch kind {
        case .reply:
            body = replyBodyGerman(topic: topic, formal: formal)
        case .newMail:
            body = formal
                ? "ich melde mich wegen \(cleanTopic(topic)). Die wichtigsten Punkte habe ich kompakt zusammengefasst.\n\n\(focus)"
                : "ich melde mich wegen \(cleanTopic(topic)). Die wichtigsten Punkte habe ich kompakt zusammengefasst.\n\n\(focus)"
        case .collaboration:
            body = collaborationBodyGerman(topic: topic, formal: formal)
        case .event:
            body = formal
                ? "gerne bereite ich einen Termin dazu vor.\n\n\(focus)\n\nBitte senden Sie mir zwei bis drei passende Zeitfenster. Alternativ schlage ich gerne einen 30-minuetigen Call vor, sobald Timing und Ziel klar sind."
                : "gerne bereite ich einen Termin dazu vor.\n\n\(focus)\n\nSchick mir bitte zwei bis drei passende Zeitfenster. Alternativ schlage ich gerne einen 30-minuetigen Call vor, sobald Timing und Ziel klar sind."
        case .short:
            body = formal
                ? "vielen Dank, das klingt grundsaetzlich passend. Bitte senden Sie mir noch Scope, Timing, Budgetrahmen und Nutzungsrechte, dann gebe ich Ihnen eine konkrete Rueckmeldung."
                : "danke dir, das klingt grundsaetzlich passend. Schick mir bitte noch Scope, Timing, Budgetrahmen und Nutzungsrechte, dann gebe ich dir eine konkrete Rueckmeldung."
        case .friendly:
            body = formal
                ? "vielen Dank fuer Ihre Nachricht. Das klingt spannend und ich freue mich ueber die Anfrage.\n\n\(focus)\n\nIch wuerde die Details gerne sauber abstimmen und danach einen passenden Vorschlag schicken."
                : "danke dir fuer die Nachricht. Das klingt spannend und ich freue mich ueber die Anfrage.\n\n\(focus)\n\nIch wuerde die Details gerne sauber abstimmen und danach einen passenden Vorschlag schicken."
        case .professional:
            body = "vielen Dank fuer Ihre Nachricht. Damit ich die Anfrage belastbar einschaetzen kann, brauche ich bitte die finalen Eckdaten zu Scope, Timing, Deliverables, Budgetrahmen und Nutzungsrechten.\n\n\(focus)\n\nSobald diese Punkte klar sind, melde ich mich mit einer strukturierten Rueckmeldung und einem konkreten naechsten Schritt."
        case .briefing:
            body = "vielen Dank fuer die Anfrage. Grundsaetzlich klingt die Kooperation interessant. Fuer eine konkrete Einschaetzung brauche ich bitte noch:\n\n\(briefingList(limit: 7))"
        case .pricing:
            body = pricingBodyGerman(formal: formal)
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
        let formal = shouldUseFormalTone(for: kind, topic: topic)
        let greeting = formal ? "Hello," : "Hi,"
        let signoff = formal ? "Best regards\n\(senderName(formal: true))" : "Best\n\(senderName(formal: false))"
        let focus = focusLine(topic: topic, formal: formal)

        let body: String
        switch kind {
        case .reply:
            body = "thank you for your message. I have noted the key points and would like to align the next step properly.\n\n\(focus)\n\nPlease send me any missing details regarding scope, timing, budget and usage rights so I can come back with a clear recommendation."
        case .newMail:
            body = "I am reaching out regarding \(cleanTopic(topic)). I have summarized the key points below.\n\n\(focus)"
        case .collaboration:
            body = "thank you for the request. The collaboration sounds interesting and could be a good fit for \(cleanTopic(profile.niche)).\n\n\(focus)\n\nTo assess it properly, I would need the briefing, deliverables, timing, budget range, usage rights, exclusivity and approval process."
        case .event:
            body = "I am happy to prepare a meeting.\n\n\(focus)\n\nPlease send me two or three suitable time slots. Alternatively, I can suggest a 30-minute call once the goal and timing are clear."
        case .short:
            body = "thank you, this generally sounds suitable. Please send over the scope, timing, budget range and usage rights so I can give you a concrete response."
        case .friendly:
            body = "thank you for your message. This sounds interesting and I appreciate the request.\n\n\(focus)\n\nI would be happy to align on the details before sending a clear proposal."
        case .professional:
            body = "thank you for your message. To assess the request properly, I would need the final details regarding scope, timing, deliverables, budget range and usage rights.\n\n\(focus)\n\nOnce these points are clear, I will come back with a structured response and a concrete next step."
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
        case .collaboration:
            return language == .german ? "die Kooperation" : "the collaboration"
        case .newMail:
            return language == .german ? "die Anfrage" : "the request"
        default:
            return language == .german ? "die Nachricht" : "the message"
        }
    }

    private func shouldUseFormalTone(for kind: DraftKind, topic: String) -> Bool {
        if kind == .professional { return true }
        let lower = normalized(topic)
        let formalMarkers = [" sie ", " ihnen ", " ihr ", " ihre ", " frau ", " herr ", " sehr geehrte", " guten tag"]
        let casualMarkers = [" du ", " dir ", "dich", "euch", "hallo linda", "hi linda", "liebe linda"]
        if formalMarkers.contains(where: { lower.contains($0) }) { return true }
        if casualMarkers.contains(where: { lower.contains($0) }) { return false }
        return formality == .formal
    }

    private func senderName(formal: Bool) -> String {
        let preferred = formal ? profile.formalSender : profile.casualSender
        let trimmed = preferred.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        let fullName = profile.fullName
        return fullName.isEmpty ? profile.appName : fullName
    }

    private func normalized(_ text: String) -> String {
        " \(text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current).lowercased()) "
    }

    private func cleanTopic(_ topic: String, maxLength: Int = 360) -> String {
        let cleaned = topic
            .replacingOccurrences(of: "\n", with: "; ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.count <= maxLength { return cleaned }
        return String(cleaned.prefix(maxLength)).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
    }

    private func focusLine(topic: String, formal: Bool) -> String {
        let topic = cleanTopic(topic)
        let fallback = language == .german ? "die Anfrage" : "the request"
        guard !topic.isEmpty, topic != fallback else {
            return language == .german ? "Wichtig sind fuer mich die Eckdaten, der genaue Scope und der naechste Schritt." : "The key points for me are the details, the exact scope and the next step."
        }
        if language == .english {
            return "Current context: \(topic)"
        }
        return formal ? "Aktueller Kontext: \(topic)" : "Ich habe mir notiert: \(topic)"
    }

    private func replyBodyGerman(topic: String, formal: Bool) -> String {
        let lower = normalized(topic)
        if lower.contains("preis") || lower.contains("budget") || lower.contains("honorar") || lower.contains("rate") {
            return pricingBodyGerman(formal: formal)
        }
        if lower.contains("kooperation") || lower.contains("collab") || lower.contains("kampagne") || lower.contains("brand") || lower.contains("ugc") {
            return collaborationBodyGerman(topic: topic, formal: formal)
        }
        if lower.contains("termin") || lower.contains("call") || lower.contains("meeting") || lower.contains("kalender") {
            return formal
                ? "vielen Dank fuer Ihre Nachricht. Gerne bereite ich den Termin vor.\n\n\(focusLine(topic: topic, formal: formal))\n\nBitte senden Sie mir zwei bis drei passende Zeitfenster, dann koordiniere ich den naechsten Schritt."
                : "danke dir fuer die Nachricht. Gerne bereite ich den Termin vor.\n\n\(focusLine(topic: topic, formal: formal))\n\nSchick mir bitte zwei bis drei passende Zeitfenster, dann koordiniere ich den naechsten Schritt."
        }
        return formal
            ? "vielen Dank fuer Ihre Nachricht. Ich habe die Punkte aufgenommen und wuerde den naechsten Schritt gerne sauber abstimmen.\n\n\(focusLine(topic: topic, formal: formal))\n\nBitte senden Sie mir noch die fehlenden Eckdaten, falls etwas offen ist. Danach kann ich Ihnen eine konkrete Rueckmeldung geben."
            : "danke dir fuer die Nachricht. Ich habe die Punkte aufgenommen und wuerde den naechsten Schritt gerne sauber abstimmen.\n\n\(focusLine(topic: topic, formal: formal))\n\nSchick mir gerne noch die fehlenden Eckdaten, falls etwas offen ist. Danach kann ich dir eine konkrete Rueckmeldung geben."
    }

    private func collaborationBodyGerman(topic: String, formal: Bool) -> String {
        let intro = formal
            ? "vielen Dank fuer die Anfrage. Die Kooperation klingt grundsaetzlich interessant und passt potenziell zu \(cleanTopic(profile.niche))."
            : "danke dir fuer die Anfrage. Die Kooperation klingt grundsaetzlich interessant und passt potenziell zu \(cleanTopic(profile.niche))."
        let ask = formal
            ? "Fuer eine serioese Einschaetzung senden Sie mir bitte noch die wichtigsten Eckdaten:"
            : "Fuer eine serioese Einschaetzung schick mir bitte noch die wichtigsten Eckdaten:"
        return "\(intro)\n\n\(focusLine(topic: topic, formal: formal))\n\n\(ask)\n\n\(briefingList(limit: 7))\n\nWichtig: \(profile.usageRightsPolicy)"
    }

    private func pricingBodyGerman(formal: Bool) -> String {
        let ask = formal
            ? "zum Budget kann ich eine serioese Einschaetzung geben, sobald der Scope klar ist. Relevant sind vor allem:"
            : "zum Budget kann ich eine serioese Einschaetzung geben, sobald der Scope klar ist. Relevant sind vor allem:"
        return "\(ask)\n\n\(briefingList(limit: 6))\n\n\(profile.rateCardNote)\n\n\(profile.usageRightsPolicy)"
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
        insertDraftReplacingNotesIfUseful(kind: .reply)
    }

    @objc private func insertNewMailDraft() {
        insertDraftReplacingNotesIfUseful(kind: .newMail)
    }

    @objc private func insertCollaborationDraft() {
        insertDraftReplacingNotesIfUseful(kind: .collaboration)
    }

    @objc private func insertEventDraft() {
        insertDraftReplacingNotesIfUseful(kind: .event)
    }

    @objc private func insertThreeDrafts() {
        let rawNotes = notesBeforeInputForReplacement()
        let context = rawNotes?.trimmingCharacters(in: .whitespacesAndNewlines)
        let drafts = [
            "1. Kurz\n\(makeDraft(kind: .short, contextOverride: context))",
            "2. Freundlich\n\(makeDraft(kind: .friendly, contextOverride: context))",
            "3. Professionell\n\(makeDraft(kind: .professional, contextOverride: context))"
        ]
        deleteNotesIfNeeded(rawNotes)
        insertText(drafts.joined(separator: "\n\n---\n\n"))
    }

    @objc private func insertShortDraft() {
        insertDraftReplacingNotesIfUseful(kind: .short)
    }

    @objc private func insertFriendlyDraft() {
        insertDraftReplacingNotesIfUseful(kind: .friendly)
    }

    @objc private func insertProfessionalDraft() {
        insertDraftReplacingNotesIfUseful(kind: .professional)
    }

    @objc private func insertBriefingDraft() {
        insertDraftReplacingNotesIfUseful(kind: .briefing)
    }

    @objc private func insertPricingDraft() {
        insertDraftReplacingNotesIfUseful(kind: .pricing)
    }

    @objc private func insertFollowUpDraft() {
        insertDraftReplacingNotesIfUseful(kind: .followUp)
    }

    @objc private func insertMediaKitDraft() {
        insertDraftReplacingNotesIfUseful(kind: .mediaKit)
    }

    @objc private func insertDeclineDraft() {
        insertDraftReplacingNotesIfUseful(kind: .decline)
    }

    @objc private func insertInvoiceDraft() {
        insertDraftReplacingNotesIfUseful(kind: .invoice)
    }

    @objc private func insertSignature() {
        if language == .english {
            insertText("Best regards\n\(senderName(formal: true))")
        } else if formality == .formal {
            insertText("Beste Gruesse\n\(senderName(formal: true))")
        } else {
            insertText("Liebe Gruesse\n\(senderName(formal: false))")
        }
    }

    private func insertDraftReplacingNotesIfUseful(kind: DraftKind) {
        let rawNotes = notesBeforeInputForReplacement()
        let context = rawNotes?.trimmingCharacters(in: .whitespacesAndNewlines)
        let draft = makeDraft(kind: kind, contextOverride: context)
        deleteNotesIfNeeded(rawNotes)
        insertText(draft)
    }

    private func notesBeforeInputForReplacement() -> String? {
        guard (textDocumentProxy.documentContextAfterInput ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        guard let before = textDocumentProxy.documentContextBeforeInput, !before.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        let trimmed = before.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count <= maximumNoteReplacementLength else { return nil }

        let lower = normalized(trimmed)
        let protectedMailMarkers = [
            "guten tag,", "hallo,", "liebe gruesse", "liebe grusse", "beste gruesse",
            "mit freundlichen gruessen", "best regards", "kind regards", "sent from"
        ]
        if protectedMailMarkers.contains(where: { lower.contains($0) }) {
            return nil
        }
        return before
    }

    private func deleteNotesIfNeeded(_ notes: String?) {
        guard let notes else { return }
        for _ in notes {
            textDocumentProxy.deleteBackward()
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
    case collaboration
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
