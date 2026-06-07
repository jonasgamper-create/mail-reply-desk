import { createServer } from "node:http";
import { readFileSync } from "node:fs";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import { randomBytes } from "node:crypto";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
loadDotEnv(join(__dirname, ".env"));

const PORT = Number(process.env.PORT || 8787);
const CLIENT_ID = process.env.GOOGLE_CLIENT_ID || "";
const CLIENT_SECRET = process.env.GOOGLE_CLIENT_SECRET || "";
const REDIRECT_URI = process.env.GOOGLE_REDIRECT_URI || `http://127.0.0.1:${PORT}/oauth/google/callback`;
const FOCUS_QUERY = process.env.GMAIL_FOCUS_QUERY || "newer_than:30d";
const TOKEN_PATH = join(__dirname, ".local", "google-token.json");
const STATE_PATH = join(__dirname, ".local", "oauth-state.txt");
const SCOPES = ["https://www.googleapis.com/auth/gmail.readonly"];

const server = createServer(async (request, response) => {
  try {
    const url = new URL(request.url || "/", `http://${request.headers.host || `127.0.0.1:${PORT}`}`);

    if (request.method === "GET" && url.pathname === "/health") {
      return sendJSON(response, 200, { ok: true, service: "mail-reply-desk-gmail-readonly" });
    }

    if (request.method === "GET" && url.pathname === "/auth/google") {
      return startGoogleOAuth(response);
    }

    if (request.method === "GET" && url.pathname === "/oauth/google/callback") {
      return finishGoogleOAuth(url, response);
    }

    if (request.method === "GET" && url.pathname === "/gmail/messages") {
      const maxResults = Math.min(Number(url.searchParams.get("max") || 10), 25);
      const query = url.searchParams.get("q") || FOCUS_QUERY;
      const messages = await listMessages({ maxResults, query });
      return sendJSON(response, 200, { query, messages });
    }

    if (request.method === "GET" && url.pathname.startsWith("/gmail/messages/")) {
      const id = decodeURIComponent(url.pathname.replace("/gmail/messages/", ""));
      const message = await getMessage(id);
      return sendJSON(response, 200, message);
    }

    sendJSON(response, 404, {
      error: "not_found",
      routes: ["/health", "/auth/google", "/gmail/messages", "/gmail/messages/:id"]
    });
  } catch (error) {
    sendJSON(response, 500, {
      error: "server_error",
      message: error instanceof Error ? error.message : String(error)
    });
  }
});

server.listen(PORT, "127.0.0.1", () => {
  console.log(`Mail Reply Desk Gmail backend: http://127.0.0.1:${PORT}`);
  console.log("Login: /auth/google");
});

async function startGoogleOAuth(response) {
  assertOAuthConfig();
  const state = randomBytes(24).toString("hex");
  await writeLocalFile(STATE_PATH, state);

  const url = new URL("https://accounts.google.com/o/oauth2/v2/auth");
  url.searchParams.set("client_id", CLIENT_ID);
  url.searchParams.set("redirect_uri", REDIRECT_URI);
  url.searchParams.set("response_type", "code");
  url.searchParams.set("scope", SCOPES.join(" "));
  url.searchParams.set("access_type", "offline");
  url.searchParams.set("prompt", "consent");
  url.searchParams.set("state", state);

  response.writeHead(302, { Location: url.toString() });
  response.end();
}

async function finishGoogleOAuth(url, response) {
  assertOAuthConfig();
  const code = url.searchParams.get("code");
  const state = url.searchParams.get("state");
  const expectedState = existsSync(STATE_PATH) ? (await readFile(STATE_PATH, "utf8")).trim() : "";

  if (!code || !state || state !== expectedState) {
    return sendHTML(response, 400, "OAuth fehlgeschlagen: ungültiger State oder fehlender Code.");
  }

  const token = await tokenRequest({
    code,
    client_id: CLIENT_ID,
    client_secret: CLIENT_SECRET,
    redirect_uri: REDIRECT_URI,
    grant_type: "authorization_code"
  });

  await saveToken(normalizeToken(token));
  sendHTML(response, 200, "Gmail Read-only verbunden. Du kannst dieses Fenster schließen.");
}

async function listMessages({ maxResults, query }) {
  const token = await getValidAccessToken();
  const url = new URL("https://gmail.googleapis.com/gmail/v1/users/me/messages");
  url.searchParams.set("maxResults", String(maxResults));
  url.searchParams.set("q", query);

  const data = await gmailFetch(url, token);
  const messages = data.messages || [];
  const details = [];

  for (const item of messages) {
    const message = await getMessage(item.id, { includeBody: false });
    details.push(message);
  }
  return details;
}

