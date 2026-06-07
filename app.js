const STORAGE_KEY = "linda-social-desk-v1";

let activeSuggestions = [];
let gmailMessages = [];
let selectedGmailThreadId = "";

const DEFAULT_STATE = {
  owner: {
    firstName: "Linda",
    lastName: "Hiller",
    gender: "female",
    appName: "Linda Social Desk",
    formalSender: "Frau Hiller",
    casualSender: "Linda",
    roleTitle: "Influencerin / Social Media Managerin",
    niche: "Lifestyle, Sport, Content Creation, Brand-Kooperationen",
    services: "Reels, Stories, UGC, Shootings, Kampagnenkonzepte, Content-Kalender",
    mediaKitUrl: "",
    socialLinks: "",
    rateCardNote: "Preise erst nach Briefing, Deliverables, Nutzungsrechten, Laufzeit und Budgetrahmen fixieren.",
    usageRightsPolicy: "Whitelisting/Spark Ads, Paid Usage, Exklusivität und Laufzeit immer separat klären.",
    briefingChecklist: "Kampagnenziel\nDeliverables\nTiming/Deadline\nBudgetrahmen\nNutzungsrechte/Laufzeit\nExklusivität\nFreigabeschleifen\nReporting",
    brandSafetyNoGos: "keine unbefristeten Nutzungsrechte ohne Vergütung, keine automatischen Zusagen, keine Preise ohne Scope"
  },
  accounts: [
    {
      email: "info@jonnyandlinda.com",
      label: "Jonny & Linda",
      provider: "Google Workspace / Gmail via Wix",
      accessStatus: "nicht verbunden",
      active: true,
      defaultSender: "Linda Hiller",
      signature: "Liebe Grüße\nLinda"
    },
    {
      email: "linda.hiller@skinfit.eu",
      label: "Skinfit",
      provider: "Provider offen",
      accessStatus: "nicht verbunden",
      active: true,
      defaultSender: "Frau Hiller",
      signature: "Beste Grüße\nLinda Hiller"
    },
    {
      email: "hillerlinda@icloud.com",
      label: "iCloud",
      provider: "iCloud Mail",
      accessStatus: "nicht verbunden",
      active: true,
      defaultSender: "Linda",
      signature: "Liebe Grüße\nLinda"
    },
    {
      email: "lindas.contentfactory@gmail.com",
      label: "Linda Content Factory",
      provider: "Gmail",
      accessStatus: "nicht verbunden",
      active: true,
      defaultSender: "Linda Hiller",
      signature: "Liebe Grüße\nLinda"
    }
  ],
  brands: [
    {
      id: "general",
      name: "Allgemein",
      tone: "klar, freundlich, professionell, nicht übertrieben",
      audience: "Kundinnen, Partner, Brands, interne Abstimmungen",
      noGos: "nicht automatisch zusagen, keine Preise erfinden, keine Nachricht automatisch senden"
    },
    {
      id: "skinfit",
      name: "Skinfit",
      tone: "präzise, sportlich, verbindlich, hochwertig",
      audience: "Kundinnen, Athleten, Partner, Team",
      noGos: "keine privaten Details, keine unbestätigten Liefer- oder Rabattzusagen"
    },
    {
      id: "contentfactory",
      name: "Linda Content Factory",
      tone: "kreativ, hochwertig, direkt, warm",
      audience: "Brands, Creator, Agenturen, Kooperationspartner",
      noGos: "kein generischer Agenturton, keine schwammigen Leistungsversprechen"
    }
  ],
  style: {
    voice: "Linda schreibt klar, warm und professionell. Sie klingt effizient, nahbar und nie künstlich. Sie vermeidet lange Erklärungen, bleibt aber vollständig, wenn Termine, Preise, nächste Schritte oder Verantwortlichkeiten wichtig sind.",
    rules: "Nie automatisch senden. Immer als Entwurf formulieren. Wenn Informationen fehlen, dezent markieren. Anrede und Signatur an Konto, Kanal und Beziehung anpassen. Bei Kooperationen immer Deliverables, Budget, Nutzungsrechte, Timing und Freigaben klären.",
    signature: "Liebe Grüße\nLinda"
  },
  settings: {
    apiMode: "local",
    backendUrl: "",
    gmailBackendUrl: "http://127.0.0.1:8787",
    gmailQuery: "to:info@jonnyandlinda.com newer_than:30d",
    targetLanguage: "de",
    allowedMailOnly: true,
    primaryCalendar: "icloud",
    calendarMode: "ics-first"
  },
  followups: [],
  calendar: []
};

let state = normalizeState(loadState());
let workflowMode = "reply";
let activeCalendarEvent = null;

const $ = (selector) => document.querySelector(selector);
const $$ = (selector) => Array.from(document.querySelectorAll(selector));

document.addEventListener("DOMContentLoaded", init);

function init() {
  renderAll();
  bindEvents();
  updatePromptPreview();
  updateSummary();

  if ("serviceWorker" in navigator) {
    navigator.serviceWorker.register("sw.js").catch(() => {});
  }
}

function bindEvents() {
  $$(".tab-button").forEach((button) => {
    button.addEventListener("click", () => activatePanel(button.dataset.panel));
  });

  $$(".ai-toolbar button").forEach((button) => {
    button.addEventListener("click", () => handleToolbarAction(button.dataset.action));
  });

  $$(".workflow-button").forEach((button) => {
    button.addEventListener("click", () => setWorkflowMode(button.dataset.workflowMode));
  });

  const settingSelectors = new Set(["#apiMode", "#backendUrl", "#gmailBackendUrl", "#gmailQuery", "#allowedMailOnly", "#primaryCalendar", "#calendarMode"]);
  [
    "#fromAccount",
    "#brandSelect",
    "#relationshipSelect",
    "#senderNameSelect",
    "#channelSelect",
    "#toneSelect",
    "#recipientName",
    "#replyGoal",
    "#threadInput",
    "#keywordInput",
    "#eventTitle",
    "#eventAttendees",
    "#eventDate",
    "#eventTime",
    "#eventDuration",
    "#eventLocation",
    "#contentType",
    "#contentChannel",
    "#contentBrandSelect",
    "#contentCta",
    "#contentTopic",
    "#contentDetails",
    "#calendarRange",
    "#calendarFrequency",
    "#calendarTopics",
    "#apiMode",
    "#backendUrl",
    "#gmailBackendUrl",
    "#gmailQuery",
    "#allowedMailOnly",
    "#primaryCalendar",
    "#calendarMode"
  ].forEach((selector) => {
    const element = $(selector);
    if (element) {
      element.addEventListener("input", () => {
        syncSettingsFromInputs();
        if (settingSelectors.has(selector)) {
          renderAccounts();
          renderAccessPlan();
        }
        updatePromptPreview();
        updateSummary();
        updateDecisionPreview();
      });
    }
  });

  $("#generateContent").addEventListener("click", () => generateContent());
  $("#checkGmailStatus").addEventListener("click", () => checkGmailStatus());
  $("#connectGmail").addEventListener("click", () => connectGmail());
  $("#loadGmailMessages").addEventListener("click", () => loadGmailMessages());
  $("#loadTemplate").addEventListener("click", () => loadSelectedTemplate());
  $("#generateCalendar").addEventListener("click", () => generateCalendarPlan());
  $("#saveProfiles").addEventListener("click", () => saveProfiles());
  $("#addBrand").addEventListener("click", () => addBrandProfile());
  $("#addAccount").addEventListener("click", () => addAccount());
  $("#copyDraft").addEventListener("click", () => copyText($("#outputText").value, "Entwurf kopiert"));
  $("#downloadDraft").addEventListener("click", () => downloadDraft());
  $("#downloadCalendarInvite").addEventListener("click", () => downloadCalendarInvite());
  $("#addFollowup").addEventListener("click", () => addFollowup());
  $("#summarizeThread").addEventListener("click", () => updateSummary(true));
  $("#copyPrompt").addEventListener("click", () => copyText($("#promptPreview").value, "Prompt kopiert"));
  $("#clearFollowups").addEventListener("click", clearFollowups);
  $("#exportConfig").addEventListener("click", exportConfig);
  $("#importConfig").addEventListener("click", () => $("#importFile").click());
  $("#importFile").addEventListener("change", importConfig);
  $("#resetConfig").addEventListener("click", resetConfig);
  $("#dictateThread").addEventListener("click", () => startDictation("threadInput"));
  $("#dictateContent").addEventListener("click", () => startDictation("contentTopic"));
  $("#dictateDraft").addEventListener("click", () => startDictation("outputText"));
  setWorkflowMode("reply");
}

function activatePanel(panelId) {
  $$(".tab-button").forEach((button) => {
    button.classList.toggle("active", button.dataset.panel === panelId);
  });
  $$(".panel").forEach((panel) => {
    panel.classList.toggle("active", panel.id === panelId);
  });
  updatePromptPreview();
}

function renderAll() {
  renderOwnerBranding();
  renderSenderOptions();
  renderAccounts();
  renderBrands();
  renderProfileInputs();
  renderSettings();
  renderAccessPlan();
  renderFollowups();
  renderCalendar();
  updateDecisionPreview();
}

function renderOwnerBranding() {
  const fullName = getOwnerFullName();
  $("#appTitle").textContent = state.owner.appName || `${fullName} Desk`;
  $("#brandMark").textContent = initialsForName(fullName);
  document.title = state.owner.appName || "Mail Reply Desk";
}

function renderSenderOptions() {
  const select = $("#senderNameSelect");
  if (!select) return;
  const selected = select.value;
  const options = [
    { value: "auto", label: "Auto" },
    { value: getOwnerFullName(), label: getOwnerFullName() },
    { value: state.owner.formalSender, label: state.owner.formalSender },
    { value: state.owner.casualSender, label: state.owner.casualSender }
  ].filter((option, index, array) => option.value && array.findIndex((item) => item.value === option.value) === index);
  select.innerHTML = options
    .map((option) => `<option value="${escapeAttribute(option.value)}">${escapeHtml(option.label)}</option>`)
    .join("");
  select.value = options.some((option) => option.value === selected) ? selected : "auto";
}

function renderAccounts() {
  const visibleAccounts = getVisibleAccounts();
  const selects = ["#fromAccount"];
  selects.forEach((selector) => {
    const element = $(selector);
    const selected = element.value;
    element.innerHTML = visibleAccounts
      .map((account) => `<option value="${escapeHtml(account.email)}">${escapeHtml(account.label)} · ${escapeHtml(account.email)}</option>`)
      .join("");
    element.value = visibleAccounts.some((account) => account.email === selected)
      ? selected
      : visibleAccounts[0]?.email || "";
  });

  const accountList = $("#accountList");
  accountList.innerHTML = state.accounts
    .map((account, index) => {
      return `
        <article class="list-item ${account.active ? "" : "account-inactive"}" data-account-index="${index}">
          <div class="list-item-header">
            <strong>${escapeHtml(account.label)}</strong>
            <label class="switch-line">
              <input type="checkbox" data-account-active="${index}" ${account.active ? "checked" : ""}>
              Fokus
            </label>
          </div>
          <div class="pill-row">
            <span class="pill teal">${escapeHtml(account.email)}</span>
            <span class="pill gold">${escapeHtml(account.provider)}</span>
            <span class="pill coral">${escapeHtml(account.accessStatus)}</span>
            <span class="pill">${escapeHtml(account.defaultSender)}</span>
          </div>
          <div class="form-grid two">
            <label>Provider<input data-account-provider="${index}" value="${escapeAttribute(account.provider)}"></label>
            <label>Absendername
              <select data-account-sender="${index}">
                ${senderOptionsForAccount(account.defaultSender)}
              </select>
            </label>
          </div>
          <label>Signatur<textarea data-account-signature="${index}">${escapeHtml(account.signature)}</textarea></label>
        </article>
      `;
    })
    .join("");

  $$("[data-account-active]").forEach((input) => {
    input.addEventListener("change", () => {
      const index = Number(input.dataset.accountActive);
      state.accounts[index].active = input.checked;
      saveState();
      renderAccounts();
      renderAccessPlan();
      updatePromptPreview();
      updateDecisionPreview();
    });
  });

  $$("[data-account-provider]").forEach((input) => {
    input.addEventListener("input", () => {
      const index = Number(input.dataset.accountProvider);
      state.accounts[index].provider = input.value;
      saveState();
      renderAccessPlan();
      updateDecisionPreview();
    });
  });

  $$("[data-account-sender]").forEach((input) => {
    input.addEventListener("input", () => {
      const index = Number(input.dataset.accountSender);
      state.accounts[index].defaultSender = input.value;
      saveState();
      renderAccounts();
      updatePromptPreview();
      updateDecisionPreview();
    });
  });

  $$("[data-account-signature]").forEach((input) => {
    input.addEventListener("input", () => {
      const index = Number(input.dataset.accountSignature);
      state.accounts[index].signature = input.value;
      saveState();
      updatePromptPreview();
      updateDecisionPreview();
    });
  });
}

