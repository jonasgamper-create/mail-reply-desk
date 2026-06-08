import UIKit

final class KeyboardViewController: UIInputViewController {
    private enum KeyboardMode {
        case letters
        case numbers
        case tools
    }

    private enum ButtonRole {
        case key
        case system
        case action
        case primaryAction
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

    private enum ConversationMode: String {
        case auto
        case privateChat
        case work

        private static let storageKey = "mailReplyDesk.keyboard.conversationMode"

        static func load() -> ConversationMode {
            guard let raw = UserDefaults.standard.string(forKey: storageKey) else { return .auto }
            return ConversationMode(rawValue: raw) ?? .auto
        }

        mutating func toggle() {
            switch self {
            case .auto:
                self = .privateChat
            case .privateChat:
                self = .work
            case .work:
                self = .auto
            }
        }

        func save() {
            UserDefaults.standard.set(rawValue, forKey: Self.storageKey)
            UserDefaults.standard.synchronize()
        }

        var shortTitle: String {
            switch self {
            case .auto: return "Auto"
            case .privateChat: return "Privat"
            case .work: return "Arbeit"
            }
        }
    }

    private var profile = ProfileStore.loadProfile()
    private var keyboardMode: KeyboardMode = .letters
    private var language: OutputLanguage = .german
    private var formality: Formality = .formal
    private var conversationMode: ConversationMode = .load()
    private var isShifted = false
    private let rootStack = UIStackView()
    private var heightConstraint: NSLayoutConstraint?
    private let maximumNoteReplacementLength = 520
    private let maximumClipboardContextLength = 1600
    private let learningPrefix = "mailReplyDesk.learning.kind."
    private let lastDraftLengthKey = "mailReplyDesk.keyboard.lastDraft.length"
    private let lastDraftSuffixKey = "mailReplyDesk.keyboard.lastDraft.suffix"
    private let lastDraftSourceContextKey = "mailReplyDesk.keyboard.lastDraft.sourceContext"
    private let lastDraftSuffixLength = 48

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
            let constraint = view.heightAnchor.constraint(equalToConstant: 286)
            constraint.priority = UILayoutPriority(999)
            constraint.isActive = true
            heightConstraint = constraint
        }
    }

    private func setupKeyboard() {
        view.backgroundColor = UIColor.systemGray6
        rootStack.axis = .vertical
        rootStack.spacing = 4
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootStack)

        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            rootStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -6),
            rootStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 6),
            rootStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -6)
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
            makeAdaptiveToolRows().forEach { rootStack.addArrangedSubview($0) }
            rootStack.addArrangedSubview(makeToolsBottomRow())
        }
    }

    private func makeAdaptiveToolRows() -> [UIStackView] {
        let mode = effectiveConversationMode(for: bestAvailableContextForMode())
        if mode == .privateChat {
            return [
                makeToolRow([
                    ("Antwort", #selector(insertReplyDraft)),
                    ("Ja", #selector(insertApproveDraft)),
                    ("Nein", #selector(insertDeclineDraft)),
                    ("Danke", #selector(insertThanksDraft))
                ]),
                makeToolRow([
                    ("Kurz", #selector(insertShortDraft)),
                    ("Warm", #selector(insertFriendlyDraft)),
                    ("Klar", #selector(insertProfessionalDraft)),
                    ("Sorry", #selector(insertSorryDraft))
                ]),
                makeToolRow([
                    ("Treffen", #selector(insertPrivateMeetingDraft)),
                    ("Später", #selector(insertLaterDraft)),
                    ("Übersetz.", #selector(insertTranslatedReplyDraft)),
                    ("Check", #selector(insertAnalysisDraft))
                ]),
                makeToolRow([
                    ("Diktat", #selector(openDictationKeyboard)),
                    ("ABC", #selector(showLetters)),
                    ("⌫", #selector(deleteBackward))
                ])
            ]
        }

        return [
            makeToolRow([
                ("Antwort", #selector(insertReplyDraft)),
                ("Termin", #selector(insertEventDraft)),
                ("Preis", #selector(insertPricingDraft)),
                ("Koop", #selector(insertCollaborationDraft))
            ]),
            makeToolRow([
                ("3x", #selector(insertThreeDrafts)),
                ("Check", #selector(insertAnalysisDraft)),
                ("Freundl.", #selector(insertFriendlyDraft)),
                ("Profi", #selector(insertProfessionalDraft))
            ]),
            makeToolRow([
                ("Briefing", #selector(insertBriefingDraft)),
                ("Follow-up", #selector(insertFollowUpDraft)),
                ("Rechnung", #selector(insertInvoiceDraft)),
                ("MediaKit", #selector(insertMediaKitDraft))
            ]),
            makeToolRow([
                ("Mail", #selector(insertNewMailDraft)),
                ("Kürzer", #selector(insertShortDraft)),
                ("Übersetz.", #selector(insertTranslatedReplyDraft)),
                ("Signatur", #selector(insertSignature))
            ])
        ]
    }

    private func makeHeaderRow() -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 5
        row.alignment = .fill
        row.distribution = .fill

        let contextMode = makeContextMenuButton()
        contextMode.widthAnchor.constraint(equalToConstant: 78).isActive = true

        let lang = makeLanguageMenuButton()
        lang.widthAnchor.constraint(equalToConstant: 48).isActive = true

        let tone = makeFormalityMenuButton()
        tone.widthAnchor.constraint(equalToConstant: 50).isActive = true

        let statusChip = makeStatusChip()

        let next = makeButton("⌨", weight: .regular, role: .system)
        next.addTarget(self, action: #selector(nextKeyboard), for: .touchUpInside)
        next.accessibilityLabel = "Nächste Tastatur"
        next.widthAnchor.constraint(equalToConstant: 42).isActive = true

        row.addArrangedSubview(contextMode)
        row.addArrangedSubview(lang)
        row.addArrangedSubview(tone)
        row.addArrangedSubview(statusChip)
        row.addArrangedSubview(next)
        return row
    }

    private func makeQuickReplyRow() -> UIStackView {
        let row = horizontalRow()

        let smart = makeButton("↩", weight: .semibold, role: .primaryAction)
        smart.addTarget(self, action: #selector(insertReplyDraft), for: .touchUpInside)
        smart.accessibilityLabel = "Intelligente Antwort"

        let approve = makeButton("✓", weight: .semibold, role: .action)
        approve.addTarget(self, action: #selector(insertApproveDraft), for: .touchUpInside)
        approve.accessibilityLabel = "Zusage erstellen"

        let decline = makeButton("✕", weight: .semibold, role: .action)
        decline.addTarget(self, action: #selector(insertDeclineDraft), for: .touchUpInside)
        decline.accessibilityLabel = "Absage erstellen"

        let style = makeStyleMenuButton()
        let more = makeMoreMenuButton()

        [smart, approve, decline, style, more].forEach { row.addArrangedSubview($0) }
        return row
    }

    private func makeToolRow(_ items: [(String, Selector)]) -> UIStackView {
        let row = horizontalRow()
        items.forEach { title, selector in
            let button = makeButton(title, weight: .medium, role: .action)
            if title == "3x" {
                button.accessibilityLabel = "Antwortvorlage wählen"
                button.showsMenuAsPrimaryAction = true
                button.menu = makeDraftVariantMenu()
                button.configuration?.baseBackgroundColor = UIColor.systemBlue
                button.configuration?.baseForegroundColor = UIColor.white
                row.addArrangedSubview(button)
                return
            }
            if ["Antwort", "Ja", "Nein", "Koop", "Termin", "Mail", "Danke", "Treffen", "Preis"].contains(title) {
                button.configuration?.baseBackgroundColor = UIColor.systemBlue
                button.configuration?.baseForegroundColor = UIColor.white
            }
            if title == "Nein" {
                button.configuration?.baseBackgroundColor = UIColor.systemGray
                button.configuration?.baseForegroundColor = UIColor.white
            } else if ["Warm", "Freundl."].contains(title) {
                button.configuration?.baseBackgroundColor = UIColor.systemGreen
                button.configuration?.baseForegroundColor = UIColor.white
            } else if title == "Check" {
                button.configuration?.baseBackgroundColor = UIColor.systemTeal
                button.configuration?.baseForegroundColor = UIColor.white
            } else if ["Profi", "Klar"].contains(title) {
                button.configuration?.baseBackgroundColor = UIColor.systemIndigo
                button.configuration?.baseForegroundColor = UIColor.white
            } else if title == "Übersetz." {
                button.configuration?.baseBackgroundColor = UIColor.systemPurple
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
            let button = makeButton(displayTitle(for: key), weight: .regular, role: key == "delete" || key == "shift" || key == "#+=" ? .system : .key)
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

        let numbers = makeButton(keyboardMode == .numbers ? "ABC" : "123", weight: .regular, role: .system)
        numbers.addTarget(self, action: #selector(toggleNumbers), for: .touchUpInside)

        let dictation = makeButton("Dikt.", weight: .regular, role: .system)
        dictation.addTarget(self, action: #selector(openDictationKeyboard), for: .touchUpInside)
        dictation.accessibilityLabel = "Zur Apple-Tastatur für Diktat wechseln"

        let space = makeButton("Leerzeichen", weight: .regular, role: .key)
        space.addTarget(self, action: #selector(insertSpace), for: .touchUpInside)

        let returnKey = makeButton("Return", weight: .regular, role: .system)
        returnKey.addTarget(self, action: #selector(insertReturn), for: .touchUpInside)

        row.addArrangedSubview(numbers)
        row.addArrangedSubview(dictation)
        row.addArrangedSubview(space)
        row.addArrangedSubview(returnKey)
        numbers.widthAnchor.constraint(equalToConstant: 54).isActive = true
        dictation.widthAnchor.constraint(equalToConstant: 58).isActive = true
        returnKey.widthAnchor.constraint(equalToConstant: 72).isActive = true
        return row
    }

    private func makeToolsBottomRow() -> UIStackView {
        let row = horizontalRow()

        let abc = makeButton("ABC", weight: .semibold, role: .system)
        abc.addTarget(self, action: #selector(showLetters), for: .touchUpInside)

        let lang = makeButton(language == .german ? "Deutsch" : "English", weight: .regular, role: .system)
        lang.addTarget(self, action: #selector(toggleLanguage), for: .touchUpInside)

        let tone = makeButton(formality == .formal ? "Sie-Form" : "Du-Form", weight: .regular, role: .system)
        tone.addTarget(self, action: #selector(toggleFormality), for: .touchUpInside)

        let delete = makeButton("⌫", weight: .regular, role: .system)
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
        row.spacing = 4
        row.distribution = .fillEqually
        return row
    }

    private func makeButton(_ title: String, weight: UIFont.Weight, role: ButtonRole = .action) -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.cornerStyle = .small
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)

        switch role {
        case .key:
            configuration.baseBackgroundColor = UIColor.systemBackground
            configuration.baseForegroundColor = UIColor.label
        case .system:
            configuration.baseBackgroundColor = UIColor.systemGray5
            configuration.baseForegroundColor = UIColor.label
        case .action:
            configuration.baseBackgroundColor = UIColor.systemGray4
            configuration.baseForegroundColor = UIColor.label
        case .primaryAction:
            configuration.baseBackgroundColor = UIColor.systemBlue
            configuration.baseForegroundColor = UIColor.white
        }

        let button = UIButton(configuration: configuration)
        let fontSize: CGFloat
        switch role {
        case .key:
            fontSize = title.count == 1 ? 21 : 15
        case .system:
            fontSize = title.count <= 2 ? 17 : 13
        case .action, .primaryAction:
            fontSize = title.count <= 2 ? 18 : 13
        }
        button.titleLabel?.font = .systemFont(ofSize: fontSize, weight: weight)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.72
        button.titleLabel?.lineBreakMode = .byClipping
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = role == .key ? 0.12 : 0.04
        button.layer.shadowRadius = 1
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: role == .key ? 38 : 30).isActive = true
        return button
    }

    private func makeStatusChip() -> UIButton {
        let hasContext = storedContextIfUseful() != nil
        let title = hasContext ? "Kontext" : profile.initials
        let button = makeButton(title, weight: .semibold, role: .system)
        button.accessibilityLabel = hasContext ? "Kontext aktiv" : "Profil \(profile.fullName)"
        button.setContentHuggingPriority(.defaultLow, for: .horizontal)
        button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        if hasContext {
            button.configuration?.baseBackgroundColor = UIColor.systemGreen
            button.configuration?.baseForegroundColor = UIColor.white
            button.showsMenuAsPrimaryAction = true
            button.menu = UIMenu(title: "Kontext aktiv", children: [
                UIAction(title: "Check einfügen") { [weak self] _ in
                    self?.insertAnalysisDraft()
                },
                UIAction(title: "Kontext löschen", attributes: .destructive) { [weak self] _ in
                    MessageContextStore.clear()
                    self?.clearLastGeneratedDraft()
                    self?.rebuildKeyboard()
                }
            ])
        }

        return button
    }

    private func makeContextMenuButton() -> UIButton {
        let button = makeButton(conversationMode.shortTitle, weight: .semibold, role: .system)
        button.accessibilityLabel = "Kontextmodus"
        button.showsMenuAsPrimaryAction = true
        button.menu = UIMenu(title: "Kontext", children: [
            UIAction(title: "Auto", state: conversationMode == .auto ? .on : .off) { [weak self] _ in
                self?.setConversationMode(.auto)
            },
            UIAction(title: "Privat", state: conversationMode == .privateChat ? .on : .off) { [weak self] _ in
                self?.setConversationMode(.privateChat)
            },
            UIAction(title: "Arbeit", state: conversationMode == .work ? .on : .off) { [weak self] _ in
                self?.setConversationMode(.work)
            }
        ])
        return button
    }

    private func makeLanguageMenuButton() -> UIButton {
        let button = makeButton(language.shortTitle, weight: .semibold, role: .system)
        button.accessibilityLabel = "Sprache"
        button.showsMenuAsPrimaryAction = true
        button.menu = UIMenu(title: "Sprache", children: [
            UIAction(title: "Deutsch", state: language == .german ? .on : .off) { [weak self] _ in
                self?.setLanguage(.german)
            },
            UIAction(title: "English", state: language == .english ? .on : .off) { [weak self] _ in
                self?.setLanguage(.english)
            }
        ])
        return button
    }

    private func makeFormalityMenuButton() -> UIButton {
        let button = makeButton(formality.shortTitle, weight: .semibold, role: .system)
        button.accessibilityLabel = "Anrede"
        button.showsMenuAsPrimaryAction = true
        button.menu = UIMenu(title: "Anrede", children: [
            UIAction(title: "Du", state: formality == .casual ? .on : .off) { [weak self] _ in
                self?.setFormality(.casual)
            },
            UIAction(title: "Sie", state: formality == .formal ? .on : .off) { [weak self] _ in
                self?.setFormality(.formal)
            }
        ])
        return button
    }

    private func makeStyleMenuButton() -> UIButton {
        let button = makeButton("Aa", weight: .semibold, role: .action)
        button.accessibilityLabel = "Stil"
        button.showsMenuAsPrimaryAction = true
        button.menu = UIMenu(title: "Stil", children: [
            UIAction(title: "Kürzer") { [weak self] _ in self?.insertShortDraft() },
            UIAction(title: "Freundlicher") { [weak self] _ in self?.insertFriendlyDraft() },
            UIAction(title: "Professioneller") { [weak self] _ in self?.insertProfessionalDraft() },
            UIAction(title: "Übersetzen") { [weak self] _ in self?.insertTranslatedReplyDraft() }
        ])
        return button
    }

    private func makeMoreMenuButton() -> UIButton {
        let button = makeButton("...", weight: .semibold, role: .action)
        button.accessibilityLabel = "Weitere Aktionen"
        button.showsMenuAsPrimaryAction = true
        var actions: [UIMenuElement] = []
        if effectiveConversationMode(for: bestAvailableContextForMode()) != .privateChat {
            actions.append(makeDraftVariantMenu())
        }
        actions.append(contentsOf: [
            UIAction(title: "Analyse") { [weak self] _ in self?.insertAnalysisDraft() },
            UIAction(title: "Termin") { [weak self] _ in self?.insertEventDraft() },
            UIAction(title: "Preis/Budget") { [weak self] _ in self?.insertPricingDraft() },
            UIAction(title: "Kooperation") { [weak self] _ in self?.insertCollaborationDraft() },
            UIAction(title: "Briefing") { [weak self] _ in self?.insertBriefingDraft() },
            UIAction(title: "Follow-up") { [weak self] _ in self?.insertFollowUpDraft() },
            UIAction(title: "MediaKit") { [weak self] _ in self?.insertMediaKitDraft() },
            UIAction(title: "Signatur") { [weak self] _ in self?.insertSignature() }
        ])
        button.menu = UIMenu(title: "Aktionen", children: actions)
        return button
    }

    private func makeDraftVariantMenu() -> UIMenu {
        UIMenu(title: "Vorlage wählen", options: .displayInline, children: [
            UIAction(title: "Kurz") { [weak self] _ in self?.insertDraftVariant(.short) },
            UIAction(title: "Freundlich") { [weak self] _ in self?.insertDraftVariant(.friendly) },
            UIAction(title: "Professionell") { [weak self] _ in self?.insertDraftVariant(.professional) }
        ])
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

    private func bestAvailableContextForMode() -> String {
        let visible = currentContext()
        if let stored = storedContextIfUseful() {
            return "\(stored)\n\(visible)".trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return visible
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
        let mode = effectiveConversationMode(for: topic)
        let formal = shouldUseFormalTone(for: kind, topic: topic)
        let greeting = formal ? "Guten Tag," : "Hallo,"
        let signoff = formal ? "Beste Grüße\n\(senderName(formal: true))" : "Liebe Grüße\n\(senderName(formal: false))"
        let focus = focusLine(topic: topic, formal: formal)

        let body: String
        switch kind {
        case .reply:
            body = replyBodyGerman(topic: topic, formal: formal)
        case .approve:
            body = approveBodyGerman(topic: topic, formal: formal)
        case .newMail:
            body = formal
                ? "ich melde mich wegen \(cleanTopic(topic)).\n\n\(focus)"
                : "ich melde mich wegen \(cleanTopic(topic)).\n\n\(focus)"
        case .collaboration:
            body = collaborationBodyGerman(topic: topic, formal: formal)
        case .event:
            if mode == .privateChat {
                body = "Ja, das passt grundsätzlich. Sag mir bitte kurz, wann und wo es dir am besten passt, dann richte ich mich danach."
            } else {
                body = formal
                ? "gerne. Bitte senden Sie mir zwei bis drei passende Zeitfenster, dann koordiniere ich den Termin.\n\n\(focus)"
                : "gerne. Schick mir bitte zwei bis drei passende Zeitfenster, dann koordiniere ich den Termin.\n\n\(focus)"
            }
        case .short:
            if let notes = userKeywords(from: topic),
               let keywordBody = mode == .privateChat
                ? privateKeywordBodyGerman(notes: notes)
                : workKeywordBodyGerman(notes: notes, formal: formal) {
                body = keywordBody
            } else if mode == .privateChat {
                body = shortPrivateBodyGerman(topic: topic)
            } else {
                body = formal
                ? "vielen Dank. Bitte senden Sie mir noch Scope, Timing, Budgetrahmen und Nutzungsrechte. Danach gebe ich Ihnen eine konkrete Rückmeldung."
                : "danke dir. Schick mir bitte noch Scope, Timing, Budgetrahmen und Nutzungsrechte. Danach gebe ich dir eine konkrete Rückmeldung."
            }
        case .friendly:
            if let notes = userKeywords(from: topic),
               let keywordBody = mode == .privateChat
                ? privateKeywordBodyGerman(notes: notes)
                : workKeywordBodyGerman(notes: notes, formal: formal) {
                body = keywordBody
            } else if mode == .privateChat {
                body = friendlyPrivateBodyGerman(topic: topic)
            } else {
                body = formal
                ? "vielen Dank für Ihre Nachricht, das klingt interessant.\n\n\(focus)\n\nSenden Sie mir gerne noch die offenen Eckdaten, dann melde ich mich mit einem passenden Vorschlag."
                : "danke dir, das klingt interessant.\n\n\(focus)\n\nSchick mir gerne noch die offenen Eckdaten, dann melde ich mich mit einem passenden Vorschlag."
            }
        case .professional:
            if let notes = userKeywords(from: topic),
               let keywordBody = mode == .privateChat
                ? privateKeywordBodyGerman(notes: notes)
                : workKeywordBodyGerman(notes: notes, formal: formal) {
                body = keywordBody
            } else {
                body = mode == .privateChat
                    ? clearPrivateBodyGerman(topic: topic)
                    : "vielen Dank für Ihre Nachricht. Für eine belastbare Einschätzung brauche ich bitte Scope, Timing, Deliverables, Budgetrahmen und Nutzungsrechte.\n\n\(focus)\n\nSobald das klar ist, melde ich mich mit dem nächsten Schritt."
            }
        case .briefing:
            body = "vielen Dank für die Anfrage. Für eine konkrete Einschätzung brauche ich bitte noch:\n\n\(briefingList(limit: 6))"
        case .pricing:
            body = pricingBodyGerman(formal: formal)
        case .followUp:
            body = formal
                ? "ich wollte kurz nachfragen, ob die Anfrage weiterhin relevant ist. Falls ja, senden Sie mir gerne die fehlenden Eckdaten:\n\n\(briefingList(limit: 5))"
                : "ich wollte kurz nachfragen, ob die Anfrage weiterhin relevant ist. Falls ja, schick mir gerne die fehlenden Eckdaten:\n\n\(briefingList(limit: 5))"
        case .mediaKit:
            body = mediaKitBody(formal: formal)
        case .decline:
            if mode == .privateChat {
                body = "Danke dir fürs Fragen. Das passt bei mir diesmal leider nicht, aber sag mir gerne Bescheid, wenn es ein anderes Mal wieder relevant ist."
            } else {
                body = formal
                ? "vielen Dank für die Anfrage. Aktuell passt die Kooperation leider nicht sauber zu Profil, Timing oder Rahmenbedingungen. Ich wünsche Ihnen viel Erfolg bei der Umsetzung."
                : "danke dir für die Anfrage. Aktuell passt die Kooperation leider nicht sauber zu Profil, Timing oder Rahmenbedingungen. Ich wünsche euch viel Erfolg bei der Umsetzung."
            }
        case .invoice:
            body = formal
                ? "für die weitere Abwicklung sende ich Ihnen gerne die Rechnungsdaten. Bitte lassen Sie mich wissen, welche Angaben benötigt werden."
                : "für die weitere Abwicklung schicke ich dir gerne die Rechnungsdaten. Sag mir bitte kurz, welche Angaben ihr braucht."
        }

        return wrapDraft(body: body, greeting: greeting, signoff: signoff, topic: topic)
    }

    private func makeEnglishDraft(kind: DraftKind, topic: String) -> String {
        let mode = effectiveConversationMode(for: topic)
        let formal = shouldUseFormalTone(for: kind, topic: topic)
        let greeting = formal ? "Hello," : "Hi,"
        let signoff = formal ? "Best regards\n\(senderName(formal: true))" : "Best\n\(senderName(formal: false))"
        let focus = focusLine(topic: topic, formal: formal)

        let body: String
        switch kind {
        case .reply:
            body = mode == .privateChat
                ? privateReplyBodyEnglish(topic: topic)
                : "thank you for your message. I have noted the key points and would like to align the next step properly.\n\n\(focus)\n\nPlease send me any missing details regarding scope, timing, budget and usage rights so I can come back with a clear recommendation."
        case .approve:
            body = mode == .privateChat ? "Yes, that works for me. Send me the key details and I will get back to you." : approveBodyEnglish(topic: topic)
        case .newMail:
            body = "I am reaching out regarding \(cleanTopic(topic)). I have summarized the key points below.\n\n\(focus)"
        case .collaboration:
            body = "thank you for the request. The collaboration sounds interesting and could be a good fit for \(cleanTopic(profile.niche)).\n\n\(focus)\n\nTo assess it properly, I would need the briefing, deliverables, timing, budget range, usage rights, exclusivity and approval process."
        case .event:
            body = mode == .privateChat
                ? "Yes, that should work. Send me when and where, and I will plan around it."
                : "I am happy to prepare a meeting.\n\n\(focus)\n\nPlease send me two or three suitable time slots. Alternatively, I can suggest a 30-minute call once the goal and timing are clear."
        case .short:
            body = mode == .privateChat
                ? "Thanks, I saw it. I will get back to you shortly."
                : "thank you, this generally sounds suitable. Please send over the scope, timing, budget range and usage rights so I can give you a concrete response."
        case .friendly:
            body = mode == .privateChat
                ? "Thanks for letting me know. That sounds good, I will take a look and get back to you."
                : "thank you for your message. This sounds interesting and I appreciate the request.\n\n\(focus)\n\nI would be happy to align on the details before sending a clear proposal."
        case .professional:
            body = mode == .privateChat
                ? "Thanks, I understand. I will check it and come back with a clear answer."
                : "thank you for your message. To assess the request properly, I would need the final details regarding scope, timing, deliverables, budget range and usage rights.\n\n\(focus)\n\nOnce these points are clear, I will come back with a structured response and a concrete next step."
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

        return wrapDraft(body: body, greeting: greeting, signoff: signoff, topic: topic)
    }

    private func defaultTopic(for kind: DraftKind) -> String {
        switch kind {
        case .approve:
            return language == .german ? "die Frage" : "the question"
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

    private func bestKind(for topic: String?) -> DraftKind {
        let source = normalized(topic ?? "")
        guard !source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return learnedPreferredReplyKind() ?? .reply
        }
        if containsAny(source, [" rechnung ", " invoice ", " zahlung ", " uid ", " steuer ", " honorarnote "]) {
            return .invoice
        }
        if containsAny(source, [" absage ", " ablehnen ", " leider nicht ", " nicht passend ", " passt nicht "]) {
            return .decline
        }
        if containsAny(source, [
            " termin ", " kalender ", " meeting ", " call ", " telefonieren ", " telefonat ",
            " zeitfenster ", " uhr ", " morgen ", " heute ", " montag ", " dienstag ",
            " mittwoch ", " donnerstag ", " freitag ", " samstag ", " sonntag ",
            " zoom ", " teams "
        ]) {
            return .event
        }
        if containsAny(source, [
            " preis ", " budget ", " honorar ", " kosten ", " angebot ", " offerte ",
            " kostenvoranschlag ", " rate ", " fee ", " vergutung ", " vergütung "
        ]) {
            return .pricing
        }
        if containsAny(source, [" follow-up ", " follow up ", " nachfassen ", " nachfragen ", " reminder ", " erinnerung ", " ruckmeldung ", " rückmeldung "]) {
            return .followUp
        }
        if containsAny(source, [" mediakit ", " media kit ", " portfolio ", " press kit "]) {
            return .mediaKit
        }
        if containsAny(source, [" briefing ", " brief ", " infos ", " details ", " eckdaten ", " deliverables ", " freigabe "]) {
            return .briefing
        }
        if containsAny(source, [
            " kooperation ", " zusammenarbeit ", " kampagne ", " collab ", " partnership ",
            " brand ", " marke ", " ugc ", " reel ", " reels ", " story ", " stories ",
            " influencer ", " creator ", " shooting ", " content ", " nutzungsrechte ",
            " whitelisting ", " spark ads ", " paid usage ", " exklusivitat ", " exklusivität "
        ]) {
            return .collaboration
        }
        if looksLikeYesNoQuestion(source) {
            return .approve
        }
        return learnedPreferredReplyKind() ?? .reply
    }

    private func containsAny(_ source: String, _ needles: [String]) -> Bool {
        needles.contains { source.contains($0) }
    }

    private func looksLikeYesNoQuestion(_ source: String) -> Bool {
        source.contains("?") || containsAny(source, [
            " passt das ", " ware das ", " wäre das ", " ist das moglich ", " ist das möglich ",
            " konnen wir ", " können wir ", " kannst du ", " konnen sie ", " können sie ",
            " sollen wir ", " duerfen wir ", " dürfen wir ", " geht das ", " okay ", " ok "
        ])
    }

    private func effectiveConversationMode(for topic: String) -> ConversationMode {
        switch conversationMode {
        case .privateChat, .work:
            return conversationMode
        case .auto:
            if looksLikePrivateChat(topic) {
                return .privateChat
            }
            return .work
        }
    }

    private func looksLikePrivateChat(_ topic: String) -> Bool {
        let source = normalized(topic)
        if containsAny(source, [
            " whatsapp ", " whats app ", " sms ", " privat ", " freund ", " freunde ",
            " familie ", " mama ", " papa ", " schatz ", " liebling ", " insta dm ",
            " dm ", " direct message ", " treffen wir ", " hast du zeit ", " wie geht",
            " essen ", " kaffee ", " kommst du ", " lust ", " bis später ", " bis spaeter"
        ]) {
            return true
        }

        if isBusinessContext(topic) || containsAny(source, [
            " sehr geehrte ", " sehr geehrter ", " guten tag ", " mit freundlichen ",
            " beste grusse ", " beste gruesse ", " beste grüße ", " frau ", " herr ",
            " angebot ", " rechnung ", " kunde ", " kundin ", " anfrage "
        ]) {
            return false
        }

        let cleaned = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return false }
        let lines = cleaned.split(whereSeparator: { $0.isNewline }).count
        let words = cleaned.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count

        if lines <= 3, words <= 36 {
            return cleaned.contains("?") || containsAny(source, [
                " ja ", " nein ", " passt ", " ok ", " okay ", " danke ", " sorry ",
                " morgen ", " heute ", " später ", " spaeter ", " zeit ", " treffen ",
                " wann ", " wo ", " kurz ", " gleich "
            ])
        }

        return false
    }

    private func isBusinessContext(_ topic: String) -> Bool {
        let source = normalized(topic)
        return containsAny(source, [
            " kooperation ", " zusammenarbeit ", " kampagne ", " brand ", " marke ",
            " ugc ", " reel ", " reels ", " story ", " stories ", " influencer ",
            " creator ", " nutzungsrechte ", " whitelisting ", " spark ads ",
            " paid usage ", " briefing ", " budget ", " honorar ", " preis "
        ])
    }

    private func isChatStyle(topic: String) -> Bool {
        let source = normalized(topic)
        return containsAny(source, [
            " whatsapp ", " whats app ", " wa chat ", " dm ", " direct message ",
            " chat ", " instagram ", " insta ", " linkedin ", " sms "
        ])
    }

    private func contextForDraft(rawNotes: String?) -> String? {
        let notes = rawNotes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let stored = storedContextIfUseful()

        if !notes.isEmpty {
            if let stored, !stored.isEmpty {
                return combinedContext(received: stored, notes: notes)
            }
            return notesContext(notes)
        }

        let visibleContext = currentContext().trimmingCharacters(in: .whitespacesAndNewlines)
        if isUsefulMessageContext(visibleContext) {
            if let stored, !stored.isEmpty, visibleContext != stored {
                return combinedContext(received: stored, notes: visibleContext)
            }
            return visibleContext
        }

        return clipboardContextIfUseful()
    }

    private func storedContextIfUseful() -> String? {
        guard let shared = MessageContextStore.loadRecent(),
              isUsefulMessageContext(shared),
              !looksSensitive(shared) else {
            return nil
        }
        return shared
    }

    private func clipboardContextIfUseful() -> String? {
        if let shared = storedContextIfUseful() {
            return shared
        }

        guard hasFullAccess else { return nil }

        let copiedText: String?
        if let explicitContext = MessageContextStore.decodeClipboardContext(UIPasteboard.general.string) {
            copiedText = explicitContext
        } else {
            copiedText = UIPasteboard.general.string
        }

        let text = copiedText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard text.count >= 12,
              text.count <= maximumClipboardContextLength,
              ProfileStore.decodeProfile(from: text) == nil,
              isUsefulMessageContext(text),
              !looksSensitive(text) else {
            return nil
        }
        return text
    }

    private func combinedContext(received: String, notes: String) -> String {
        let received = cleanTopic(received, maxLength: 900)
        let notes = cleanTopic(notes, maxLength: 360)
        if language == .english {
            return "Received message:\n\(received)\n\nMy notes for the reply:\n\(notes)"
        }
        return "Empfangene Nachricht:\n\(received)\n\nMeine Stichworte für die Antwort:\n\(notes)"
    }

    private func notesContext(_ notes: String) -> String {
        let notes = cleanTopic(notes, maxLength: 360)
        if language == .english {
            return "My notes for the reply:\n\(notes)"
        }
        return "Meine Stichworte für die Antwort:\n\(notes)"
    }

    private func isUsefulMessageContext(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 8 else { return false }
        let source = normalized(trimmed)

        if trimmed.contains("?") || trimmed.contains("\n") || trimmed.contains("@") {
            return true
        }

        return containsAny(source, [
            " hallo ", " guten tag ", " hi ", " liebe ", " sehr geehrte ",
            " kooperation ", " zusammenarbeit ", " kampagne ", " brand ", " angebot ",
            " preis ", " budget ", " termin ", " meeting ", " call ", " whatsapp ",
            " instagram ", " reel ", " story ", " briefing ", " rechnung ", " follow up ",
            " rückmeldung ", " ruckmeldung ", " bitte ", " danke "
        ])
    }

    private func looksSensitive(_ text: String) -> Bool {
        let source = normalized(text)
        return containsAny(source, [
            " passwort ", " password ", " tan ", " otp ", " 2fa ", " authentifizierungscode ",
            " verification code ", " sicherheitscode ", " kreditkarte ", " credit card "
        ])
    }

    private func prefersConciseReplies() -> Bool {
        let source = normalized("\(profile.styleVoice) \(profile.learningNotes)")
        return containsAny(source, [" kurz ", " kurzer ", " kompakt ", " knapp ", " präzise ", " prazise ", " concise ", " short "])
    }

    private func learnedPreferredReplyKind() -> DraftKind? {
        let candidates: [DraftKind] = [.short, .friendly, .professional]
        let ranked = candidates
            .map { ($0, learnedCount(for: $0)) }
            .sorted { $0.1 > $1.1 }
        guard let winner = ranked.first, winner.1 >= 3 else { return nil }
        return winner.0
    }

    private func learnedCount(for kind: DraftKind) -> Int {
        UserDefaults.standard.integer(forKey: learningPrefix + kind.storageKey)
    }

    private func registerUse(kind: DraftKind) {
        let key = learningPrefix + kind.storageKey
        UserDefaults.standard.set(learnedCount(for: kind) + 1, forKey: key)
        UserDefaults.standard.synchronize()
    }

    private func shouldUseFormalTone(for kind: DraftKind, topic: String) -> Bool {
        if effectiveConversationMode(for: topic) == .privateChat { return false }
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
        let maxLength = prefersConciseReplies() ? min(maxLength, 240) : maxLength
        let cleaned = topic
            .replacingOccurrences(of: "\n", with: "; ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.count <= maxLength { return cleaned }
        return String(cleaned.prefix(maxLength)).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
    }

    private func userKeywords(from topic: String) -> String? {
        let markers = [
            "Meine Stichworte für die Antwort:",
            "My notes for the reply:"
        ]

        for marker in markers {
            if let range = topic.range(of: marker, options: [.caseInsensitive, .diacriticInsensitive]) {
                let notes = topic[range.upperBound...]
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return notes.isEmpty ? nil : String(notes)
            }
        }

        return nil
    }

    private func sentenceFromKeywords(_ notes: String) -> String {
        let cleaned = cleanTopic(notes, maxLength: 140)
        guard !cleaned.isEmpty else { return "" }
        let first = cleaned.prefix(1).uppercased()
        let rest = cleaned.dropFirst()
        let sentence = "\(first)\(rest)"
        if sentence.hasSuffix(".") || sentence.hasSuffix("!") || sentence.hasSuffix("?") {
            return sentence
        }
        return "\(sentence)."
    }

    private func capitalizedPhrase(_ text: String) -> String {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return cleaned }
        return "\(cleaned.prefix(1).uppercased())\(cleaned.dropFirst())"
    }

    private func timePhrase(from notes: String) -> String? {
        let source = normalized(notes)
        let day: String?
        if source.contains(" heute ") {
            day = "heute"
        } else if source.contains(" morgen ") {
            day = "morgen"
        } else if source.contains(" ubermorgen ") || source.contains(" uebermorgen ") || source.contains(" übermorgen ") {
            day = "übermorgen"
        } else if source.contains(" montag ") {
            day = "am Montag"
        } else if source.contains(" dienstag ") {
            day = "am Dienstag"
        } else if source.contains(" mittwoch ") {
            day = "am Mittwoch"
        } else if source.contains(" donnerstag ") {
            day = "am Donnerstag"
        } else if source.contains(" freitag ") {
            day = "am Freitag"
        } else if source.contains(" samstag ") {
            day = "am Samstag"
        } else if source.contains(" sonntag ") {
            day = "am Sonntag"
        } else {
            day = nil
        }

        let timePattern = #"\b\d{1,2}(:\d{2})?\s*(Uhr|uhr)\b"#
        let time = notes.range(of: timePattern, options: .regularExpression).map { String(notes[$0]) }

        switch (day, time) {
        case let (day?, time?):
            return "\(day) um \(time.replacingOccurrences(of: " Uhr", with: "").replacingOccurrences(of: "uhr", with: "").trimmingCharacters(in: .whitespacesAndNewlines)) Uhr"
        case let (day?, nil):
            return day
        case let (nil, time?):
            return "um \(time)"
        case (nil, nil):
            return nil
        }
    }

    private func privateKeywordBodyGerman(notes: String) -> String? {
        let source = normalized(notes)
        let time = timePhrase(from: notes)

        if containsAny(source, [" nein ", " leider nicht ", " geht nicht ", " keine zeit ", " passt nicht "]) {
            if let time {
                return "\(capitalizedPhrase(time)) geht bei mir leider nicht. Sag mir gerne eine Alternative."
            }
            return "Das geht bei mir leider nicht. Sag mir gerne, ob es eine Alternative gibt."
        }

        if containsAny(source, [" später ", " spaeter ", " nachher ", " melde mich ", " antworten später ", " antworten spaeter "]) {
            return "Hab es gesehen. Ich antworte dir später in Ruhe."
        }

        if containsAny(source, [" ja ", " passt ", " gerne ", " ok ", " okay ", " klar "]) {
            if let time {
                return "Ja, \(time) passt für mich."
            }
            return "Ja, das passt für mich."
        }

        if containsAny(source, [" danke ", " dankeschon ", " dankeschön "]) {
            return "Danke dir, das freut mich."
        }

        if containsAny(source, [" treffen ", " essen ", " kaffee ", " zeit "]), let time {
            return "\(capitalizedPhrase(time)) passt bei mir. Sag mir bitte noch kurz, wo genau."
        }

        return sentenceFromKeywords(notes)
    }

    private func workKeywordBodyGerman(notes: String, formal: Bool) -> String? {
        let source = normalized(notes)
        let sentence = sentenceFromKeywords(notes)
        guard !sentence.isEmpty else { return nil }

        if containsAny(source, [" termin ", " call ", " meeting ", " zeitfenster "]) {
            return formal
                ? "\(sentence)\n\nBitte senden Sie mir dafür zwei bis drei passende Zeitfenster."
                : "\(sentence)\n\nSchick mir dafür bitte zwei bis drei passende Zeitfenster."
        }

        if containsAny(source, [" budget ", " preis ", " honorar ", " kosten "]) {
            return formal
                ? "\(sentence)\n\nFür eine konkrete Einschätzung brauche ich bitte noch Scope, Timing, Deliverables und Nutzungsrechte."
                : "\(sentence)\n\nFür eine konkrete Einschätzung brauche ich bitte noch Scope, Timing, Deliverables und Nutzungsrechte."
        }

        return formal
            ? "\(sentence)\n\nGerne stimme ich den nächsten Schritt sauber mit Ihnen ab."
            : "\(sentence)\n\nGerne stimme ich den nächsten Schritt sauber mit dir ab."
    }

    private func focusLine(topic: String, formal: Bool) -> String {
        let topic = cleanTopic(topic)
        let fallback = language == .german ? "die Anfrage" : "the request"
        guard !topic.isEmpty, topic != fallback else {
            return language == .german ? "Wichtig sind die Eckdaten, der Scope und der nächste Schritt." : "The key points are the details, the scope and the next step."
        }
        if language == .english {
            return "Current context: \(topic)"
        }
        return formal ? "Ausgangslage: \(topic)" : "Ich habe mir notiert: \(topic)"
    }

    private func wrapDraft(body: String, greeting: String, signoff: String, topic: String) -> String {
        if effectiveConversationMode(for: topic) == .privateChat || isChatStyle(topic: topic) {
            return body
        }
        return "\(greeting)\n\n\(body)\n\n\(signoff)"
    }

    private func replyBodyGerman(topic: String, formal: Bool) -> String {
        if effectiveConversationMode(for: topic) == .privateChat {
            return privateReplyBodyGerman(topic: topic)
        }
        if let notes = userKeywords(from: topic),
           let body = workKeywordBodyGerman(notes: notes, formal: formal) {
            return body
        }
        let lower = normalized(topic)
        if lower.contains("preis") || lower.contains("budget") || lower.contains("honorar") || lower.contains("rate") {
            return pricingBodyGerman(formal: formal)
        }
        if lower.contains("kooperation") || lower.contains("collab") || lower.contains("kampagne") || lower.contains("brand") || lower.contains("ugc") {
            return collaborationBodyGerman(topic: topic, formal: formal)
        }
        if lower.contains("termin") || lower.contains("call") || lower.contains("meeting") || lower.contains("kalender") {
            return formal
                ? "vielen Dank für Ihre Nachricht. Bitte senden Sie mir zwei bis drei passende Zeitfenster, dann koordiniere ich den Termin.\n\n\(focusLine(topic: topic, formal: formal))"
                : "danke dir. Schick mir bitte zwei bis drei passende Zeitfenster, dann koordiniere ich den Termin.\n\n\(focusLine(topic: topic, formal: formal))"
        }
        if !isBusinessContext(topic) {
            return workReplyBodyGerman(topic: topic, formal: formal)
        }
        return formal
            ? "vielen Dank für Ihre Nachricht. Ich habe die Punkte aufgenommen und stimme den nächsten Schritt gerne sauber ab.\n\n\(focusLine(topic: topic, formal: formal))\n\nBitte senden Sie mir noch die fehlenden Eckdaten, falls etwas offen ist."
            : "danke dir. Ich habe die Punkte aufgenommen und stimme den nächsten Schritt gerne sauber ab.\n\n\(focusLine(topic: topic, formal: formal))\n\nSchick mir gerne noch die fehlenden Eckdaten, falls etwas offen ist."
    }

    private func privateReplyBodyGerman(topic: String) -> String {
        if let notes = userKeywords(from: topic),
           let body = privateKeywordBodyGerman(notes: notes) {
            return body
        }
        let lower = normalized(topic)
        if containsAny(lower, [" danke ", " danke dir ", " vielen dank "]) {
            return "Sehr gerne, freut mich. Gib mir kurz Bescheid, falls noch etwas offen ist."
        }
        if containsAny(lower, [" sorry ", " tut mir leid ", " entschuldige ", " entschuldigung "]) {
            return "Alles gut, danke fürs Bescheid geben. Mach dir keinen Stress."
        }
        if containsAny(lower, [" wie geht ", " alles gut ", " wie lauft ", " wie läuft "]) {
            return "Danke dir, bei mir passt alles. Wie geht es dir?"
        }
        if containsAny(lower, [" treffen ", " essen ", " kaffee ", " zeit ", " kommst du ", " lust "]) {
            return "Klingt gut. Sag mir bitte kurz wann und wo, dann schaue ich, wie es sich ausgeht."
        }
        if looksLikeYesNoQuestion(lower) {
            return "Ja, das passt grundsätzlich. Schick mir bitte noch kurz die wichtigsten Details."
        }
        if lower.contains("?") {
            return "Danke dir, ich schaue es mir an und melde mich gleich mit einer Antwort."
        }
        return "Danke dir, ich habe es gesehen. Ich melde mich gleich dazu."
    }

    private func shortPrivateBodyGerman(topic: String) -> String {
        if let notes = userKeywords(from: topic),
           let body = privateKeywordBodyGerman(notes: notes) {
            return body
        }
        let lower = normalized(topic)
        if looksLikeYesNoQuestion(lower) {
            return "Ja, passt grundsätzlich. Schick mir bitte kurz die Details."
        }
        return "Danke dir, ich habe es gesehen. Ich melde mich gleich."
    }

    private func friendlyPrivateBodyGerman(topic: String) -> String {
        if let notes = userKeywords(from: topic),
           let body = privateKeywordBodyGerman(notes: notes) {
            return body
        }
        let lower = normalized(topic)
        if containsAny(lower, [" treffen ", " essen ", " kaffee ", " zeit ", " lust "]) {
            return "Klingt gut, danke dir. Sag mir kurz wann und wo, dann schaue ich, wie es bei mir passt."
        }
        return "Danke dir fürs Bescheid geben. Ich schaue es mir in Ruhe an und melde mich gleich."
    }

    private func clearPrivateBodyGerman(topic: String) -> String {
        if let notes = userKeywords(from: topic),
           let body = privateKeywordBodyGerman(notes: notes) {
            return body
        }
        let lower = normalized(topic)
        if lower.contains("?") {
            return "Danke dir. Ich prüfe das kurz und gebe dir gleich eine klare Antwort."
        }
        return "Verstanden, danke dir. Ich kümmere mich darum und melde mich, sobald ich es geprüft habe."
    }

    private func workReplyBodyGerman(topic: String, formal: Bool) -> String {
        if let notes = userKeywords(from: topic),
           let body = workKeywordBodyGerman(notes: notes, formal: formal) {
            return body
        }
        if formal {
            return "vielen Dank für Ihre Nachricht. Ich habe die Punkte aufgenommen und prüfe den nächsten Schritt.\n\n\(focusLine(topic: topic, formal: formal))\n\nFalls noch etwas offen ist, melde ich mich kurz mit einer Rückfrage."
        }
        return "danke dir, ich habe es gesehen. Ich prüfe den nächsten Schritt und melde mich kurz, falls noch etwas offen ist.\n\n\(focusLine(topic: topic, formal: formal))"
    }

    private func approveBodyGerman(topic: String, formal: Bool) -> String {
        if effectiveConversationMode(for: topic) == .privateChat {
            return shortPrivateBodyGerman(topic: topic)
        }
        let lower = normalized(topic)
        if containsAny(lower, [" termin ", " call ", " meeting ", " zeitfenster "]) {
            return formal
                ? "ja, das passt grundsätzlich. Bitte senden Sie mir zwei bis drei konkrete Zeitfenster, dann bestätige ich den Termin."
                : "ja, das passt grundsätzlich. Schick mir bitte zwei bis drei konkrete Zeitfenster, dann bestätige ich den Termin."
        }
        if containsAny(lower, [" kooperation ", " kampagne ", " collab ", " ugc ", " reel ", " story ", " nutzungsrechte "]) {
            return formal
                ? "ja, grundsätzlich ist das interessant. Für eine finale Einschätzung brauche ich bitte noch Briefing, Deliverables, Timing, Budgetrahmen und Nutzungsrechte."
                : "ja, grundsätzlich klingt das interessant. Für eine finale Einschätzung brauche ich bitte noch Briefing, Deliverables, Timing, Budgetrahmen und Nutzungsrechte."
        }
        if containsAny(lower, [" preis ", " budget ", " honorar ", " kosten "]) {
            return formal
                ? "ja, ich kann Ihnen dazu gerne eine Einschätzung geben. Dafür brauche ich bitte noch Scope, Deliverables, Timing und Nutzungsrechte."
                : "ja, ich kann dir dazu gerne eine Einschätzung geben. Dafür brauche ich bitte noch Scope, Deliverables, Timing und Nutzungsrechte."
        }
        return formal
            ? "ja, das ist grundsätzlich möglich. Bitte senden Sie mir noch die offenen Eckdaten, dann bestätige ich den nächsten Schritt verbindlich."
            : "ja, das ist grundsätzlich möglich. Schick mir bitte noch die offenen Eckdaten, dann bestätige ich den nächsten Schritt."
    }

    private func approveBodyEnglish(topic: String) -> String {
        let lower = normalized(topic)
        if containsAny(lower, [" meeting ", " call ", " time slot ", " calendar "]) {
            return "yes, that generally works. Please send me two or three concrete time slots and I will confirm the meeting."
        }
        if containsAny(lower, [" collaboration ", " campaign ", " collab ", " ugc ", " reel ", " story ", " usage rights "]) {
            return "yes, this sounds interesting. For a final assessment, I would need the briefing, deliverables, timing, budget range and usage rights."
        }
        if containsAny(lower, [" price ", " budget ", " fee ", " cost ", " rate "]) {
            return "yes, I can give you a reliable estimate. For that, I would need the scope, deliverables, timing and usage rights."
        }
        return "yes, that is generally possible. Please send me the remaining key details and I will confirm the next step."
    }

    private func privateReplyBodyEnglish(topic: String) -> String {
        let lower = normalized(topic)
        if containsAny(lower, [" thanks ", " thank you "]) {
            return "Of course, happy to help. Let me know if anything else is open."
        }
        if containsAny(lower, [" sorry ", " apology ", " apologies "]) {
            return "No worries, thanks for letting me know."
        }
        if containsAny(lower, [" how are you ", " all good "]) {
            return "Thanks, I am good. How are you?"
        }
        if containsAny(lower, [" meet ", " dinner ", " coffee ", " time ", " are you free "]) {
            return "Sounds good. Send me when and where, and I will check what works."
        }
        if looksLikeYesNoQuestion(lower) {
            return "Yes, that should work. Send me the key details."
        }
        if lower.contains("?") {
            return "Thanks, I will check it and get back to you shortly."
        }
        return "Thanks, I saw it. I will get back to you shortly."
    }

    private func collaborationBodyGerman(topic: String, formal: Bool) -> String {
        let intro = formal
            ? "vielen Dank für die Anfrage. Die Kooperation klingt interessant und passt potenziell zu \(cleanTopic(profile.niche))."
            : "danke dir für die Anfrage. Die Kooperation klingt interessant und passt potenziell zu \(cleanTopic(profile.niche))."
        let ask = formal
            ? "Für eine seriöse Einschätzung senden Sie mir bitte noch:"
            : "Für eine seriöse Einschätzung schick mir bitte noch:"
        return "\(intro)\n\n\(focusLine(topic: topic, formal: formal))\n\n\(ask)\n\n\(briefingList(limit: 7))\n\nWichtig: \(profile.usageRightsPolicy)"
    }

    private func pricingBodyGerman(formal: Bool) -> String {
        let ask = formal
            ? "zum Budget kann ich eine seriöse Einschätzung geben, sobald der Scope klar ist. Relevant sind:"
            : "zum Budget kann ich eine seriöse Einschätzung geben, sobald der Scope klar ist. Relevant sind:"
        return "\(ask)\n\n\(briefingList(limit: 6))\n\n\(profile.rateCardNote)\n\n\(profile.usageRightsPolicy)"
    }

    private func briefingList(limit: Int) -> String {
        let limit = prefersConciseReplies() ? min(limit, 5) : limit
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
        let linkBlock = links.isEmpty ? "[Media-Kit Link ergänzen]" : links
        let serviceBlock = services.isEmpty ? "[Leistungen ergänzen]" : services

        if language == .english {
            return "here are the key details for a potential collaboration:\n\n\(linkBlock)\n\nServices:\n\(serviceBlock)\n\nFor a concrete proposal, I would need the briefing, deliverables, timing, budget and usage rights."
        }

        if formal {
            return "hier finden Sie die wichtigsten Infos für eine mögliche Zusammenarbeit:\n\n\(linkBlock)\n\nLeistungen:\n\(serviceBlock)\n\nFür ein konkretes Angebot brauche ich bitte Briefing, Deliverables, Timing, Budget und Nutzungsrechte."
        }
        return "hier findest du die wichtigsten Infos für eine mögliche Zusammenarbeit:\n\n\(linkBlock)\n\nLeistungen:\n\(serviceBlock)\n\nFür ein konkretes Angebot brauche ich bitte Briefing, Deliverables, Timing, Budget und Nutzungsrechte."
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

    private func setLanguage(_ nextLanguage: OutputLanguage) {
        language = nextLanguage
        rebuildKeyboard()
    }

    @objc private func toggleFormality() {
        formality.toggle()
        rebuildKeyboard()
    }

    private func setFormality(_ nextFormality: Formality) {
        formality = nextFormality
        rebuildKeyboard()
    }

    @objc private func toggleConversationMode() {
        conversationMode.toggle()
        conversationMode.save()
        rebuildKeyboard()
    }

    private func setConversationMode(_ nextMode: ConversationMode) {
        conversationMode = nextMode
        conversationMode.save()
        rebuildKeyboard()
    }

    @objc private func toggleShift() {
        isShifted.toggle()
        rebuildKeyboard()
    }

    @objc private func insertReplyDraft() {
        insertSmartReplyDraft()
    }

    @objc private func insertNewMailDraft() {
        insertDraftReplacingNotesIfUseful(kind: .newMail)
    }

    @objc private func insertApproveDraft() {
        insertDraftReplacingNotesIfUseful(kind: .approve)
    }

    @objc private func insertCollaborationDraft() {
        insertDraftReplacingNotesIfUseful(kind: .collaboration)
    }

    @objc private func insertEventDraft() {
        insertDraftReplacingNotesIfUseful(kind: .event)
    }

    @objc private func insertThreeDrafts() {
        insertDraftVariant(.short)
    }

    private func insertDraftVariant(_ kind: DraftKind) {
        insertDraftReplacingNotesIfUseful(kind: kind)
    }

    @objc private func insertThanksDraft() {
        let rawNotes = notesBeforeInputForReplacement()
        let context = sourceContextForDraft(rawNotes: rawNotes)
        replaceTextBeforeInsert(rawNotes)
        registerUse(kind: .friendly)
        if language == .english {
            insertGeneratedText("Thank you, I really appreciate it. I will get back to you shortly if anything else is open.", sourceContext: context)
        } else {
            insertGeneratedText("Danke dir, das freut mich. Ich melde mich kurz, falls noch etwas offen ist.", sourceContext: context)
        }
    }

    @objc private func insertSorryDraft() {
        let rawNotes = notesBeforeInputForReplacement()
        let context = sourceContextForDraft(rawNotes: rawNotes)
        replaceTextBeforeInsert(rawNotes)
        registerUse(kind: .friendly)
        if language == .english {
            insertGeneratedText("Sorry, that took a little longer. Thanks for your patience, I will take care of it now.", sourceContext: context)
        } else {
            insertGeneratedText("Sorry, das hat etwas länger gedauert. Danke dir fürs Warten, ich kümmere mich jetzt darum.", sourceContext: context)
        }
    }

    @objc private func insertPrivateMeetingDraft() {
        let rawNotes = notesBeforeInputForReplacement()
        let context = sourceContextForDraft(rawNotes: rawNotes)
        replaceTextBeforeInsert(rawNotes)
        registerUse(kind: .event)
        if language == .english {
            insertGeneratedText("Sounds good. Send me when and where, and I will check what works for me.", sourceContext: context)
        } else if let context, normalized(context).contains("morgen") {
            insertGeneratedText("Morgen passt grundsätzlich. Sag mir bitte kurz Uhrzeit und Ort, dann richte ich mich danach.", sourceContext: context)
        } else {
            insertGeneratedText("Klingt gut. Sag mir bitte kurz wann und wo, dann schaue ich, wie es bei mir passt.", sourceContext: context)
        }
    }

    @objc private func insertLaterDraft() {
        let rawNotes = notesBeforeInputForReplacement()
        let context = sourceContextForDraft(rawNotes: rawNotes)
        replaceTextBeforeInsert(rawNotes)
        registerUse(kind: .short)
        if language == .english {
            insertGeneratedText("I saw it. I will reply properly a little later.", sourceContext: context)
        } else {
            insertGeneratedText("Hab es gesehen. Ich antworte dir später in Ruhe.", sourceContext: context)
        }
    }

    @objc private func insertTranslatedReplyDraft() {
        let rawNotes = notesBeforeInputForReplacement()
        let context = sourceContextForDraft(rawNotes: rawNotes)
        let kind = bestKind(for: context ?? currentContext())
        let previousLanguage = language
        language.toggle()
        let draft = makeDraft(kind: kind, contextOverride: context)
        language = previousLanguage
        replaceTextBeforeInsert(rawNotes)
        registerUse(kind: kind)
        insertGeneratedText(draft, sourceContext: context)
        improveGeneratedDraftWithBackend(kind: kind, localDraft: draft, sourceContext: context)
    }

    @objc private func insertAnalysisDraft() {
        let rawNotes = notesBeforeInputForReplacement()
        let context = sourceContextForDraft(rawNotes: rawNotes) ?? currentContext()
        let kind = bestKind(for: context)
        let analysis = makeAnalysisDraft(context: context, kind: kind)
        replaceTextBeforeInsert(rawNotes)
        insertGeneratedText(analysis, sourceContext: context)
        improveGeneratedDraftWithBackend(kind: kind, localDraft: analysis, sourceContext: context)
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
            insertText("Beste Grüße\n\(senderName(formal: true))")
        } else {
            insertText("Liebe Grüße\n\(senderName(formal: false))")
        }
    }

    private func insertDraftReplacingNotesIfUseful(kind: DraftKind) {
        let rawNotes = notesBeforeInputForReplacement()
        let context = sourceContextForDraft(rawNotes: rawNotes)
        let draft = makeDraft(kind: kind, contextOverride: context)
        replaceTextBeforeInsert(rawNotes)
        registerUse(kind: kind)
        insertGeneratedText(draft, sourceContext: context)
        improveGeneratedDraftWithBackend(kind: kind, localDraft: draft, sourceContext: context)
    }

    private func insertSmartReplyDraft() {
        let rawNotes = notesBeforeInputForReplacement()
        let context = sourceContextForDraft(rawNotes: rawNotes)
        let kind = bestKind(for: context ?? currentContext())
        let draft = makeDraft(kind: kind, contextOverride: context)
        replaceTextBeforeInsert(rawNotes)
        registerUse(kind: kind)
        insertGeneratedText(draft, sourceContext: context)
        improveGeneratedDraftWithBackend(kind: kind, localDraft: draft, sourceContext: context)
    }

    private func makeAnalysisDraft(context: String, kind: DraftKind) -> String {
        let mode = effectiveConversationMode(for: context)
        let formal = shouldUseFormalTone(for: kind, topic: context)
        let topic = cleanTopic(context, maxLength: 220)

        if mode == .privateChat {
            if language == .english {
                return [
                    "Suggestions:",
                    "- Reply: \(makeDraft(kind: .reply, contextOverride: context))",
                    "- Short: \(makeDraft(kind: .short, contextOverride: context))",
                    "- Clear: \(makeDraft(kind: .professional, contextOverride: context))"
                ].joined(separator: "\n")
            }

            return [
                "Vorschläge:",
                "- Antwort: \(makeDraft(kind: .reply, contextOverride: context))",
                "- Kurz: \(makeDraft(kind: .short, contextOverride: context))",
                "- Klar: \(makeDraft(kind: .professional, contextOverride: context))"
            ].joined(separator: "\n")
        }

        if language == .english {
            return [
                "Detected: \(modeLabel(mode)) / \(intentLabel(kind))",
                "Tone: \(formal ? "formal" : "casual"), \(mode == .privateChat ? "no greeting/sign-off" : "structured reply")",
                "Reply logic: \(recommendationLabel(kind: kind, mode: mode))",
                "Context: \(topic)"
            ].joined(separator: "\n")
        }

        return [
            "Erkannt: \(modeLabel(mode)) / \(intentLabel(kind))",
            "Stil: \(formal ? "förmlich" : "locker"), \(mode == .privateChat ? "ohne Grußformel" : "strukturierte Antwort")",
            "Antwortlogik: \(recommendationLabel(kind: kind, mode: mode))",
            "Kontext: \(topic)"
        ].joined(separator: "\n")
    }

    private func modeLabel(_ mode: ConversationMode) -> String {
        switch (language, mode) {
        case (.german, .auto): return "Auto"
        case (.german, .privateChat): return "Privat/Chat"
        case (.german, .work): return "Arbeit/Mail"
        case (.english, .auto): return "Auto"
        case (.english, .privateChat): return "Private/chat"
        case (.english, .work): return "Work/mail"
        }
    }

    private func intentLabel(_ kind: DraftKind) -> String {
        switch (language, kind) {
        case (.german, .reply): return "Antwort"
        case (.german, .approve): return "Zusage/Ja"
        case (.german, .newMail): return "neue Mail"
        case (.german, .collaboration): return "Kooperation"
        case (.german, .event): return "Termin"
        case (.german, .short): return "kurz"
        case (.german, .friendly): return "freundlich"
        case (.german, .professional): return "professionell"
        case (.german, .briefing): return "Briefing"
        case (.german, .pricing): return "Preis/Budget"
        case (.german, .followUp): return "Follow-up"
        case (.german, .mediaKit): return "MediaKit"
        case (.german, .decline): return "Absage"
        case (.german, .invoice): return "Rechnung"
        case (.english, .reply): return "reply"
        case (.english, .approve): return "yes/approval"
        case (.english, .newMail): return "new email"
        case (.english, .collaboration): return "collaboration"
        case (.english, .event): return "meeting"
        case (.english, .short): return "short"
        case (.english, .friendly): return "friendly"
        case (.english, .professional): return "professional"
        case (.english, .briefing): return "briefing"
        case (.english, .pricing): return "price/budget"
        case (.english, .followUp): return "follow-up"
        case (.english, .mediaKit): return "media kit"
        case (.english, .decline): return "decline"
        case (.english, .invoice): return "invoice"
        }
    }

    private func recommendationLabel(kind: DraftKind, mode: ConversationMode) -> String {
        if language == .english {
            if mode == .privateChat { return "answer naturally, short, without email framing." }
            switch kind {
            case .event: return "ask for or confirm time slots."
            case .pricing: return "clarify scope before price."
            case .collaboration: return "ask for briefing, deliverables, timing, budget and usage rights."
            case .decline: return "decline politely without overexplaining."
            default: return "acknowledge context and define the next step."
            }
        }

        if mode == .privateChat { return "natürlich, kurz und ohne Mail-Rahmen antworten." }
        switch kind {
        case .event: return "Zeitfenster klären oder Termin bestätigen."
        case .pricing: return "erst Scope klären, dann Preis nennen."
        case .collaboration: return "Briefing, Deliverables, Timing, Budget und Nutzungsrechte anfragen."
        case .decline: return "höflich absagen, ohne unnötig zu erklären."
        default: return "Kontext bestätigen und nächsten Schritt klar machen."
        }
    }

    private func improveGeneratedDraftWithBackend(kind: DraftKind, localDraft: String, sourceContext: String?) {
        guard hasFullAccess,
              let url = aiBackendEndpoint(),
              !localDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        let context = (sourceContext ?? currentContext()).trimmingCharacters(in: .whitespacesAndNewlines)
        Task { [weak self] in
            guard let self else { return }
            guard let improved = await self.requestBackendDraft(url: url, kind: kind, context: context, localDraft: localDraft),
                  !improved.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  improved != localDraft else {
                return
            }

            await MainActor.run {
                self.replaceLastGeneratedDraftWithBackend(improved, sourceContext: context)
            }
        }
    }

    private func aiBackendEndpoint() -> URL? {
        let trimmed = profile.aiBackendURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return URL(string: trimmed)
    }

    private func requestBackendDraft(url: URL, kind: DraftKind, context: String, localDraft: String) async -> String? {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let payload: [String: Any] = [
            "operation": kind.storageKey,
            "prompt": backendPrompt(kind: kind, context: context, localDraft: localDraft),
            "context": context,
            "draft": localDraft,
            "language": language == .german ? "de" : "en",
            "formality": formality == .formal ? "formal" : "casual",
            "conversationMode": effectiveConversationMode(for: context).shortTitle,
            "profile": [
                "firstName": profile.firstName,
                "lastName": profile.lastName,
                "formalSender": profile.formalSender,
                "casualSender": profile.casualSender,
                "mailAccounts": profile.normalizedMailAccounts,
                "roleTitle": profile.roleTitle,
                "niche": profile.niche,
                "services": profile.services,
                "styleVoice": profile.styleVoice,
                "learningNotes": profile.learningNotes,
                "rateCardNote": profile.rateCardNote,
                "usageRightsPolicy": profile.usageRightsPolicy,
                "briefingChecklist": profile.briefingChecklist,
                "brandSafetyNoGos": profile.brandSafetyNoGos
            ]
        ]

        guard JSONSerialization.isValidJSONObject(payload),
              let body = try? JSONSerialization.data(withJSONObject: payload) else {
            return nil
        }
        request.httpBody = body

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse,
               !(200..<300).contains(http.statusCode) {
                return nil
            }
            return extractBackendText(from: data)
        } catch {
            return nil
        }
    }

    private func backendPrompt(kind: DraftKind, context: String, localDraft: String) -> String {
        let mode = effectiveConversationMode(for: context)
        if language == .english {
            return """
            Improve the draft below for a private iPhone keyboard assistant. Never send automatically. Use the received context, keep the message coherent, and match \(mode == .privateChat ? "private chat" : "business email") style.

            Intent: \(kind.storageKey)
            Profile: \(profile.fullName), \(profile.roleTitle)
            Voice: \(profile.styleVoice)
            Rules: \(profile.learningNotes)

            Received context:
            \(cleanTopic(context, maxLength: 1200))

            Draft to improve:
            \(localDraft)
            """
        }

        return """
        Verbessere den folgenden Entwurf für eine private iPhone-Tastatur. Niemals automatisch senden. Nutze den empfangenen Kontext, antworte nachvollziehbar und passe den Stil an \(mode == .privateChat ? "private Chat-Kommunikation" : "geschäftliche Mail-Kommunikation") an.

        Absicht: \(kind.storageKey)
        Profil: \(profile.fullName), \(profile.roleTitle)
        Stimme: \(profile.styleVoice)
        Regeln: \(profile.learningNotes)

        Empfangener Kontext:
        \(cleanTopic(context, maxLength: 1200))

        Entwurf verbessern:
        \(localDraft)
        """
    }

    private func extractBackendText(from data: Data) -> String? {
        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            for key in ["text", "output", "answer", "content"] {
                if let text = object[key] as? String,
                   !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return text.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }

            if let message = object["message"] as? [String: Any],
               let content = message["content"] as? String,
               !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return content.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            if let choices = object["choices"] as? [[String: Any]],
               let first = choices.first,
               let message = first["message"] as? [String: Any],
               let content = message["content"] as? String,
               !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return content.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        if let text = String(data: data, encoding: .utf8) {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }

        return nil
    }

    private func replaceLastGeneratedDraftWithBackend(_ improved: String, sourceContext: String?) {
        guard let previous = lastGeneratedDraftAtCursor() else { return }
        for _ in 0..<previous.length {
            textDocumentProxy.deleteBackward()
        }
        clearLastGeneratedDraft()
        insertGeneratedText(improved, sourceContext: sourceContext)
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
            "liebe grüße", "beste grüße", "mit freundlichen gruessen", "mit freundlichen grüßen",
            "best regards", "kind regards", "sent from"
        ]
        if protectedMailMarkers.contains(where: { lower.contains($0) }) {
            return nil
        }
        return before
    }

    private func sourceContextForDraft(rawNotes: String?) -> String? {
        if lastGeneratedDraftAtCursor() != nil,
           let previousSource = UserDefaults.standard.string(forKey: lastDraftSourceContextKey),
           !previousSource.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return previousSource
        }
        return contextForDraft(rawNotes: rawNotes)
    }

    private func replaceTextBeforeInsert(_ notes: String?) {
        if let previous = lastGeneratedDraftAtCursor() {
            for _ in 0..<previous.length {
                textDocumentProxy.deleteBackward()
            }
            clearLastGeneratedDraft()
            return
        }
        deleteNotesIfNeeded(notes)
    }

    private func insertGeneratedText(_ text: String, sourceContext: String?) {
        insertText(text)
        rememberGeneratedDraft(text, sourceContext: sourceContext)
    }

    private func rememberGeneratedDraft(_ text: String, sourceContext: String?) {
        let defaults = UserDefaults.standard
        defaults.set(text.count, forKey: lastDraftLengthKey)
        defaults.set(String(text.suffix(lastDraftSuffixLength)), forKey: lastDraftSuffixKey)
        if let sourceContext,
           !sourceContext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            defaults.set(sourceContext, forKey: lastDraftSourceContextKey)
        } else {
            defaults.removeObject(forKey: lastDraftSourceContextKey)
        }
        defaults.synchronize()
    }

    private func lastGeneratedDraftAtCursor() -> (length: Int, sourceContext: String?)? {
        guard (textDocumentProxy.documentContextAfterInput ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        let defaults = UserDefaults.standard
        let length = defaults.integer(forKey: lastDraftLengthKey)
        guard length > 0,
              let suffix = defaults.string(forKey: lastDraftSuffixKey),
              !suffix.isEmpty,
              let before = textDocumentProxy.documentContextBeforeInput,
              before.hasSuffix(suffix) else {
            return nil
        }
        return (length, defaults.string(forKey: lastDraftSourceContextKey))
    }

    private func clearLastGeneratedDraft() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: lastDraftLengthKey)
        defaults.removeObject(forKey: lastDraftSuffixKey)
        defaults.removeObject(forKey: lastDraftSourceContextKey)
        defaults.synchronize()
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
    case approve
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

    var storageKey: String {
        switch self {
        case .reply: return "reply"
        case .approve: return "approve"
        case .newMail: return "newMail"
        case .collaboration: return "collaboration"
        case .event: return "event"
        case .short: return "short"
        case .friendly: return "friendly"
        case .professional: return "professional"
        case .briefing: return "briefing"
        case .pricing: return "pricing"
        case .followUp: return "followUp"
        case .mediaKit: return "mediaKit"
        case .decline: return "decline"
        case .invoice: return "invoice"
        }
    }
}