async function getMessage(id, options = { includeBody: true }) {
  const token = await getValidAccessToken();
  const format = options.includeBody ? "full" : "metadata";
  const url = new URL(`https://gmail.googleapis.com/gmail/v1/users/me/messages/${encodeURIComponent(id)}`);
  url.searchParams.set("format", format);
  if (!options.includeBody) {
    url.searchParams.append("metadataHeaders", "From");
    url.searchParams.append("metadataHeaders", "To");
    url.searchParams.append("metadataHeaders", "Subject");
    url.searchParams.append("metadataHeaders", "Date");
  }

  const data = await gmailFetch(url, token);
  const headers = Object.fromEntries((data.payload?.headers || []).map((header) => [header.name.toLowerCase(), header.value]));
  const body = options.includeBody ? extractPlainText(data.payload) : undefined;

  return {
    id: data.id,
    threadId: data.threadId,
    from: headers.from || "",
    to: headers.to || "",
    subject: headers.subject || "",
    date: headers.date || "",
    snippet: data.snippet || "",
    body
  };
}

async function gmailFetch(url, token) {
  const response = await fetch(url, {
    headers: { Authorization: `Bearer ${token.access_token}` }
  });
  const data = await response.json();
  if (!response.ok) {
    throw new Error(data.error?.message || `Gmail API failed with ${response.status}`);
  }
  return data;
}

async function getValidAccessToken() {
  const token = await loadToken();
  if (!token.refresh_token && token.expires_at <= Date.now() + 60_000) {
    throw new Error("Token abgelaufen. Bitte /auth/google erneut öffnen.");
  }
  if (token.expires_at > Date.now() + 60_000) {
    return token;
  }

  const refreshed = await tokenRequest({
    client_id: CLIENT_ID,
    client_secret: CLIENT_SECRET,
    refresh_token: token.refresh_token,
    grant_type: "refresh_token"
  });
  const nextToken = normalizeToken({ ...token, ...refreshed, refresh_token: token.refresh_token });
  await saveToken(nextToken);
  return nextToken;
}

async function tokenRequest(body) {
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams(body)
  });
  const data = await response.json();
  if (!response.ok) {
    throw new Error(data.error_description || data.error || `OAuth token request failed with ${response.status}`);
  }
  return data;
}

async function loadToken() {
  if (!existsSync(TOKEN_PATH)) {
    throw new Error("Gmail ist noch nicht verbunden. Bitte zuerst /auth/google öffnen.");
  }
  return JSON.parse(await readFile(TOKEN_PATH, "utf8"));
}

async function saveToken(token) {
  await writeLocalFile(TOKEN_PATH, JSON.stringify(token, null, 2));
}

function normalizeToken(token) {
  return {
    access_token: token.access_token,
    refresh_token: token.refresh_token,
    scope: token.scope,
    token_type: token.token_type,
    expires_at: Date.now() + Number(token.expires_in || 3600) * 1000
  };
}

function extractPlainText(payload) {
  if (!payload) return "";
  if (payload.mimeType === "text/plain" && payload.body?.data) {
    return decodeBase64Url(payload.body.data);
  }
  for (const part of payload.parts || []) {
    const text = extractPlainText(part);
    if (text) return text;
  }
  if (payload.body?.data) {
    return stripHTML(decodeBase64Url(payload.body.data));
  }
  return "";
}

function decodeBase64Url(value) {
  const normalized = value.replace(/-/g, "+").replace(/_/g, "/");
  return Buffer.from(normalized, "base64").toString("utf8").trim();
}

function stripHTML(value) {
  return value
    .replace(/<br\s*\/?>/gi, "\n")
    .replace(/<\/p>/gi, "\n")
    .replace(/<[^>]+>/g, " ")
    .replace(/\s+\n/g, "\n")
    .replace(/[ \t]{2,}/g, " ")
    .trim();
}

function assertOAuthConfig() {
  if (!CLIENT_ID || !CLIENT_SECRET) {
    throw new Error("GOOGLE_CLIENT_ID und GOOGLE_CLIENT_SECRET fehlen. Bitte backend/.env ausfüllen.");
  }
}

async function writeLocalFile(path, value) {
  await mkdir(dirname(path), { recursive: true });
  await writeFile(path, value, { mode: 0o600 });
}

function loadDotEnv(path) {
  if (!existsSync(path)) return;
  const content = readFileSyncSafe(path);
  for (const line of content.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const index = trimmed.indexOf("=");
    if (index === -1) continue;
    const key = trimmed.slice(0, index).trim();
    const value = trimmed.slice(index + 1).trim();
    if (!process.env[key]) process.env[key] = value;
  }
}

function readFileSyncSafe(path) {
  return existsSync(path) ? Buffer.from(readFileSync(path)).toString("utf8") : "";
}

function sendJSON(response, status, data) {
  response.writeHead(status, {
    "Content-Type": "application/json; charset=utf-8",
    "Access-Control-Allow-Origin": "http://127.0.0.1:4173"
  });
  response.end(JSON.stringify(data, null, 2));
}

function sendHTML(response, status, message) {
  response.writeHead(status, { "Content-Type": "text/html; charset=utf-8" });
  response.end(`<!doctype html><meta name="viewport" content="width=device-width, initial-scale=1"><body style="font-family:-apple-system,BlinkMacSystemFont,sans-serif;padding:32px;line-height:1.4"><h1>Mail Reply Desk</h1><p>${escapeHTML(message)}</p></body>`);
}

function escapeHTML(value) {
  return value.replace(/[&<>"']/g, (char) => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    "\"": "&quot;",
    "'": "&#039;"
  }[char]));
}