function renderBrands() {
  const options = state.brands
    .map((brand) => `<option value="${escapeHtml(brand.id)}">${escapeHtml(brand.name)}</option>`)
    .join("");
  ["#brandSelect", "#contentBrandSelect"].forEach((selector) => {
    const element = $(selector);
    const selected = element.value;
    element.innerHTML = options;
    element.value = selected || state.brands[0]?.id || "";
  });

  const brandList = $("#brandList");
  brandList.innerHTML = state.brands
    .map((brand, index) => {
      return `
        <article class="list-item" data-brand-index="${index}">
          <div class="list-item-header">
            <strong>${escapeHtml(brand.name)}</strong>
            <button type="button" data-remove-brand="${index}">Entfernen</button>
          </div>
          <div class="form-grid two">
            <label>Name<input data-brand-field="name" data-brand-index="${index}" value="${escapeAttribute(brand.name)}"></label>
            <label>Zielgruppe<input data-brand-field="audience" data-brand-index="${index}" value="${escapeAttribute(brand.audience)}"></label>
          </div>
          <label>Ton<textarea data-brand-field="tone" data-brand-index="${index}">${escapeHtml(brand.tone)}</textarea></label>
          <label>No-Gos<textarea data-brand-field="noGos" data-brand-index="${index}">${escapeHtml(brand.noGos)}</textarea></label>
        </article>
      `;
    })
    .join("");

  $$("[data-brand-field]").forEach((input) => {
    input.addEventListener("input", () => {
      const index = Number(input.dataset.brandIndex);
      const field = input.dataset.brandField;
      state.brands[index][field] = input.value;
      saveState();
      renderBrandSelectsOnly();
      updatePromptPreview();
    });
  });

  $$("[data-remove-brand]").forEach((button) => {
    button.addEventListener("click", () => {
      if (state.brands.length <= 1) {
        showToast("Mindestens ein Brand-Profil bleibt aktiv");
        return;
      }
      state.brands.splice(Number(button.dataset.removeBrand), 1);
      saveState();
      renderBrands();
      updatePromptPreview();
    });
  });
}

function renderBrandSelectsOnly() {
  const currentBrand = $("#brandSelect").value;
  const currentContentBrand = $("#contentBrandSelect").value;
  const options = state.brands
    .map((brand) => `<option value="${escapeHtml(brand.id)}">${escapeHtml(brand.name)}</option>`)
    .join("");
  $("#brandSelect").innerHTML = options;
  $("#contentBrandSelect").innerHTML = options;
  $("#brandSelect").value = currentBrand;
  $("#contentBrandSelect").value = currentContentBrand;
}

function renderProfileInputs() {
  $("#ownerFirstName").value = state.owner.firstName;
  $("#ownerLastName").value = state.owner.lastName;
  $("#ownerGender").value = state.owner.gender;
  $("#ownerAppName").value = state.owner.appName;
  $("#ownerFormalSender").value = state.owner.formalSender;
  $("#ownerCasualSender").value = state.owner.casualSender;
  $("#ownerRoleTitle").value = state.owner.roleTitle;
  $("#ownerNiche").value = state.owner.niche;
  $("#ownerServices").value = state.owner.services;
  $("#ownerMediaKitUrl").value = state.owner.mediaKitUrl;
  $("#ownerSocialLinks").value = state.owner.socialLinks;
  $("#ownerRateCardNote").value = state.owner.rateCardNote;
  $("#ownerUsageRightsPolicy").value = state.owner.usageRightsPolicy;
  $("#ownerBriefingChecklist").value = state.owner.briefingChecklist;
  $("#ownerBrandSafetyNoGos").value = state.owner.brandSafetyNoGos;
  $("#styleVoice").value = state.style.voice;
  $("#styleRules").value = state.style.rules;
  $("#styleSignature").value = state.style.signature;
}

function renderSettings() {
  $("#apiMode").value = state.settings.apiMode;
  $("#backendUrl").value = state.settings.backendUrl;
  $("#gmailBackendUrl").value = state.settings.gmailBackendUrl || DEFAULT_STATE.settings.gmailBackendUrl;
  $("#gmailQuery").value = state.settings.gmailQuery || defaultGmailQuery();
  $("#allowedMailOnly").checked = state.settings.allowedMailOnly;
  $("#primaryCalendar").value = state.settings.primaryCalendar;
  $("#calendarMode").value = state.settings.calendarMode;
  $("#aiModeBadge").textContent = state.settings.apiMode === "backend" ? "Backend" : "Lokal";
}

function renderAccessPlan() {
  const container = $("#accessList");
  if (!container) return;
  const activeAccounts = getVisibleAccounts();
  const rows = [
    ...activeAccounts.map((account) => ({
      key: account.email,
      title: account.email,
      provider: account.provider,
      status: account.accessStatus,
      action: accessActionForProvider(account.provider, account.email)
    })),
    {
      key: "icloud-calendar",
      title: "Primärer Kalender",
      provider: calendarLabel(state.settings.primaryCalendar),
      status: state.settings.calendarMode === "ics-first" ? "ICS zuerst" : "direkt nach Bestätigung",
      action: calendarAccessAction(state.settings.primaryCalendar)
    }
  ];

  container.innerHTML = rows.map((row, index) => {
    return `
      <article class="list-item">
        <div class="list-item-header">
          <strong>${escapeHtml(row.title)}</strong>
          <button type="button" data-access-index="${index}">Anleitung</button>
        </div>
        <div class="pill-row">
          <span class="pill teal">${escapeHtml(row.provider)}</span>
          <span class="pill coral">${escapeHtml(row.status)}</span>
        </div>
        <div>${escapeHtml(row.action.short)}</div>
      </article>
    `;
  }).join("");

  $$("[data-access-index]").forEach((button) => {
    button.addEventListener("click", () => {
      const row = rows[Number(button.dataset.accessIndex)];
      setDraft(row.action.long, `Zugriff: ${row.title}`);
    });
  });
}

function getVisibleAccounts() {
  if (!state.settings.allowedMailOnly) return state.accounts;
  const active = state.accounts.filter((account) => account.active);
  return active.length ? active : state.accounts;
}

function accessActionForProvider(provider, email) {
  const lower = provider.toLowerCase();
  if (lower.includes("gmail") || lower.includes("google")) {
    return {
      short: "Backend: Gmail OAuth Read-Only vorbereiten. Keine Senderechte.",
      long: [
        `Zugriff für ${email}`,
        "",
        "Benötigt wird ein Google-OAuth-Login mit Gmail Read-Only.",
        "Ziel: Threads lesen, passende Mail erkennen, 3 Antwortentwürfe vorbereiten.",
        "Nicht anfordern: automatische Senderechte.",
        "",
        "Umsetzung im Backend:",
        "- Konto als freigegebenes Linda-Konto speichern",
        "- OAuth-Token verschlüsselt speichern",
        "- nur Messages/Threads lesen",
        "- nur Entwürfe zurückgeben"
      ].join("\n")
    };
  }
  if (lower.includes("icloud")) {
    return {
      short: "Backend: iCloud IMAP mit app-spezifischem Passwort vorbereiten.",
      long: [
        `Zugriff für ${email}`,
        "",
        "Benötigt wird ein app-spezifisches Apple-Passwort für iCloud Mail.",
        "Dieses Passwort nicht im Chat teilen. Es gehört später in eine gesicherte Setup-Seite.",
        "",
        "Ziel: iCloud Mail lesen, Threads erkennen, Entwürfe vorbereiten.",
        "Nicht anfordern: automatisches Senden."
      ].join("\n")
    };
  }
  return {
    short: "Provider zuerst klären, dann Read-Only Mailzugriff vorbereiten.",
    long: [
      `Zugriff für ${email}`,
      "",
      "Provider ist noch offen. Vor der Integration muss geklärt werden, ob das Konto über Google Workspace, Microsoft 365 oder IMAP läuft.",
      "",
      "Danach nur Leserechte einrichten. Keine automatischen Senderechte."
    ].join("\n")
  };
}

function calendarLabel(value) {
  const labels = {
    icloud: "iCloud Kalender",
    google: "Google Kalender",
    microsoft: "Microsoft Kalender",
    manual: "Nur ICS-Datei"
  };
  return labels[value] || "iCloud Kalender";
}

function calendarAccessAction(value) {
  if (value === "icloud") {
    return {
      short: "iCloud ist primär: erst ICS, später CalDAV mit app-spezifischem Passwort.",
      long: [
        "Zugriff für iCloud Kalender",
        "",
        "Aktueller sinnvoller Modus: ICS-Datei erzeugen und Linda bestätigt den Kalendertermin.",
        "Für echte Verfügbarkeitsprüfung oder direktes Eintragen braucht das Backend iCloud CalDAV.",
        "",
        "Benötigt später:",
        "- Apple-ID von Linda",
        "- app-spezifisches Passwort",
        "- Auswahl des richtigen iCloud-Kalenders",
        "",
        "Nicht im Chat teilen. Nur in einer gesicherten Setup-Seite eingeben."
      ].join("\n")
    };
  }
  return {
    short: "Kalenderzugriff erst nach Bestätigung einrichten.",
    long: "Kalenderzugriff wird erst eingerichtet, wenn Linda diesen Kalender wirklich als primär bestätigt."
  };
}

function renderFollowups() {
  const container = $("#followupList");
  if (!state.followups.length) {
    container.innerHTML = `<div class="summary-box">Keine Follow-ups</div>`;
    return;
  }
  container.innerHTML = state.followups
    .map((item, index) => {
      return `
        <article class="list-item">
          <div class="list-item-header">
            <strong>${escapeHtml(item.date)}</strong>
            <button type="button" data-remove-followup="${index}">Entfernen</button>
          </div>
          <div>${escapeHtml(item.subject)}</div>
          <div class="pill-row">
            <span class="pill teal">${escapeHtml(item.account)}</span>
            <span class="pill gold">${escapeHtml(item.recipient || "Kontakt")}</span>
          </div>
        </article>
      `;
    })
    .join("");

  $$("[data-remove-followup]").forEach((button) => {
    button.addEventListener("click", () => {
      state.followups.splice(Number(button.dataset.removeFollowup), 1);
      saveState();
      renderFollowups();
    });
  });
}

function renderCalendar() {
  const rows = $("#calendarRows");
  if (!state.calendar.length) {
    rows.innerHTML = `<tr><td colspan="5">Kein Plan</td></tr>`;
    return;
  }
  rows.innerHTML = state.calendar
    .map((row) => {
      return `
        <tr>
          <td>${escapeHtml(row.date)}</td>
          <td>${escapeHtml(row.channel)}</td>
          <td>${escapeHtml(row.format)}</td>
          <td>${escapeHtml(row.topic)}</td>
          <td>${escapeHtml(row.hook)}</td>
        </tr>
      `;
    })
    .join("");
}

function syncSettingsFromInputs() {
  state.settings.apiMode = $("#apiMode").value;
  state.settings.backendUrl = $("#backendUrl").value.trim();
  state.settings.gmailBackendUrl = normalizeBaseUrl($("#gmailBackendUrl").value.trim() || DEFAULT_STATE.settings.gmailBackendUrl);
  state.settings.gmailQuery = $("#gmailQuery").value.trim() || defaultGmailQuery();
  state.settings.allowedMailOnly = $("#allowedMailOnly").checked;
  state.settings.primaryCalendar = $("#primaryCalendar").value;
  state.settings.calendarMode = $("#calendarMode").value;
  $("#aiModeBadge").textContent = state.settings.apiMode === "backend" ? "Backend" : "Lokal";
  saveState();
}

function saveProfiles() {
  state.owner.firstName = $("#ownerFirstName").value.trim() || state.owner.firstName;
  state.owner.lastName = $("#ownerLastName").value.trim() || state.owner.lastName;
  state.owner.gender = $("#ownerGender").value;
  state.owner.appName = $("#ownerAppName").value.trim() || `${getOwnerFullName()} Desk`;
  state.owner.formalSender = $("#ownerFormalSender").value.trim() || defaultFormalSender(state.owner);
  state.owner.casualSender = $("#ownerCasualSender").value.trim() || state.owner.firstName;
  state.owner.roleTitle = $("#ownerRoleTitle").value.trim();
  state.owner.niche = $("#ownerNiche").value.trim();
  state.owner.services = $("#ownerServices").value.trim();
  state.owner.mediaKitUrl = $("#ownerMediaKitUrl").value.trim();
  state.owner.socialLinks = $("#ownerSocialLinks").value.trim();
  state.owner.rateCardNote = $("#ownerRateCardNote").value.trim();
  state.owner.usageRightsPolicy = $("#ownerUsageRightsPolicy").value.trim();
  state.owner.briefingChecklist = $("#ownerBriefingChecklist").value.trim();
  state.owner.brandSafetyNoGos = $("#ownerBrandSafetyNoGos").value.trim();
  state.style.voice = $("#styleVoice").value.trim();
  state.style.rules = $("#styleRules").value.trim();
  state.style.signature = $("#styleSignature").value.trim();
  state.accounts = state.accounts.map((account) => ({
    ...account,
    defaultSender: normalizeAccountSender(account.defaultSender),
    signature: normalizeLegacySignature(account.signature, account)
  }));
  saveState();
  renderOwnerBranding();
  renderSenderOptions();
  renderAccounts();
  updatePromptPreview();
  showToast("Profile gespeichert");
}

function addBrandProfile() {
  const id = `brand-${Date.now()}`;
  state.brands.push({
    id,
    name: "Neuer Brand",
    tone: "klar, hochwertig, passend zur Zielgruppe",
    audience: "Zielgruppe ergänzen",
    noGos: "keine unbestätigten Aussagen"
  });
  saveState();
  renderBrands();
}

function addAccount() {
  const email = $("#newAccountEmail").value.trim();
  const label = $("#newAccountLabel").value.trim() || email.split("@")[0] || "Konto";
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    showToast("Gültige Mailadresse eintragen");
    return;
  }
  state.accounts.push({
    email,
    label,
    provider: inferProvider(email),
    accessStatus: "nicht verbunden",
    active: true,
    defaultSender: inferDefaultSender(email),
    signature: defaultSignatureForOwner({ email })
  });
  $("#newAccountEmail").value = "";
  $("#newAccountLabel").value = "";
  saveState();
  renderAccounts();
  renderAccessPlan();
  updatePromptPreview();
}

async function checkGmailStatus() {
  syncSettingsFromInputs();
  setMailInboxStatus("Status wird geprüft");
  try {
    const status = await fetchGmailJSON("/gmail/status");
    updateGmailAccessStatus(status.connected);
    setMailInboxStatus(status.message || (status.connected ? "Gmail Read-only verbunden" : "Gmail nicht verbunden"));
    showToast(status.connected ? "Gmail verbunden" : "Gmail noch nicht verbunden");
    return status;
  } catch (error) {
    setMailInboxStatus("Backend nicht erreichbar");
    showToast("Gmail-Backend nicht erreichbar");
    return null;
  }
}

function connectGmail() {
  syncSettingsFromInputs();
  const url = `${gmailBackendBaseUrl()}/auth/google`;
  const opened = window.open(url, "_blank", "noopener");
  setMailInboxStatus("Google Login geöffnet");
  if (!opened) {
    window.location.href = url;
  }
}

async function loadGmailMessages() {
  syncSettingsFromInputs();
  setMailInboxStatus("Mails werden geladen");
  try {
    const query = $("#gmailQuery").value.trim() || defaultGmailQuery();
    const data = await fetchGmailJSON(`/gmail/messages?max=12&q=${encodeURIComponent(query)}`);
    gmailMessages = data.messages || [];
    selectedGmailThreadId = "";
    renderGmailInbox();
    setMailInboxStatus(`${gmailMessages.length} Mail${gmailMessages.length === 1 ? "" : "s"} geladen`);
    if (!gmailMessages.length) showToast("Keine passenden Mails gefunden");
  } catch (error) {
    renderGmailInbox(error instanceof Error ? error.message : String(error));
    setMailInboxStatus("Mails konnten nicht geladen werden");
    showToast("Gmail prüfen: Login oder Backend fehlt");
  }
}

async function importGmailThread(index) {
  const item = gmailMessages[index];
  if (!item?.threadId) return;
  selectedGmailThreadId = item.threadId;
  renderGmailInbox();
  setMailInboxStatus("Thread wird übernommen");

  try {
    const thread = await fetchGmailJSON(`/gmail/threads/${encodeURIComponent(item.threadId)}`);
    applyGmailThreadToReply(thread);
    const context = collectReplyContext();
    const suggestions = buildWorkflowSuggestions(context);
    renderSuggestions(suggestions, 0);
    setDraft(suggestions[0].text, "Gmail-Thread übernommen");
    activeCalendarEvent = suggestions[0].event || null;
    setMailInboxStatus("Thread übernommen, 3 Entwürfe erstellt");
  } catch (error) {
    setMailInboxStatus("Thread konnte nicht geladen werden");
    showToast("Thread konnte nicht geladen werden");
  }
}

function renderGmailInbox(errorMessage = "") {
  const container = $("#gmailInboxList");
  if (!container) return;
  if (errorMessage) {
    container.innerHTML = `<div class="summary-box compact">${escapeHtml(errorMessage)}</div>`;
    return;
  }
  if (!gmailMessages.length) {
    container.innerHTML = `<div class="summary-box compact">Nach Login werden hier die letzten passenden Mails angezeigt.</div>`;
    return;
  }

  container.innerHTML = gmailMessages.map((message, index) => {
    const from = parseEmailAddress(message.from);
    const active = selectedGmailThreadId === message.threadId ? "active" : "";
    return `
      <button class="mail-card ${active}" type="button" data-gmail-index="${index}">
        <strong>${escapeHtml(message.subject || "(Ohne Betreff)")}</strong>
        <span>${escapeHtml(from.name || from.email || message.from || "Unbekannt")} · ${escapeHtml(formatMailDate(message.date))}</span>
        <p>${escapeHtml(message.snippet || "")}</p>
      </button>
    `;
  }).join("");

  $$("[data-gmail-index]").forEach((button) => {
    button.addEventListener("click", () => importGmailThread(Number(button.dataset.gmailIndex)));
  });
}

function applyGmailThreadToReply(thread) {
  const messages = thread.messages || [];
  const contextText = thread.contextText || formatMessagesAsContext(messages);
  const replyTarget = findLastExternalMessage(messages) || thread.latest || messages[messages.length - 1] || {};
  const account = findAccountForGmailThread(messages);
  const sender = parseEmailAddress(replyTarget.from || "");

  activatePanel("replyPanel");
  setWorkflowMode("reply");
  setSelectValue("#fromAccount", account?.email || getVisibleAccounts()[0]?.email || "");
  setSelectValue("#channelSelect", "E-Mail");
  setSelectValue("#relationshipSelect", "auto");
  setSelectValue("#senderNameSelect", "auto");
  setSelectValue("#toneSelect", isCreatorLikeText(contextText) ? "verbindlich" : "freundlich");
  $("#recipientName").value = sender.name || sender.email || "";
  $("#replyGoal").value = replyTarget.subject ? `Antwort auf: ${replyTarget.subject}` : "Antwort vorbereiten";
  $("#threadInput").value = contextText;

  if (!$("#keywordInput").value.trim()) {
    $("#keywordInput").value = deriveReplyKeywords(contextText).join("\n");
  }

  updatePromptPreview();
  updateSummary(true);
  updateDecisionPreview();
}

function fetchGmailJSON(path) {
  return fetch(`${gmailBackendBaseUrl()}${path}`, {
    method: "GET",
    headers: { Accept: "application/json" }
  }).then(async (response) => {
    const data = await response.json().catch(() => ({}));
    if (!response.ok) {
      throw new Error(data.message || data.error || `HTTP ${response.status}`);
    }
    return data;
  });
}

function gmailBackendBaseUrl() {
  return normalizeBaseUrl(state.settings.gmailBackendUrl || DEFAULT_STATE.settings.gmailBackendUrl);
}

function normalizeBaseUrl(value) {
  return String(value || "").trim().replace(/\/+$/, "");
}

function defaultGmailQuery() {
  const account = getVisibleAccounts().find((item) => item.email === "info@jonnyandlinda.com") || getVisibleAccounts()[0];
  return account?.email ? `to:${account.email} newer_than:30d` : "newer_than:30d";
}

function setMailInboxStatus(text) {
  const element = $("#gmailStatusText");
  if (element) element.textContent = text;
}

function updateGmailAccessStatus(connected) {
  state.accounts = state.accounts.map((account) => {
    const provider = account.provider.toLowerCase();
    if (!provider.includes("gmail") && !provider.includes("google")) return account;
    return {
      ...account,
      accessStatus: connected ? "read-only verbunden" : account.accessStatus
    };
  });
  saveState();
  renderAccounts();
  renderAccessPlan();
}

function findAccountForGmailThread(messages) {
  const allRecipients = messages.map((message) => `${message.to || ""} ${message.from || ""}`).join(" ").toLowerCase();
  return getVisibleAccounts().find((account) => allRecipients.includes(account.email.toLowerCase())) || getVisibleAccounts()[0];
}

function findLastExternalMessage(messages) {
  const accountEmails = state.accounts.map((account) => account.email.toLowerCase());
  return [...messages].reverse().find((message) => {
    const from = parseEmailAddress(message.from || "").email.toLowerCase();
    return from && !accountEmails.includes(from);
  });
}

function formatMessagesAsContext(messages) {
  return messages.map((message) => [
    `From: ${message.from || ""}`,
    `To: ${message.to || ""}`,
    `Date: ${message.date || ""}`,
    `Subject: ${message.subject || ""}`,
    "",
    message.body || message.snippet || ""
  ].join("\n")).join("\n\n---\n\n");
}

function deriveReplyKeywords(text) {
  const questions = extractQuestions(text).slice(0, 3).map((item) => `Offene Frage: ${item}`);
  const dates = extractDateLike(text).slice(0, 3).map((item) => `Termin/Timing klären: ${item}`);
  const amounts = extractAmounts(text).slice(0, 3).map((item) => `Budget/Preis einordnen: ${item}`);
  const base = [];
  if (isCreatorLikeText(text)) {
    base.push("Briefingdaten prüfen", "Budgetrahmen klären", "Nutzungsrechte/Laufzeit klären");
  }
  return [...questions, ...dates, ...amounts, ...base].slice(0, 8);
}

function isCreatorLikeText(text) {
  const lower = text.toLowerCase();
  return containsAny(lower, [
    "kooperation",
    "collab",
    "kampagne",
    "creator",
    "influencer",
    "ugc",
    "reel",
    "story",
    "shooting",
    "media kit",
    "nutzungsrechte",
    "whitelisting",
    "paid usage"
  ]);
}

function parseEmailAddress(value) {
  const raw = String(value || "");
  const emailMatch = raw.match(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/i);
  const email = emailMatch ? emailMatch[0] : "";
  const name = cleanupName(raw.replace(email, "").replace(/\([^)]*\)/g, ""));
  return { name, email };
}

function formatMailDate(value) {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value || "";
  return date.toLocaleString("de-AT", {
    day: "2-digit",
    month: "2-digit",
    hour: "2-digit",
    minute: "2-digit"
  });
}

function setSelectValue(selector, value) {
  const element = $(selector);
  if (!element) return;
  const hasOption = Array.from(element.options || []).some((option) => option.value === value);
  if (hasOption) element.value = value;
}

async function handleToolbarAction(action) {
  syncSettingsFromInputs();
  if (action === "translate") {
    state.settings.targetLanguage = state.settings.targetLanguage === "de" ? "en" : "de";
    saveState();
  }

  const operation = action === "reply" ? "reply" : action;
  const backendText = await runBackendIfEnabled(operation);
  if (backendText) {
    setDraft(backendText, labelForAction(action));
    return;
  }

  const context = collectReplyContext();
  const current = $("#outputText").value.trim();
  if (action === "reply") {
    const suggestions = buildWorkflowSuggestions(context);
    renderSuggestions(suggestions, 0);
    setDraft(suggestions[0].text, `Vorschlag 1 ausgewählt`);
    activeCalendarEvent = suggestions[0].event || null;
    return;
  }

  if (["briefing", "pricing", "followup"].includes(action)) {
    const generated = buildCreatorActionDraft(action, context);
    setDraft(generated, labelForAction(action));
    return;
  }

  const generated = transformDraft(action, current || buildEmailReply(context), context);
  setDraft(generated, labelForAction(action));
}

async function generateContent() {
  syncSettingsFromInputs();
  const type = $("#contentType").value;
  const backendText = await runBackendIfEnabled(type);
  if (backendText) {
    setDraft(backendText, labelForContentType(type));
    return;
  }

  const context = collectContentContext();
  const text = buildContentOutput(context);
  setDraft(text, labelForContentType(type));
}

async function runBackendIfEnabled(operation) {
  if (state.settings.apiMode !== "backend" || !state.settings.backendUrl) return "";
  const prompt = buildPrompt(operation);
  const context = getActiveContext(operation);

  try {
    $("#draftMeta").textContent = "Backend läuft";
    const response = await fetch(state.settings.backendUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ operation, prompt, context })
    });
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }
    const data = await response.json();
    return data.text || data.output || data.answer || data.message?.content || "";
  } catch (error) {
    $("#draftMeta").textContent = "Backend nicht erreichbar";
    showToast("Backend nicht erreichbar, lokaler Entwurf verwendet");
    return "";
  }
}

function collectReplyContext() {
  const account = state.accounts.find((item) => item.email === $("#fromAccount").value) || state.accounts[0];
  const brand = state.brands.find((item) => item.id === $("#brandSelect").value) || state.brands[0];
  const thread = $("#threadInput").value.trim();
  const parsed = parseMailThread(thread);
  const channel = $("#channelSelect").value;
  const relationship = resolveRelationship($("#relationshipSelect").value, thread, channel);
  const senderName = resolveSenderName($("#senderNameSelect").value, account);
  const recipient = $("#recipientName").value.trim() || parsed.senderName || "";

  return {
    account,
    brand,
    thread,
    parsed,
    relationship,
    senderName,
    recipient,
    channel,
    tone: $("#toneSelect").value,
    goal: $("#replyGoal").value.trim(),
    keywords: splitItems($("#keywordInput").value),
    targetLanguage: state.settings.targetLanguage,
    workflowMode,
    event: {
      title: $("#eventTitle").value.trim(),
      attendees: splitItems($("#eventAttendees").value),
      date: $("#eventDate").value,
      time: $("#eventTime").value,
      durationMinutes: Number($("#eventDuration").value || 30),
      location: $("#eventLocation").value.trim()
    }
  };
}

function collectContentContext() {
  const brand = state.brands.find((item) => item.id === $("#contentBrandSelect").value) || state.brands[0];
  return {
    type: $("#contentType").value,
    channel: $("#contentChannel").value,
    brand,
    topic: $("#contentTopic").value.trim(),
    details: $("#contentDetails").value.trim(),
    cta: $("#contentCta").value.trim(),
    targetLanguage: state.settings.targetLanguage
  };
}

function getActiveContext(operation) {
  if (["caption", "hooks", "hashtags", "offer", "briefing", "cancellation"].includes(operation)) {
    return collectContentContext();
  }
  return collectReplyContext();
}

function buildEmailReply(context) {
  if (isChatContext(context)) return buildChatReply(context);

  const isEnglish = context.targetLanguage === "en";
  const greeting = makeGreeting(context, isEnglish);
  const signoff = makeSignature(context, isEnglish);
  const answerParagraphs = makeAnswerParagraphs(context, isEnglish);
  const goalSentence = context.goal && !isCreatorCollaborationContext(context)
    ? makeGoalSentence(context.goal, context.relationship, isEnglish)
    : "";
  const threadAwareLine = makeThreadAwareLine(context, isEnglish);

  const paragraphs = [
    greeting,
    threadAwareLine,
    openerByTone(context.tone, context.relationship, isEnglish),
    goalSentence,
    ...answerParagraphs,
    closeByTone(context.tone, context.relationship, isEnglish),
    signoff
  ].filter(Boolean);

  return cleanupDraft(paragraphs.join("\n\n"));
}

function buildChatReply(context) {
  const isEnglish = context.targetLanguage === "en";
  const text = `${context.thread} ${context.goal} ${context.keywords.join(" ")}`.toLowerCase();
  const keywordLine = makeChatKeywordLine(context.keywords);

  if (isEnglish) {
    if (containsAny(text, ["sorry", "apolog", "late"])) return "No worries, thanks for letting me know.";
    if (containsAny(text, ["thank", "thanks"])) return "Of course, happy to help. Let me know if anything else is open.";
    if (containsAny(text, ["meet", "coffee", "dinner", "time", "free"])) return keywordLine ? `Sounds good. ${keywordLine}` : "Sounds good. Send me when and where, and I will check what works.";
    if (looksLikeDecisionQuestion(text)) return keywordLine ? `Yes, that should work. ${keywordLine}` : "Yes, that should work. Send me the key details.";
    if (keywordLine) return cleanupDraft(`Thanks, I saw it. ${keywordLine} I will get back to you shortly.`);
    return "Thanks, I saw it. I will get back to you shortly.";
  }

  if (containsAny(text, ["sorry", "entschuldigung", "tut mir leid"])) return "Alles gut, danke fürs Bescheid geben. Mach dir keinen Stress.";
  if (containsAny(text, ["danke", "vielen dank"])) return "Sehr gerne, freut mich. Gib mir kurz Bescheid, falls noch etwas offen ist.";
  if (containsAny(text, ["treffen", "kaffee", "essen", "zeit", "kommst du", "lust"])) {
    return keywordLine ? `Klingt gut. ${keywordLine}` : "Klingt gut. Sag mir bitte kurz wann und wo, dann schaue ich, wie es sich ausgeht.";
  }
  if (looksLikeDecisionQuestion(text)) {
    return keywordLine ? `Ja, passt grundsätzlich. ${keywordLine}` : "Ja, passt grundsätzlich. Schick mir bitte kurz die wichtigsten Details.";
  }
  if (keywordLine) return cleanupDraft(`Danke dir, ich habe es gesehen. ${keywordLine} Ich melde mich gleich dazu.`);
  return "Danke dir, ich habe es gesehen. Ich melde mich gleich dazu.";
}

function makeChatKeywordLine(keywords) {
  return keywords
    .slice(0, 3)
    .map((item) => stripKeywordLabel(item))
    .filter(Boolean)
    .map((item) => `${capitalizeSentence(item)}.`)
    .join(" ");
}

function buildCreatorActionDraft(action, context) {
  const focusByAction = {
    briefing: "briefing",
    pricing: "pricing",
    followup: "followup"
  };
  const variantContext = {
    ...context,
    creatorFocus: focusByAction[action] || "briefing",
    tone: action === "pricing" ? "verbindlich" : context.tone,
    goal: action === "briefing"
      ? "Briefingdetails klären"
      : action === "pricing"
        ? "Budget, Nutzungsrechte und Scope klären"
        : "freundlich nachfassen"
  };

  if (action === "followup") return buildCreatorFollowupMail(variantContext);
  return buildEmailReply(variantContext);
}

function buildWorkflowSuggestions(context) {
  if (context.workflowMode === "create") return buildNewMailSuggestions(context);
  if (context.workflowMode === "event") return buildEventSuggestions(context);
  return buildDraftSuggestions(context);
}

function buildDraftSuggestions(context) {
  const intent = inferMailIntent(context);
  const base = isChatContext(context)
    ? [
        {
          title: "Kurz antworten",
          tone: "kurz",
          relationship: "du",
          summary: "knapp, natürlich, ohne Mail-Grußformel"
        },
        {
          title: "Warm antworten",
          tone: "freundlich",
          relationship: "du",
          summary: "privat oder locker, aber klar"
        },
        {
          title: "Klar entscheiden",
          tone: "verbindlich",
          relationship: "du",
          summary: "Ja/Nein oder nächster Schritt eindeutig"
        }
      ]
    : isCreatorCollaborationContext(context)
    ? [
        {
          title: "Interesse + Briefing",
          tone: "freundlich",
          relationship: context.relationship,
          creatorFocus: "briefing",
          summary: "Anfrage positiv aufnehmen und fehlende Briefingdaten abfragen"
        },
        {
          title: "Budget & Rechte",
          tone: "verbindlich",
          relationship: context.relationship,
          creatorFocus: "pricing",
          summary: "Preis nur nach Scope, Nutzungsrechten und Laufzeit einordnen"
        },
        {
          title: "Kurz entscheiden",
          tone: "kurz",
          relationship: context.relationship,
          creatorFocus: "short",
          summary: "knapp sagen, welche Daten für eine Zusage fehlen"
        }
      ]
    : [
        {
          title: "Kurz & klar",
          tone: "kurz",
          relationship: context.relationship,
          summary: "direkt antworten, offene Punkte knapp klären"
        },
        {
          title: "Warm & freundlich",
          tone: "freundlich",
          relationship: context.relationship,
          summary: "nahbar antworten, Kooperation oder Anliegen positiv aufnehmen"
        },
        {
          title: "Verbindlich & professionell",
          tone: "verbindlich",
          relationship: "sie",
          summary: "formeller, sauber strukturiert, nächste Schritte eindeutig"
        }
      ];

  return base.map((variant, index) => {
    const variantContext = {
      ...context,
      tone: variant.tone,
      relationship: variant.relationship,
      creatorFocus: variant.creatorFocus
    };
    return {
      title: variant.title,
      intent,
      summary: variant.summary,
      bullets: buildSuggestionBullets(variantContext),
      text: buildEmailReply(variantContext),
      event: null,
      index
    };
  });
}

function buildNewMailSuggestions(context) {
  const base = [
    { title: "Kurz & klar", tone: "kurz", relationship: context.relationship, summary: "schnell auf den Punkt" },
    { title: "Warm & freundlich", tone: "freundlich", relationship: context.relationship, summary: "persönlich und angenehm" },
    { title: "Verbindlich & professionell", tone: "verbindlich", relationship: "sie", summary: "formell und entscheidungsreif" }
  ];

  return base.map((variant, index) => {
    const variantContext = { ...context, tone: variant.tone, relationship: variant.relationship };
    return {
      title: variant.title,
      intent: "Erkannt: neue Mail aus Stichworten",
      summary: variant.summary,
      bullets: buildSuggestionBullets(variantContext),
      text: buildNewEmail(variantContext),
      event: null,
      index
    };
  });
}

function buildEventSuggestions(context) {
  const event = inferCalendarEvent(context);
  const base = [
    { title: "Termin bestätigen", tone: "kurz", action: "confirm" },
    { title: "Termin vorschlagen", tone: "freundlich", action: "suggest" },
    { title: "Kalendereinladung", tone: "verbindlich", action: "invite" }
  ];

  return base.map((variant, index) => {
    const variantContext = { ...context, tone: variant.tone, event };
    return {
      title: variant.title,
      intent: "Erkannt: Kalendertermin / Abstimmung",
      summary: "Termintext plus ICS-Datei vorbereiten",
      bullets: buildEventBullets(event),
      text: buildEventMail(variantContext, variant.action),
      event,
      index
    };
  });
}

function renderSuggestions(suggestions, selectedIndex = 0) {
  activeSuggestions = suggestions;
  const container = $("#suggestionList");
  $("#suggestionMeta").textContent = `${suggestions.length} Richtungen erkannt`;
  container.innerHTML = suggestions.map((suggestion, index) => {
    return `
      <article class="suggestion-card ${index === selectedIndex ? "active" : ""}">
        <div class="list-item-header">
          <h4>${escapeHtml(suggestion.title)}</h4>
          <button type="button" data-select-suggestion="${index}">Auswählen</button>
        </div>
        <p>${escapeHtml(suggestion.intent)}</p>
        <p>${escapeHtml(suggestion.summary)}</p>
        <ul>
          ${suggestion.bullets.map((item) => `<li>${escapeHtml(item)}</li>`).join("")}
        </ul>
      </article>
    `;
  }).join("");

  $$("[data-select-suggestion]").forEach((button) => {
    button.addEventListener("click", () => {
      const index = Number(button.dataset.selectSuggestion);
      renderSuggestions(activeSuggestions, index);
      setDraft(activeSuggestions[index].text, `Vorschlag ${index + 1} ausgewählt`);
      activeCalendarEvent = activeSuggestions[index].event || null;
    });
  });
}

function buildNewEmail(context) {
  const isEnglish = context.targetLanguage === "en";
  const greeting = makeGreeting(context, isEnglish);
  const signoff = makeSignature(context, isEnglish);
  const topicLine = context.goal || context.parsed.subject || context.keywords[0] || "";
  const body = makeAnswerParagraphs(context, isEnglish);
  const opener = isEnglish
    ? `I am reaching out regarding ${topicLine || "the following topic"}.`
    : context.relationship === "sie"
      ? `ich melde mich wegen ${topicLine || "des folgenden Themas"}.`
      : `ich melde mich wegen ${topicLine || "des folgenden Themas"}.`;
  return cleanupDraft([
    greeting,
    opener,
    ...body,
    closeByTone(context.tone, context.relationship, isEnglish),
    signoff
  ].filter(Boolean).join("\n\n"));
}

function inferCalendarEvent(context) {
  const title = context.event.title || context.goal || context.parsed.subject || "Termin mit Linda";
  const attendeeFromThread = context.parsed.senderEmail ? [context.parsed.senderEmail] : [];
  return {
    title,
    attendees: context.event.attendees.length ? context.event.attendees : attendeeFromThread,
    date: context.event.date,
    time: context.event.time,
    durationMinutes: context.event.durationMinutes || 30,
    location: context.event.location,
    notes: [context.thread, context.keywords.join("\n")].filter(Boolean).join("\n\n")
  };
}

function buildEventMail(context, action) {
  const event = context.event;
  const isEnglish = context.targetLanguage === "en";
  const greeting = makeGreeting(context, isEnglish);
  const signoff = makeSignature(context, isEnglish);
  const when = formatEventWhen(event);
  const location = event.location ? `Ort/Link: ${event.location}.` : "Ort/Link kann ich noch ergänzen.";
  const attendeeLine = event.attendees.length ? `Teilnehmer: ${event.attendees.join(", ")}.` : "";

  let middle;
  if (action === "confirm") {
    middle = context.relationship === "sie"
      ? `ich bestätige Ihnen gerne den Termin: ${when}.`
      : `ich bestätige dir gerne den Termin: ${when}.`;
  } else if (action === "suggest") {
    middle = context.relationship === "sie"
      ? `ich kann Ihnen folgenden Termin anbieten: ${when}.`
      : `ich kann dir folgenden Termin anbieten: ${when}.`;
  } else {
    middle = context.relationship === "sie"
      ? `ich bereite Ihnen die Kalendereinladung für ${when} vor.`
      : `ich bereite dir die Kalendereinladung für ${when} vor.`;
  }

  return cleanupDraft([
    greeting,
    middle,
    location,
    attendeeLine,
    context.relationship === "sie" ? "Geben Sie mir gerne kurz Bescheid, ob das für Sie passt." : "Gib mir gerne kurz Bescheid, ob das für dich passt.",
    signoff
  ].filter(Boolean).join("\n\n"));
}

function buildEventBullets(event) {
  return [
    `Titel: ${event.title}`,
    `Zeit: ${formatEventWhen(event)}`,
    event.location ? `Ort: ${event.location}` : "Ort: offen",
    event.attendees.length ? `Teilnehmer: ${event.attendees.join(", ")}` : "Teilnehmer: offen"
  ];
}

function makeThreadAwareLine(context, isEnglish) {
  const subject = context.parsed.subject;
  if (!subject) return "";
  const lower = `${subject} ${context.thread}`.toLowerCase();
  if (isEnglish) {
    if (containsAny(lower, ["cooperation", "collab", "campaign", "reel", "story"])) {
      return `The request regarding "${subject}" sounds interesting in principle.`;
    }
    return `I reviewed the details regarding "${subject}".`;
  }
  if (containsAny(lower, ["kooperation", "kampagne", "reel", "story", "collab"])) {
    return context.relationship === "sie"
      ? `Ihre Anfrage zu "${subject}" klingt grundsätzlich interessant.`
      : `Die Anfrage zu "${subject}" klingt grundsätzlich spannend.`;
  }
  return context.relationship === "sie"
    ? `Ich habe mir die Details zu "${subject}" angesehen.`
    : `Ich habe mir die Details zu "${subject}" angeschaut.`;
}

function makeAnswerParagraphs(context, isEnglish) {
  const categories = categorizeKeywords(context.keywords);
  const paragraphs = [];
  const formal = context.relationship === "sie";
  const creatorParagraphs = makeCreatorCollaborationParagraphs(context, categories, isEnglish);

  if (!context.keywords.length) {
    return creatorParagraphs.length ? creatorParagraphs : [
      isEnglish
        ? "[Add the specific answer points, date, price or next step here.]"
        : "[Konkreten Antwortpunkt, Termin, Preis oder nächsten Schritt ergänzen.]"
    ];
  }

  paragraphs.push(...creatorParagraphs);

  if (isEnglish) {
    if (categories.questions.length) paragraphs.push(`Regarding the open question, I have noted: ${joinReadable(categories.questions)}. I will keep the next step clear and avoid making unconfirmed commitments.`);
    if (categories.appointment.length) paragraphs.push(`I can offer the following time option: ${joinReadable(categories.appointment)}.`);
    if (categories.budget.length) paragraphs.push(`Regarding pricing and budget: ${joinReadable(categories.budget)}.`);
    if (categories.nextStep.length) paragraphs.push(`For the next step, I need: ${joinReadable(categories.nextStep)}.`);
    if (categories.timing.length) paragraphs.push(`Timing/deadline: ${joinReadable(categories.timing)}.`);
    if (categories.deliverables.length) paragraphs.push(`Deliverables/assets: ${joinReadable(categories.deliverables)}.`);
    if (categories.usageRights.length) paragraphs.push(`Usage rights: ${joinReadable(categories.usageRights)}.`);
    if (categories.metrics.length) paragraphs.push(`Media kit / audience data: ${joinReadable(categories.metrics)}.`);
    if (categories.offer.length && !creatorParagraphs.length) paragraphs.push(`For the collaboration/offer, I will align the scope once the briefing is clear.`);
    if (categories.other.length) paragraphs.push(categories.other.map((item) => `${item}.`).join(" "));
    return paragraphs;
  }

  if (categories.questions.length) {
    paragraphs.push(formal
      ? `Zu Ihrer offenen Frage halte ich fest: ${joinReadable(categories.questions)}. Ich formuliere den nächsten Schritt klar, ohne unbestätigte Zusagen zu machen.`
      : `Zu deiner offenen Frage halte ich fest: ${joinReadable(categories.questions)}. Ich formuliere den nächsten Schritt klar, ohne etwas Unbestätigtes zuzusagen.`);
  }
  if (categories.appointment.length) {
    paragraphs.push(formal
      ? `Für einen Call kann ich Ihnen ${joinReadable(categories.appointment)} anbieten.`
      : `Für einen Call kann ich dir ${joinReadable(categories.appointment)} anbieten.`);
  }
  if (categories.budget.length) {
    paragraphs.push(formal
      ? `Zum Budget bzw. Preis kann ich Ihnen eine saubere Einschätzung geben, sobald das Briefing klar ist: ${joinReadable(categories.budget)}.`
      : `Zum Budget bzw. Preis kann ich dir eine saubere Einschätzung geben, sobald das Briefing klar ist: ${joinReadable(categories.budget)}.`);
  }
  if (categories.nextStep.length) {
    paragraphs.push(formal
      ? `Als nächsten Schritt brauche ich bitte noch ${joinReadable(categories.nextStep)}.`
      : `Als nächsten Schritt brauche ich bitte noch ${joinReadable(categories.nextStep)}.`);
  }
  if (categories.timing.length) {
    paragraphs.push(formal
      ? `Für das Timing halte ich fest: ${joinReadable(categories.timing)}.`
      : `Für das Timing halte ich fest: ${joinReadable(categories.timing)}.`);
  }
  if (categories.deliverables.length) {
    paragraphs.push(`Bei den Deliverables halte ich fest: ${joinReadable(categories.deliverables)}.`);
  }
  if (categories.usageRights.length) {
    paragraphs.push(`Zu den Nutzungsrechten halte ich fest: ${joinReadable(categories.usageRights)}.`);
  }
  if (categories.metrics.length) {
    paragraphs.push(`Zu Media Kit, Zielgruppe oder Insights halte ich fest: ${joinReadable(categories.metrics)}.`);
  }
  if (categories.offer.length && !categories.budget.length && !creatorParagraphs.length) {
    paragraphs.push(formal
      ? "Für das Angebot stimme ich Umfang, Formate und Nutzungsrechte gerne sauber mit Ihnen ab."
      : "Für das Angebot stimme ich Umfang, Formate und Nutzungsrechte gerne sauber mit dir ab.");
  }
  if (categories.other.length) {
    paragraphs.push(categories.other.map((item) => `${item}.`).join(" "));
  }

  return paragraphs;
}

function makeCreatorCollaborationParagraphs(context, categories, isEnglish) {
  if (!isCreatorCollaborationContext(context)) return [];
  const formal = context.relationship === "sie";
  const checklist = briefingChecklistItems();
  const topChecklist = checklist.slice(0, 6);
  const checklistText = joinReadable(topChecklist);
  const mediaKit = creatorMediaKitLine(isEnglish);
  const rightsPolicy = state.owner.usageRightsPolicy;
  const rateNote = state.owner.rateCardNote;
  const focus = context.creatorFocus || "briefing";

  if (isEnglish) {
    const intro = focus === "pricing"
      ? "For a serious pricing estimate, I need the exact scope first."
      : "The collaboration sounds interesting in principle.";
    return [
      intro,
      `For a clear assessment, please send the following details: ${checklistText}.`,
      focus === "pricing" && rateNote ? rateNote : "",
      rightsPolicy ? `Usage rights note: ${rightsPolicy}` : "",
      mediaKit
    ].filter(Boolean);
  }

  if (focus === "pricing") {
    return [
      formal
        ? "Für eine seriöse Preiseinschätzung brauche ich bitte zuerst den genauen Leistungsumfang."
        : "Für eine saubere Preiseinschätzung brauche ich bitte zuerst den genauen Leistungsumfang.",
      `Relevant sind vor allem: ${checklistText}.`,
      rateNote || "",
      rightsPolicy ? `Wichtig zu den Nutzungsrechten: ${rightsPolicy}` : "",
      mediaKit
    ].filter(Boolean);
  }

  if (focus === "short") {
    return [
      formal
        ? `Für eine Entscheidung brauche ich bitte noch ${checklistText}.`
        : `Für eine Entscheidung brauche ich bitte noch ${checklistText}.`,
      mediaKit
    ].filter(Boolean);
  }

  return [
    formal
      ? "Damit ich die Anfrage sauber prüfen kann, brauche ich bitte die wichtigsten Rahmendaten."
      : "Damit ich die Anfrage sauber prüfen kann, brauche ich bitte die wichtigsten Rahmendaten.",
    `Konkret wichtig sind: ${checklistText}.`,
    rightsPolicy ? `Zu den Nutzungsrechten: ${rightsPolicy}` : "",
    mediaKit
  ].filter(Boolean);
}

function buildCreatorFollowupMail(context) {
  const isEnglish = context.targetLanguage === "en";
  const greeting = makeGreeting(context, isEnglish);
  const signoff = makeSignature(context, isEnglish);
  const subject = context.parsed.subject || context.goal || "der Anfrage";
  const missing = joinReadable(briefingChecklistItems().slice(0, 5));
  const mediaKit = creatorMediaKitLine(isEnglish);
  const formal = context.relationship === "sie";
  const body = isEnglish
    ? [
        `I wanted to briefly follow up regarding ${subject}.`,
        `If the collaboration is still relevant, please send the missing details: ${missing}.`,
        mediaKit,
        "Then I can prepare a clean next step."
      ]
    : [
        formal
          ? `ich wollte wegen ${subject} kurz nachfragen.`
          : `ich wollte wegen ${subject} kurz nachfragen.`,
        formal
          ? `Wenn die Kooperation weiterhin relevant ist, senden Sie mir gerne noch die fehlenden Details: ${missing}.`
          : `Wenn die Kooperation weiterhin relevant ist, schick mir gerne noch die fehlenden Details: ${missing}.`,
        mediaKit,
        formal
          ? "Danach kann ich den nächsten Schritt sauber vorbereiten."
          : "Danach kann ich den nächsten Schritt sauber vorbereiten."
      ];
  return cleanupDraft([greeting, ...body.filter(Boolean), signoff].join("\n\n"));
}

function categorizeKeywords(keywords) {
  return keywords.reduce((categories, item) => {
    const normalized = item.toLowerCase();
    const detail = normalizeKeywordDetail(item);
    if (containsAny(normalized, ["offene frage", "frage:", "question:"]) || item.trim().endsWith("?")) categories.questions.push(detail);
    else if (containsAny(normalized, ["termin", "call", "meeting", "datum"])) categories.appointment.push(cleanAppointmentDetail(detail));
    else if (containsAny(normalized, ["preis", "kosten", "budget", "honorar", "paketpreis"])) categories.budget.push(detail);
    else if (containsAny(normalized, ["nächster schritt", "naechster schritt", "next step", "briefing", "kampagnenziel", "ziel der kampagne"])) categories.nextStep.push(detail);
    else if (containsAny(normalized, ["deadline", "frist", "bis", "timing"])) categories.timing.push(detail);
    else if (containsAny(normalized, ["deliverable", "asset", "assets", "reel", "story", "stories", "ugc", "posting", "post", "shooting", "format", "formate"])) categories.deliverables.push(detail);
    else if (containsAny(normalized, ["nutzungsrecht", "nutzungsrechte", "usage", "paid usage", "whitelisting", "spark ads", "exklusivität", "exklusivitaet", "laufzeit"])) categories.usageRights.push(detail);
    else if (containsAny(normalized, ["media kit", "mediakit", "insights", "reichweite", "zielgruppe", "audience", "follower", "stats", "analytics"])) categories.metrics.push(detail);
    else if (containsAny(normalized, ["angebot", "kooperation", "collab", "kampagne"])) categories.offer.push(detail);
    else categories.other.push(detail);
    return categories;
  }, {
    questions: [],
    appointment: [],
    budget: [],
    nextStep: [],
    timing: [],
    deliverables: [],
    usageRights: [],
    metrics: [],
    offer: [],
    other: []
  });
}

function inferMailIntent(context) {
  const text = `${context.parsed.subject} ${context.thread} ${context.keywords.join(" ")}`.toLowerCase();
  if (containsAny(text, ["kooperation", "collab", "kampagne", "reel", "story", "ugc", "influencer", "brand deal"])) {
    return "Erkannt: Kooperations- oder Kampagnenanfrage";
  }
  if (containsAny(text, ["preis", "kosten", "budget", "honorar", "angebot"])) {
    return "Erkannt: Preis-, Budget- oder Angebotsfrage";
  }
  if (containsAny(text, ["termin", "call", "meeting", "verfügbarkeit"])) {
    return "Erkannt: Termin- oder Abstimmungsfrage";
  }
  if (containsAny(text, ["rechnung", "zahlung", "invoice"])) {
    return "Erkannt: Rechnungs- oder Zahlungsthema";
  }
  if (containsAny(text, ["beschwerde", "problem", "leider", "reklamation"])) {
    return "Erkannt: sensibles Anliegen mit Klärungsbedarf";
  }
  return "Erkannt: allgemeine Antwort mit offenen Details";
}

function isCreatorCollaborationContext(context) {
  const text = [
    context.parsed?.subject,
    context.thread,
    context.goal,
    context.keywords?.join(" "),
    context.brand?.name
  ].filter(Boolean).join(" ").toLowerCase();
  return containsAny(text, [
    "kooperation",
    "collab",
    "campaign",
    "kampagne",
    "brand deal",
    "influencer",
    "creator",
    "ugc",
    "reel",
    "story",
    "stories",
    "shooting",
    "media kit",
    "mediakit",
    "nutzungsrechte",
    "whitelisting",
    "paid usage",
    "spark ads"
  ]);
}

function isChatContext(context) {
  const channel = String(context.channel || "").toLowerCase();
  if (channel.includes("whatsapp") || channel.includes("instagram dm")) return true;
  const text = `${context.thread || ""} ${context.goal || ""}`.toLowerCase();
  return containsAny(text, ["whatsapp", "wa chat", "insta dm", "direct message", "sms"]);
}

function looksLikeDecisionQuestion(text) {
  const source = ` ${String(text || "").toLowerCase()} `;
  return source.includes("?") && containsAny(source, [
    " passt ",
    " möglich ",
    " moeglich ",
    " geht das ",
    " kannst du ",
    " können sie ",
    " koennen sie ",
    " sollen wir ",
    " okay ",
    " ok ",
    " works ",
    " possible ",
    " can you ",
    " should we "
  ]);
}

function briefingChecklistItems() {
  const items = splitItems(state.owner.briefingChecklist);
  return items.length ? items : [
    "Kampagnenziel",
    "Deliverables",
    "Timing/Deadline",
    "Budgetrahmen",
    "Nutzungsrechte/Laufzeit",
    "Freigabeschleifen"
  ];
}

function creatorMediaKitLine(isEnglish = false) {
  const links = [state.owner.mediaKitUrl, state.owner.socialLinks]
    .map((item) => item?.trim())
    .filter(Boolean)
    .join("\n");
  if (!links) return "";
  return isEnglish ? `Media kit / links:\n${links}` : `Media Kit / Links:\n${links}`;
}

function buildSuggestionBullets(context) {
  const categories = categorizeKeywords(context.keywords);
  const bullets = [];
  const question = extractQuestions(context.thread)[0];
  if (question) bullets.push(`Frage: ${question}`);
  if (categories.questions.length) bullets.push(`Offen: ${joinReadable(categories.questions.slice(0, 2))}`);
  if (categories.appointment.length) bullets.push(`Termin: ${joinReadable(categories.appointment)}`);
  if (categories.budget.length) bullets.push(`Budget: ${joinReadable(categories.budget)}`);
  if (categories.nextStep.length) bullets.push(`Nächster Schritt: ${joinReadable(categories.nextStep)}`);
  if (categories.timing.length) bullets.push(`Timing: ${joinReadable(categories.timing)}`);
  if (categories.deliverables.length) bullets.push(`Deliverables: ${joinReadable(categories.deliverables)}`);
  if (categories.usageRights.length) bullets.push(`Nutzungsrechte: ${joinReadable(categories.usageRights)}`);
  if (categories.metrics.length) bullets.push(`Media Kit/Insights: ${joinReadable(categories.metrics)}`);
  if (isCreatorCollaborationContext(context)) {
    bullets.push(`Creator-Check: ${joinReadable(briefingChecklistItems().slice(0, 4))}`);
  }
  if (categories.other.length) bullets.push(`Zusatz: ${joinReadable(categories.other.slice(0, 2))}`);
  return bullets.length ? bullets.slice(0, 4) : ["Stichworte ergänzen oder Mailverlauf automatisch anbinden"];
}

function makeGreeting(context, isEnglish) {
  const name = context.recipient.trim();
  if (isEnglish) {
    if (context.relationship === "du") return `Hi ${firstName(name) || "there"},`;
    return name ? `Hello ${formalDisplayName(name)},` : "Hello,";
  }
  if (context.relationship === "du") return `Hallo ${firstName(name) || "zusammen"},`;
  return name ? `Guten Tag ${formalGreetingName(name)},` : "Guten Tag,";
}

function openerByTone(tone, relationship, isEnglish) {
  const formal = relationship === "sie";
  if (isEnglish) {
    const openers = {
      kurz: "Thanks for your message. Here are the key points.",
      luxurioes: "Thank you for your message. I would be happy to align the next steps carefully.",
      verbindlich: "Thank you for your message. I am confirming the current status and next steps below.",
      entschuldigend: "Thank you for your patience and your message.",
      freundlich: "Thank you for your message. I am happy to get back to you."
    };
    return openers[tone] || openers.freundlich;
  }
  const openers = {
    kurz: formal ? "Vielen Dank für Ihre Nachricht. Die wichtigsten Punkte:" : "Danke dir für die Nachricht. Die wichtigsten Punkte:",
    luxurioes: formal ? "Vielen Dank für Ihre Nachricht. Ich stimme die nächsten Schritte gerne sorgfältig mit Ihnen ab." : "Danke dir für deine Nachricht. Ich stimme die nächsten Schritte gerne sorgfältig mit dir ab.",
    verbindlich: formal ? "Vielen Dank für Ihre Nachricht. Ich bestätige Ihnen gerne den aktuellen Stand und die nächsten Schritte." : "Danke dir für deine Nachricht. Ich bestätige dir gerne den aktuellen Stand und die nächsten Schritte.",
    entschuldigend: formal ? "Vielen Dank für Ihre Geduld und Ihre Nachricht." : "Danke dir für deine Geduld und deine Nachricht.",
    freundlich: formal ? "Vielen Dank für Ihre Nachricht. Ich melde mich gerne dazu." : "Danke dir für deine Nachricht. Ich melde mich gerne dazu."
  };
  return openers[tone] || openers.freundlich;
}

function makeGoalSentence(goal, relationship, isEnglish) {
  const cleanGoal = goal
    .replace(/\b(professionell|freundlich|kurz|verbindlich)\b/gi, "")
    .replace(/\bantworten\b/gi, "")
    .replace(/\s+/g, " ")
    .trim();
  if (!cleanGoal) return "";
  if (isEnglish) return `I will keep the next step clear: ${cleanGoal}.`;
  if (/briefing|daten|details|infos|informationen/i.test(cleanGoal)) {
    return relationship === "sie"
      ? "Damit ich sauber weiterarbeiten kann, brauche ich bitte noch die relevanten Briefingdetails."
      : "Damit ich sauber weiterarbeiten kann, brauche ich bitte noch die relevanten Briefingdetails.";
  }
  return relationship === "sie"
    ? `Ich halte den nächsten Schritt klar fest: ${cleanGoal}.`
    : `Ich halte den nächsten Schritt klar fest: ${cleanGoal}.`;
}

function makeKeywordSentences(context, isEnglish) {
  if (!context.keywords.length) {
    return [
      isEnglish
        ? "[Add the specific answer points, date, price or next step here.]"
        : "[Konkreten Antwortpunkt, Termin, Preis oder nächsten Schritt ergänzen.]"
    ];
  }

  return context.keywords.map((item) => {
    const normalized = item.toLowerCase();
    const detail = normalizeKeywordDetail(item);
    const formal = context.relationship === "sie";
    if (isEnglish) {
      if (containsAny(normalized, ["termin", "date", "meeting"])) return `- Appointment: ${detail}.`;
      if (containsAny(normalized, ["nächster schritt", "naechster schritt", "next step"])) return `- Next step: ${detail}.`;
      if (containsAny(normalized, ["preis", "price", "kosten", "budget"])) return `- Budget/pricing: ${detail}.`;
      if (containsAny(normalized, ["angebot", "offer", "kooperation"])) return `- Collaboration/offer: ${detail}.`;
      if (containsAny(normalized, ["deadline", "frist", "datum"])) return `- Timing: ${detail}.`;
      return `- ${detail}.`;
    }
    if (containsAny(normalized, ["termin", "call", "meeting", "datum"])) {
      return formal ? `- Termin: ${detail}.` : `- Termin: ${detail}.`;
    }
    if (containsAny(normalized, ["nächster schritt", "naechster schritt", "next step"])) {
      return formal ? `- Nächster Schritt: ${detail}.` : `- Nächster Schritt: ${detail}.`;
    }
    if (containsAny(normalized, ["preis", "kosten", "budget", "honorar"])) {
      return formal ? `- Kosten/Budget: ${detail}.` : `- Kosten/Budget: ${detail}.`;
    }
    if (containsAny(normalized, ["angebot", "kooperation", "collab", "kampagne"])) {
      return formal ? `- Kooperation/Angebot: ${detail}.` : `- Kooperation/Angebot: ${detail}.`;
    }
    if (containsAny(normalized, ["deadline", "frist", "bis"])) {
      return formal ? `- Timing: ${detail}.` : `- Timing: ${detail}.`;
    }
    return `- ${detail}.`;
  });
}

function stripKeywordLabel(item) {
  return item
    .replace(/^\s*(offene frage|frage|question|termin|datum|budget|kosten|preis|honorar|nächster schritt|naechster schritt|next step|angebot|kooperation|deadline|frist|timing)\s*:\s*/i, "")
    .trim();
}

function normalizeKeywordDetail(item) {
  return stripKeywordLabel(item)
    .replace(/\b(abfragen|anfragen|anfordern|erfragen|klären|klaeren|anbieten|vorschlagen)\b\.?$/i, "")
    .replace(/\s+/g, " ")
    .trim();
}

function cleanAppointmentDetail(item) {
  const cleaned = item
    .replace(/^(call|termin|meeting|datum)\s*:?\s*/i, "")
    .trim();
  return cleaned || item;
}

function closeByTone(tone, relationship, isEnglish) {
  const formal = relationship === "sie";
  if (isEnglish) {
    if (tone === "kurz") return "Please let me know if this works for you.";
    if (tone === "entschuldigend") return "I appreciate your understanding and will make sure the next step is clear.";
    return "Please let me know what works best for you.";
  }
  if (tone === "kurz") return formal ? "Geben Sie mir gerne kurz Bescheid, ob das für Sie passt." : "Gib mir gerne kurz Bescheid, ob das für dich passt.";
  if (tone === "entschuldigend") return formal ? "Vielen Dank für Ihr Verständnis." : "Danke dir für dein Verständnis.";
  return formal ? "Ich freue mich auf Ihre Rückmeldung." : "Ich freue mich auf deine Rückmeldung.";
}

function makeSignature(context, isEnglish) {
  if (isEnglish) {
    const sender = context.senderName === "Frau Hiller" ? "Linda Hiller" : context.senderName;
    return `Best regards\n${sender}`;
  }
  if (context.relationship === "sie") {
    const sender = /^(frau|herr)\s+/i.test(context.senderName || "") ? getOwnerFullName() : context.senderName;
    const configured = context.account?.signature || "";
    if (/^beste grüße/i.test(configured.trim())) return configured;
    return `Beste Grüße\n${sender || getOwnerFullName()}`;
  }
  if (context.account?.signature) return context.account.signature;
  return state.style.signature;
}

function transformDraft(action, text, context) {
  if (action === "shorten") return shortenText(text, context);
  if (action === "friendly") return makeFriendlier(text, context);
  if (action === "professional") return makeMoreProfessional(text, context);
  if (action === "translate") return buildEmailReply({ ...context, targetLanguage: state.settings.targetLanguage });
  return text;
}

function shortenText(text, context) {
  const sentences = text
    .split(/(?<=[.!?])\s+/)
    .map((sentence) => sentence.trim())
    .filter(Boolean)
    .filter((sentence) => !/Ziel meiner Antwort|Goal of my reply/i.test(sentence));
  const limited = sentences.slice(0, 7).join(" ");
  const signature = makeSignature(context, state.settings.targetLanguage === "en");
  return cleanupDraft(`${limited}\n\n${signature}`);
}

function makeFriendlier(text, context) {
  const formal = context.relationship === "sie";
  const addition = state.settings.targetLanguage === "en"
    ? "I am happy to coordinate this in a way that works well for everyone involved."
    : formal
      ? "Ich stimme das gerne so ab, dass es für alle Beteiligten gut und unkompliziert funktioniert."
      : "Ich stimme das gerne so ab, dass es für alle unkompliziert und gut funktioniert.";
  return cleanupDraft(insertBeforeSignature(text, addition));
}

function makeMoreProfessional(text, context) {
  const formalized = text
    .replace(/\bdanke dir\b/gi, "vielen Dank")
    .replace(/\bGib mir\b/g, "Geben Sie mir")
    .replace(/\bdeine\b/g, "Ihre")
    .replace(/\bdeiner\b/g, "Ihrer")
    .replace(/\bdeinem\b/g, "Ihrem")
    .replace(/\bdu\b/g, "Sie")
    .replace(/\bdich\b/g, "Sie");
  const addition = "Ich halte die nächsten Schritte verbindlich fest und melde mich mit den relevanten Details.";
  return cleanupDraft(insertBeforeSignature(formalized, addition));
}

function insertBeforeSignature(text, addition) {
  const lines = text.split("\n");
  const signatureIndex = lines.findIndex((line) => /^(liebe|beste|viele|best regards|kind regards)/i.test(line.trim()));
  if (signatureIndex >= 0) {
    lines.splice(signatureIndex, 0, "", addition, "");
    return lines.join("\n");
  }
  return `${text.trim()}\n\n${addition}`;
}

function buildContentOutput(context) {
  const type = context.type;
  if (type === "caption") return buildCaption(context);
  if (type === "hooks") return buildHooks(context);
  if (type === "hashtags") return buildHashtags(context);
  if (type === "offer") return buildOffer(context);
  if (type === "briefing") return buildBriefing(context);
  if (type === "cancellation") return buildCancellation(context);
  return buildCaption(context);
}

function buildCaption(context) {
  const topic = context.topic || "[Thema ergänzen]";
  const cta = context.cta || "Schreib mir eine Nachricht";
  const details = splitItems(context.details).slice(0, 4);
  return cleanupDraft([
    makeHook(topic, context.brand),
    "",
    `${topic}`,
    details.length ? details.map((item) => `- ${item}`).join("\n") : "- [USP ergänzen]\n- [Nutzen ergänzen]",
    "",
    `${cta}.`,
    "",
    buildHashtags(context)
  ].join("\n"));
}

function buildHooks(context) {
  const topic = context.topic || "dein Thema";
  return [
    `1. Was ${topic} wirklich verändert`,
    `2. Der Unterschied, den man erst sieht, wenn man genauer hinschaut`,
    `3. Kurz erklärt: ${topic}`,
    `4. Drei Dinge, die bei ${topic} oft übersehen werden`,
    `5. Warum ${topic} gerade jetzt relevant ist`,
    `6. Hinter den Kulissen: ${topic}`,
    `7. So fühlt sich gute Umsetzung wirklich an`
  ].join("\n");
}

function buildHashtags(context) {
  const source = `${context.topic} ${context.details} ${context.brand.name}`.toLowerCase();
  const words = splitItems(source.replace(/[^\p{L}\p{N}\s,-]/gu, " "))
    .flatMap((item) => item.split(/\s+/))
    .map((word) => word.trim())
    .filter((word) => word.length > 3)
    .filter((word, index, array) => array.indexOf(word) === index)
    .slice(0, 12);
  const base = ["content", "socialmedia", "brand", "marketing", "austria"];
  return [...words, ...base]
    .filter((word, index, array) => array.indexOf(word) === index)
    .slice(0, 18)
    .map((word) => `#${word.replace(/ä/g, "ae").replace(/ö/g, "oe").replace(/ü/g, "ue").replace(/ß/g, "ss")}`)
    .join(" ");
}

function buildOffer(context) {
  const topic = context.topic || "Kooperation";
  const details = splitItems(context.details);
  const checklist = briefingChecklistItems();
  const mediaKit = creatorMediaKitLine(false);
  return cleanupDraft([
    "Guten Tag,",
    "",
    `vielen Dank für die Anfrage zur ${topic}. Ich freue mich grundsätzlich über passende Kooperationen, wenn Zielgruppe, Timing und Umsetzung sauber zusammenpassen.`,
    "",
    state.owner.services ? `Mögliche Leistungen: ${state.owner.services}.` : "",
    mediaKit,
    "",
    "Für eine Einschätzung brauche ich bitte:",
    checklist.map((item) => `- ${item}`).join("\n"),
    "",
    state.owner.rateCardNote ? `Preisregel: ${state.owner.rateCardNote}` : "",
    state.owner.usageRightsPolicy ? `Nutzungsrechte: ${state.owner.usageRightsPolicy}` : "",
    details.length ? `\nBereits notiert:\n${details.map((item) => `- ${item}`).join("\n")}` : "",
    "",
    "Sobald diese Punkte klar sind, kann ich einen passenden Vorschlag vorbereiten.",
    "",
    state.style.signature
  ].join("\n"));
}

function buildBriefing(context) {
  const topic = context.topic || "[Projekt]";
  const checklist = briefingChecklistItems();
  return cleanupDraft([
    `Briefing: ${topic}`,
    "",
    state.owner.roleTitle ? `Profil: ${state.owner.roleTitle}` : "",
    state.owner.niche ? `Nische: ${state.owner.niche}` : "",
    state.owner.services ? `Leistungen: ${state.owner.services}` : "",
    "",
    "Ziel:",
    context.cta || "[Ziel ergänzen]",
    "",
    "Zielgruppe:",
    context.brand.audience,
    "",
    "Checkliste:",
    checklist.map((item) => `- ${item}`).join("\n"),
    "",
    "No-Gos:",
    [context.brand.noGos, state.owner.brandSafetyNoGos].filter(Boolean).join("\n")
  ].join("\n"));
}

function buildCancellation(context) {
  const topic = context.topic || "die Anfrage";
  return cleanupDraft([
    "Guten Tag,",
    "",
    `vielen Dank für ${topic}. Aktuell kann ich das leider nicht passend übernehmen.`,
    "",
    "Ich möchte hier lieber transparent sein, damit die Planung sauber bleibt und keine falsche Zusage entsteht.",
    "",
    "Ich wünsche viel Erfolg bei der Umsetzung.",
    "",
    state.style.signature
  ].join("\n"));
}

function loadSelectedTemplate() {
  generateContent();
}

function generateCalendarPlan() {
  const range = Number($("#calendarRange").value);
  const frequency = $("#calendarFrequency").value;
  const brand = state.brands.find((item) => item.id === $("#contentBrandSelect").value) || state.brands[0];
  const topics = splitItems($("#calendarTopics").value || $("#contentTopic").value || "Behind the scenes, Angebot, Kundennutzen, FAQ, Referenz");
  const channels = ["Instagram Reel", "Instagram Post", "Story", "LinkedIn"];
  const formats = ["Hook + Nutzen", "Behind the scenes", "FAQ", "Case", "CTA"];
  const rows = [];
  const start = new Date();

  for (let offset = 0; offset < range; offset += 1) {
    const date = new Date(start);
    date.setDate(start.getDate() + offset);
    if (!shouldPostOnDate(date, frequency, rows.length)) continue;
    const topic = topics[rows.length % topics.length];
    rows.push({
      date: formatDate(date),
      channel: channels[rows.length % channels.length],
      format: formats[rows.length % formats.length],
      topic,
      hook: makeHook(topic, brand)
    });
  }

  state.calendar = rows;
  saveState();
  renderCalendar();
  showToast("Kalender erstellt");
}

function shouldPostOnDate(date, frequency, count) {
  const day = date.getDay();
  if (frequency === "weekday") return day >= 1 && day <= 5;
  if (frequency === "three") return [1, 3, 5].includes(day) || (count < 3 && day === 2);
  return true;
}

function makeHook(topic, brand) {
  const clean = topic || brand.name;
  const hooks = [
    `Was bei ${clean} wirklich zählt`,
    `${clean}: klar, hochwertig und ohne Umwege`,
    `Ein Blick hinter die Umsetzung von ${clean}`,
    `Warum ${clean} mehr ist als nur ein Detail`,
    `Drei Punkte, die ${clean} sofort besser machen`
  ];
  return hooks[Math.abs(hashString(clean)) % hooks.length];
}

function addFollowup() {
  const context = collectReplyContext();
  const date = new Date();
  date.setDate(date.getDate() + 3);
  state.followups.unshift({
    date: formatDate(date),
    subject: context.parsed.subject || context.goal || "Nachfassen",
    account: context.account.email,
    recipient: context.recipient
  });
  saveState();
  renderFollowups();
  showToast("Follow-up angelegt");
}

function clearFollowups() {
  state.followups = [];
  saveState();
  renderFollowups();
}

function updateSummary(force = false) {
  const thread = $("#threadInput")?.value.trim() || "";
  if (!thread) {
    $("#summaryBox").textContent = "Keine Daten";
    return;
  }
  const parsed = parseMailThread(thread);
  const context = collectReplyContext();
  const questions = extractQuestions(thread);
  const dates = extractDateLike(thread);
  const amounts = extractAmounts(thread);
  const summary = [
    `Arbeitskonto: ${context.account.email}`,
    `Anrede/Absender: ${formatRelationshipLabel(context)}`,
    parsed.senderName ? `Absender: ${parsed.senderName}` : "",
    parsed.senderEmail ? `Mail: ${parsed.senderEmail}` : "",
    parsed.subject ? `Betreff: ${parsed.subject}` : "",
    isCreatorCollaborationContext(context) ? `Creator-Check:\n${briefingChecklistItems().slice(0, 7).map((item) => `- ${item}`).join("\n")}` : "",
    questions.length ? `Fragen:\n${questions.map((item) => `- ${item}`).join("\n")}` : "",
    dates.length ? `Termine/Fristen: ${dates.join(", ")}` : "",
    amounts.length ? `Beträge/Budgets: ${amounts.join(", ")}` : "",
    force ? `Aktualisiert: ${new Date().toLocaleTimeString("de-AT", { hour: "2-digit", minute: "2-digit" })}` : ""
  ].filter(Boolean).join("\n\n");
  $("#summaryBox").textContent = summary || "Keine verwertbaren Eckdaten gefunden";
}

function buildPrompt(operation = "reply") {
  const activePanel = $(".panel.active")?.id || "replyPanel";
  const context = activePanel === "contentPanel" || ["caption", "hooks", "hashtags", "offer", "briefing", "cancellation"].includes(operation)
    ? collectContentContext()
    : collectReplyContext();

  const brand = context.brand || {};
  const lines = [
    "Rolle: Du bist Lindas privater Schreibassistent für Social-Media-Management, Kooperationen und Mails.",
    "Regel: Nie automatisch senden. Nur Entwurf erstellen.",
    `Fokusmodus: ${state.settings.allowedMailOnly ? "nur freigegebene Mailkonten" : "alle konfigurierten Konten"}`,
    `Freigegebene Konten: ${getVisibleAccounts().map((account) => account.email).join(", ")}`,
    `Primärer Kalender: ${calendarLabel(state.settings.primaryCalendar)}`,
    `Kalender-Modus: ${state.settings.calendarMode === "ics-first" ? "ICS zuerst, nie automatisch eintragen" : "direkt nach Bestätigung eintragen"}`,
    `Nutzerprofil: ${getOwnerFullName()} · ${state.owner.roleTitle || "Social Media"}`,
    `Nische: ${state.owner.niche || "nicht hinterlegt"}`,
    `Leistungen: ${state.owner.services || "nicht hinterlegt"}`,
    `Media-Kit: ${state.owner.mediaKitUrl || "nicht hinterlegt"}`,
    `Social Links: ${state.owner.socialLinks || "nicht hinterlegt"}`,
    `Preisregel: ${state.owner.rateCardNote || "keine Preise ohne Scope erfinden"}`,
    `Nutzungsrechte-Regel: ${state.owner.usageRightsPolicy || "Nutzungsrechte separat klären"}`,
    `Briefing-Checkliste: ${briefingChecklistItems().join(", ")}`,
    `Brand-Safety No-Gos: ${state.owner.brandSafetyNoGos || "keine unbestätigten Zusagen"}`,
    `Linda-Stil: ${state.style.voice}`,
    `Linda-Regeln: ${state.style.rules}`,
    `Brand: ${brand.name || "Allgemein"}`,
    `Brand-Ton: ${brand.tone || ""}`,
    `Zielgruppe: ${brand.audience || ""}`,
    `No-Gos: ${brand.noGos || ""}`,
    `Operation: ${operation}`,
    ""
  ];

  if ("thread" in context) {
    lines.push(
      `Konto: ${context.account.email}`,
      `Provider: ${context.account.provider}`,
      `Absendername: ${context.senderName}`,
      `Entscheidung: ${formatRelationshipLabel(context)}`,
      `Kanal: ${context.channel}`,
      `Beziehung: ${context.relationship}`,
      `Ton: ${context.tone}`,
      `Empfänger: ${context.recipient || "auto"}`,
      `Ziel: ${context.goal || "auto"}`,
      `Stichworte: ${context.keywords.join(", ") || "keine"}`,
      "",
      "Mail-/DM-Verlauf:",
      context.thread || "[leer]"
    );
  } else {
    lines.push(
      `Format: ${context.type}`,
      `Kanal: ${context.channel}`,
      `Thema: ${context.topic || "[leer]"}`,
      `Details: ${context.details || "[leer]"}`,
      `CTA: ${context.cta || "[leer]"}`
    );
  }

  return lines.join("\n");
}

function updatePromptPreview() {
  const prompt = buildPrompt();
  $("#promptPreview").value = prompt;
  updateDecisionPreview();
}

function setDraft(text, label) {
  $("#outputText").value = text;
  $("#draftMeta").textContent = label;
  updatePromptPreview();
  updateSummary();
  updateDecisionPreview();
}

function updateDecisionPreview() {
  const box = $("#decisionBox");
  if (!box || !$("#fromAccount")) return;
  const context = collectReplyContext();
  const lines = [
    `Workflow: ${workflowLabel(workflowMode)}`,
    `Konto: ${context.account.label} · ${context.account.email}`,
    `Provider: ${context.account.provider}`,
    `Fokus: ${state.settings.allowedMailOnly ? "nur freigegebene Liste" : "alle konfigurierten Konten"}`,
    `Anrede: ${context.relationship === "du" ? "Du" : "Sie"}`,
    `Absender: ${context.senderName}`,
    `Profil: ${state.owner.roleTitle || "Social Media"}`,
    `Signatur: ${(context.account.signature || state.style.signature).split("\n")[0]}`,
    `Kalender: ${calendarLabel(state.settings.primaryCalendar)}`,
    isCreatorCollaborationContext(context) ? `Creator-Check: Briefing, Budget, Rechte, Timing` : ""
  ];
  box.textContent = lines.filter(Boolean).join("\n");
}

function setWorkflowMode(mode) {
  workflowMode = mode;
  $$(".workflow-button").forEach((button) => {
    button.classList.toggle("active", button.dataset.workflowMode === mode);
  });

  const config = {
    reply: {
      title: "Mail antworten",
      subtitle: "Antwortentwurf aus Verlauf und Stichworten",
      threadLabel: "Verlauf",
      keywordLabel: "Stichworte",
      threadPlaceholder: "Mailverlauf oder DM hier einfügen",
      keywordPlaceholder: "Antwortpunkte, Termine, Preise, nächste Schritte",
      actionLabel: "Antwort",
      suggestionMeta: "Antwort drücken, Richtung wählen"
    },
    create: {
      title: "Mail erstellen",
      subtitle: "Neue Mail aus Ziel, Empfänger und Stichworten",
      threadLabel: "Kontext",
      keywordLabel: "Stichworte",
      threadPlaceholder: "Optionaler Kontext, bisherige Abstimmung oder interne Notizen",
      keywordPlaceholder: "Was soll die Mail sagen? Fakten, Fristen, Bitte, CTA",
      actionLabel: "Mail erstellen",
      suggestionMeta: "Mail erstellen drücken, Richtung wählen"
    },
    event: {
      title: "Termin erstellen",
      subtitle: "Termintext und Kalenderdatei aus Anfrage und Stichworten",
      threadLabel: "Anfrage",
      keywordLabel: "Termindetails",
      threadPlaceholder: "Mail oder Nachricht mit Terminwunsch einfügen",
      keywordPlaceholder: "Datum, Uhrzeit, Dauer, Ort/Link, Zweck, Teilnehmer",
      actionLabel: "Termin",
      suggestionMeta: "Termin drücken, Variante wählen"
    }
  }[mode];

  $("#workflowTitle").textContent = config.title;
  $("#workflowSubtitle").textContent = config.subtitle;
  $("#threadLabel").textContent = config.threadLabel;
  $("#keywordLabel").textContent = config.keywordLabel;
  $("#threadInput").placeholder = config.threadPlaceholder;
  $("#keywordInput").placeholder = config.keywordPlaceholder;
  $(".ai-toolbar button[data-action='reply']").textContent = config.actionLabel;
  $("#suggestionMeta").textContent = config.suggestionMeta;
  $("#eventFields").classList.toggle("hidden", mode !== "event");
  updatePromptPreview();
}

function parseMailThread(text) {
  const fromLine = matchLine(text, /^(from|von|absender):\s*(.+)$/im);
  const subject = matchLine(text, /^(subject|betreff):\s*(.+)$/im);
  const emailMatch = (fromLine || text).match(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/i);
  const senderEmail = emailMatch ? emailMatch[0] : "";
  const senderName = cleanupName((fromLine || "").replace(senderEmail, ""));
  return { senderEmail, senderName, subject: subject || "" };
}

function matchLine(text, regex) {
  const match = text.match(regex);
  return match ? match[2].trim() : "";
}

function cleanupName(value) {
  return value
    .replace(/[<>"']/g, "")
    .replace(/\s+/g, " ")
    .trim();
}

function resolveRelationship(selection, thread, channel = "") {
  if (selection !== "auto") return selection;
  const channelLower = channel.toLowerCase();
  const lower = ` ${thread.toLowerCase()} `;
  const duScore = countMatches(lower, /\b(du|dir|dich|dein|deine|deiner|deinem)\b/g);
  const sieScore = countMatches(lower, /\b(sie|ihnen|ihre|ihrer|ihrem)\b/g);
  if ((channelLower.includes("whatsapp") || channelLower.includes("instagram dm")) && sieScore === 0) return "du";
  return duScore > sieScore ? "du" : "sie";
}

function resolveSenderName(selection, account) {
  if (selection !== "auto") return selection;
  return account?.defaultSender || inferDefaultSender(account?.email || "");
}

function inferDefaultSender(email) {
  const owner = currentOwner();
  if (email.includes("skinfit")) return owner.formalSender;
  if (email.includes("icloud")) return owner.casualSender;
  return getOwnerFullName(owner);
}

function currentOwner(fallback = DEFAULT_STATE.owner) {
  try {
    return state?.owner || fallback;
  } catch {
    return fallback;
  }
}

function getOwnerFullName(owner = currentOwner()) {
  return `${owner.firstName || ""} ${owner.lastName || ""}`.replace(/\s+/g, " ").trim() || "Linda Hiller";
}

function defaultFormalSender(owner) {
  if (owner.gender === "male") return `Herr ${owner.lastName || ""}`.trim();
  if (owner.gender === "neutral") return getOwnerFullName(owner);
  return `Frau ${owner.lastName || ""}`.trim();
}

function defaultSignatureForOwner(account = {}) {
  const owner = currentOwner();
  const sender = account.email?.includes("skinfit") ? getOwnerFullName(owner) : owner.casualSender;
  return `Liebe Grüße\n${sender}`;
}

function normalizeAccountSender(sender) {
  const owner = currentOwner();
  const legacy = {
    "Linda Hiller": getOwnerFullName(owner),
    "Frau Hiller": owner.formalSender,
    Linda: owner.casualSender
  };
  return legacy[sender] || sender || getOwnerFullName(owner);
}

function normalizeLegacySignature(signature, account = {}) {
  const legacySignatures = new Set([
    "Liebe Grüße\nLinda",
    "Beste Grüße\nLinda Hiller",
    "Liebe Grüße\nLinda Hiller"
  ]);
  if (!signature || legacySignatures.has(signature)) return defaultSignatureForOwner(account);
  return signature;
}

function senderOptionsForAccount(selected) {
  const options = [
    getOwnerFullName(),
    state.owner.formalSender,
    state.owner.casualSender
  ].filter((value, index, array) => value && array.indexOf(value) === index);
  return options.map((value) => `<option value="${escapeAttribute(value)}" ${value === selected ? "selected" : ""}>${escapeHtml(value)}</option>`).join("");
}

function initialsForName(name) {
  const parts = String(name || "")
    .split(/\s+/)
    .map((part) => part.trim())
    .filter(Boolean);
  return (parts[0]?.[0] || "M") + (parts[1]?.[0] || "D");
}

function inferProvider(email) {
  if (email === "info@jonnyandlinda.com") return "Google Workspace / Gmail via Wix";
  if (email.includes("gmail.com")) return "Gmail";
  if (email.includes("icloud.com")) return "iCloud Mail";
  if (email.includes("skinfit.eu")) return "Provider offen";
  return "Provider offen";
}

function formatRelationshipLabel(context) {
  const relationship = context.relationship === "du" ? "Du" : "Sie";
  return `${relationship} · ${context.senderName}`;
}

function workflowLabel(mode) {
  const labels = {
    reply: "Mail antworten",
    create: "Mail erstellen",
    event: "Termin erstellen"
  };
  return labels[mode] || "Mail antworten";
}

function firstName(name) {
  if (!name) return "";
  const clean = formalDisplayName(name);
  return clean.split(/\s+/)[0] || "";
}

function formalDisplayName(name) {
  return cleanupName(name)
    .replace(/^mailto:/i, "")
    .replace(/\([^)]*\)/g, "")
    .trim();
}

function formalGreetingName(name) {
  const clean = formalDisplayName(name);
  if (/^(frau|herr)\s+/i.test(clean)) return clean;
  const parts = clean.split(/\s+/).filter(Boolean);
  if (parts.length < 2 || clean.includes("@")) return clean;
  const first = parts[0].toLowerCase();
  const last = parts[parts.length - 1];
  const femaleFirstNames = new Set(["anna", "linda", "maria", "sarah", "sara", "laura", "julia", "sophie", "sofia", "katharina", "theresa", "verena", "nadine", "melanie", "carina", "christina", "claudia", "eva", "nina", "lara", "lea", "lena", "marie", "elisabeth"]);
  const maleFirstNames = new Set(["jonas", "max", "maximilian", "michael", "lukas", "lucas", "david", "thomas", "florian", "christian", "markus", "marco", "philipp", "daniel", "andreas", "stefan", "sebastian", "paul", "moritz", "felix"]);
  if (femaleFirstNames.has(first)) return `Frau ${last}`;
  if (maleFirstNames.has(first)) return `Herr ${last}`;
  return clean;
}

function splitItems(value) {
  return (value || "")
    .split(/\n|,|;/)
    .map((item) => item.trim())
    .filter(Boolean);
}

function joinReadable(items) {
  const clean = items.map((item) => item.trim()).filter(Boolean);
  if (clean.length <= 1) return clean[0] || "";
  if (clean.length === 2) return `${clean[0]} oder ${clean[1]}`;
  return `${clean.slice(0, -1).join(", ")} und ${clean[clean.length - 1]}`;
}

function capitalizeSentence(value) {
  const clean = String(value || "").trim();
  if (!clean) return "";
  return clean.charAt(0).toUpperCase() + clean.slice(1).replace(/[.!?]+$/, "");
}

function containsAny(value, needles) {
  return needles.some((needle) => value.includes(needle));
}

function countMatches(value, regex) {
  return (value.match(regex) || []).length;
}

function extractQuestions(text) {
  return text
    .split(/\n|(?<=[.!?])\s+/)
    .map((line) => line.trim())
    .filter((line) => line.includes("?"))
    .slice(0, 5);
}

function extractDateLike(text) {
  const matches = text.match(/\b(\d{1,2}\.\d{1,2}\.?\d{0,4}|\d{1,2}:\d{2}|Montag|Dienstag|Mittwoch|Donnerstag|Freitag|Samstag|Sonntag|morgen|heute|Deadline)\b/gi);
  return unique(matches || []).slice(0, 8);
}

function extractAmounts(text) {
  const matches = text.match(/\b\d{2,6}(?:[,.]\d{2})?\s?(?:EUR|Euro|€)\b/gi);
  return unique(matches || []).slice(0, 8);
}

function labelForAction(action) {
  const labels = {
    reply: "Antwortentwurf",
    briefing: "Briefing angefragt",
    pricing: "Preis/Scope geklärt",
    followup: "Follow-up",
    shorten: "Gekürzt",
    friendly: "Freundlicher",
    professional: "Professioneller",
    translate: state.settings.targetLanguage === "en" ? "Englisch" : "Deutsch"
  };
  return labels[action] || "Entwurf";
}

function labelForContentType(type) {
  const labels = {
    caption: "Caption",
    hooks: "Hooks",
    hashtags: "Hashtags",
    offer: "Angebot / Kooperation",
    briefing: "Briefing",
    cancellation: "Absage"
  };
  return labels[type] || "Content";
}

function cleanupDraft(text) {
  return text
    .replace(/[ \t]+\n/g, "\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

function unique(items) {
  return items.filter((item, index, array) => array.indexOf(item) === index);
}

function hashString(value) {
  return Array.from(value).reduce((hash, char) => ((hash << 5) - hash) + char.charCodeAt(0), 0);
}

function formatDate(date) {
  return date.toLocaleDateString("de-AT", { day: "2-digit", month: "2-digit", year: "numeric" });
}

function formatEventWhen(event) {
  if (!event.date && !event.time) return "Datum und Uhrzeit noch offen";
  const date = event.date ? new Date(`${event.date}T00:00:00`) : null;
  const dateText = date ? date.toLocaleDateString("de-AT", { weekday: "short", day: "2-digit", month: "2-digit", year: "numeric" }) : "Datum offen";
  const timeText = event.time ? `${event.time} Uhr` : "Uhrzeit offen";
  return `${dateText}, ${timeText} (${event.durationMinutes || 30} Minuten)`;
}

function parseLocalDateTime(date, time) {
  return new Date(`${date}T${time || "09:00"}:00`);
}

function formatIcsDate(date) {
  const pad = (value) => String(value).padStart(2, "0");
  return [
    date.getUTCFullYear(),
    pad(date.getUTCMonth() + 1),
    pad(date.getUTCDate()),
    "T",
    pad(date.getUTCHours()),
    pad(date.getUTCMinutes()),
    pad(date.getUTCSeconds()),
    "Z"
  ].join("");
}

function escapeIcs(value) {
  return String(value || "")
    .replace(/\\/g, "\\\\")
    .replace(/;/g, "\\;")
    .replace(/,/g, "\\,")
    .replace(/\n/g, "\\n");
}

function slugify(value) {
  return String(value || "termin")
    .toLowerCase()
    .replace(/[^a-z0-9äöüß]+/gi, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 80) || "termin";
}

async function copyText(text, message) {
  if (!text.trim()) {
    showToast("Kein Text vorhanden");
    return;
  }
  try {
    await navigator.clipboard.writeText(text);
    showToast(message);
  } catch {
    showToast("Kopieren nicht möglich");
  }
}

function downloadDraft() {
  const text = $("#outputText").value.trim();
  if (!text) {
    showToast("Kein Entwurf vorhanden");
    return;
  }
  const blob = new Blob([text], { type: "text/plain;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = `linda-entwurf-${Date.now()}.txt`;
  link.click();
  URL.revokeObjectURL(url);
}

function downloadCalendarInvite() {
  const event = activeCalendarEvent || inferCalendarEvent(collectReplyContext());
  if (!event.date || !event.time) {
    showToast("Für ICS bitte Datum und Uhrzeit eintragen");
    return;
  }
  const start = parseLocalDateTime(event.date, event.time);
  const end = new Date(start.getTime() + (event.durationMinutes || 30) * 60 * 1000);
  const ics = [
    "BEGIN:VCALENDAR",
    "VERSION:2.0",
    "PRODID:-//Linda Social Desk//DE",
    "CALSCALE:GREGORIAN",
    "METHOD:PUBLISH",
    "BEGIN:VEVENT",
    `UID:${Date.now()}@linda-social-desk`,
    `DTSTAMP:${formatIcsDate(new Date())}`,
    `DTSTART:${formatIcsDate(start)}`,
    `DTEND:${formatIcsDate(end)}`,
    `SUMMARY:${escapeIcs(event.title)}`,
    event.location ? `LOCATION:${escapeIcs(event.location)}` : "",
    event.notes ? `DESCRIPTION:${escapeIcs(event.notes)}` : "",
    ...event.attendees.map((email) => `ATTENDEE;ROLE=REQ-PARTICIPANT;PARTSTAT=NEEDS-ACTION;CN=${escapeIcs(email)}:mailto:${email}`),
    "END:VEVENT",
    "END:VCALENDAR"
  ].filter(Boolean).join("\r\n");
  const blob = new Blob([ics], { type: "text/calendar;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = `${slugify(event.title)}.ics`;
  link.click();
  URL.revokeObjectURL(url);
}

function exportConfig() {
  const blob = new Blob([JSON.stringify(state, null, 2)], { type: "application/json" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = `linda-social-desk-config-${Date.now()}.json`;
  link.click();
  URL.revokeObjectURL(url);
}

function importConfig(event) {
  const file = event.target.files?.[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = () => {
    try {
      const imported = JSON.parse(String(reader.result));
      state = deepMerge(clone(DEFAULT_STATE), imported);
      saveState();
      renderAll();
      updatePromptPreview();
      updateSummary();
      showToast("Import abgeschlossen");
    } catch {
      showToast("Import fehlgeschlagen");
    }
  };
  reader.readAsText(file);
  event.target.value = "";
}

function resetConfig() {
  state = clone(DEFAULT_STATE);
  saveState();
  renderAll();
  updatePromptPreview();
  updateSummary();
  showToast("Setup zurückgesetzt");
}

function startDictation(targetId) {
  const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
  const target = document.getElementById(targetId);
  if (!SpeechRecognition || !target) {
    showToast("Diktat über die Apple-Tastatur verwenden");
    target?.focus();
    return;
  }
  const recognition = new SpeechRecognition();
  recognition.lang = "de-AT";
  recognition.interimResults = false;
  recognition.maxAlternatives = 1;
  recognition.onresult = (event) => {
    const transcript = event.results[0][0].transcript;
    target.value = `${target.value}${target.value ? "\n" : ""}${transcript}`.trim();
    target.dispatchEvent(new Event("input", { bubbles: true }));
  };
  recognition.onerror = () => showToast("Diktat nicht verfügbar");
  recognition.start();
}

function showToast(message) {
  const existing = $(".toast");
  if (existing) existing.remove();
  const toast = document.createElement("div");
  toast.className = "toast";
  toast.textContent = message;
  document.body.appendChild(toast);
  window.setTimeout(() => toast.remove(), 2600);
}

function saveState() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  const indicator = $("#saveState");
  if (indicator) {
    indicator.textContent = `Gespeichert ${new Date().toLocaleTimeString("de-AT", { hour: "2-digit", minute: "2-digit" })}`;
  }
}

function loadState() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return clone(DEFAULT_STATE);
    return deepMerge(clone(DEFAULT_STATE), JSON.parse(raw));
  } catch {
    return clone(DEFAULT_STATE);
  }
}

function normalizeState(input) {
  const normalized = deepMerge(clone(DEFAULT_STATE), input);
  normalized.owner = {
    ...DEFAULT_STATE.owner,
    ...normalized.owner
  };
  if (!normalized.owner.formalSender) normalized.owner.formalSender = defaultFormalSender(normalized.owner);
  if (!normalized.owner.casualSender) normalized.owner.casualSender = normalized.owner.firstName;
  const defaultsByEmail = Object.fromEntries(DEFAULT_STATE.accounts.map((account) => [account.email, account]));
  normalized.accounts = normalized.accounts.map((account) => {
    const defaults = defaultsByEmail[account.email] || {};
    const fallbackSender = account.email.includes("skinfit")
      ? normalized.owner.formalSender
      : account.email.includes("icloud")
        ? normalized.owner.casualSender
        : `${normalized.owner.firstName} ${normalized.owner.lastName}`.trim();
    return {
      ...defaults,
      ...account,
      provider: account.provider || defaults.provider || inferProvider(account.email),
      accessStatus: account.accessStatus || "nicht verbunden",
      active: account.active !== false,
      defaultSender: account.defaultSender || fallbackSender,
      signature: account.signature || defaults.signature || normalized.style.signature
    };
  });
  normalized.settings = {
    ...DEFAULT_STATE.settings,
    ...normalized.settings,
    allowedMailOnly: normalized.settings.allowedMailOnly !== false,
    primaryCalendar: normalized.settings.primaryCalendar || "icloud",
    calendarMode: normalized.settings.calendarMode || "ics-first"
  };
  return normalized;
}

function deepMerge(target, source) {
  Object.entries(source || {}).forEach(([key, value]) => {
    if (Array.isArray(value)) {
      target[key] = value;
      return;
    }
    if (value && typeof value === "object") {
      target[key] = deepMerge(target[key] || {}, value);
      return;
    }
    target[key] = value;
  });
  return target;
}

function clone(value) {
  return JSON.parse(JSON.stringify(value));
}

function escapeHtml(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

function escapeAttribute(value) {
  return escapeHtml(value).replace(/\n/g, " ");
}
