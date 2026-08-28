import cors from "cors";
import express from "express";
import { disclaimerPage, privacyPage, supportPage, termsPage } from "./legal.js";
import { catalogItem, generateTransactions, institutions, snapshotFromItems } from "./sandbox.js";
import { store } from "./store.js";

const app = express();
const port = Number(process.env.PORT ?? 8787);
const usePlaid = Boolean(process.env.PLAID_CLIENT_ID && process.env.PLAID_SECRET);
const plaidEnv = process.env.PLAID_ENV ?? "sandbox";
const plaidHost =
  plaidEnv === "production"
    ? "https://production.plaid.com"
    : plaidEnv === "development"
      ? "https://development.plaid.com"
      : "https://sandbox.plaid.com";

app.use(cors());
app.use(express.json({ limit: "64kb" }));

const hits = new Map();
app.use((req, res, next) => {
  const key = req.ip ?? "unknown";
  const now = Date.now();
  const entry = hits.get(key);
  if (!entry || now - entry.start > 60_000) {
    hits.set(key, { start: now, count: 1 });
    return next();
  }
  entry.count += 1;
  if (entry.count > 180) return res.status(429).json({ error: "Too many requests" });
  next();
});

let metalsCache = null;

function gramsFromTroyOunce(pricePerOunce) {
  return Number(pricePerOunce) / 31.1034768;
}

async function plaidRequest(path, body) {
  const response = await fetch(`${plaidHost}${path}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "PLAID-CLIENT-ID": process.env.PLAID_CLIENT_ID,
      "PLAID-SECRET": process.env.PLAID_SECRET,
    },
    body: JSON.stringify(body),
  });
  const json = await response.json();
  if (!response.ok) {
    throw new Error(json.error_message ?? "Plaid request failed");
  }
  return json;
}

function bearer(req) {
  const header = req.headers.authorization ?? "";
  return header.startsWith("Bearer ") ? header.slice(7) : null;
}

function requireUser(req, res, next) {
  const user = store.userForToken(bearer(req));
  if (!user) return res.status(401).json({ error: "Sign in required." });
  req.user = user;
  next();
}

function publicUserPayload(user, token) {
  return {
    token,
    user: {
      id: user.id,
      full_name: user.full_name,
      email: user.email,
      created_at: user.created_at,
    },
  };
}

function persistSandboxItem(userID, institutionID) {
  const item = catalogItem(institutionID);
  item.transactions = generateTransactions(item.institution_id);
  store.saveItem(userID, item);
  return item;
}

app.get("/health", (_req, res) => {
  res.json({ ok: true, mode: usePlaid ? "plaid" : "sandbox", env: plaidEnv });
});

app.get("/", (_req, res) => res.type("html").send(supportPage()));
app.get("/privacy", (_req, res) => res.type("html").send(privacyPage()));
app.get("/terms", (_req, res) => res.type("html").send(termsPage()));
app.get("/disclaimer", (_req, res) => res.type("html").send(disclaimerPage()));
app.get("/legal/privacy", (_req, res) => res.redirect(301, "/privacy"));
app.get("/legal/terms", (_req, res) => res.redirect(301, "/terms"));

app.get("/v1/metals", async (_req, res) => {
  try {
    if (metalsCache && Date.now() - metalsCache.fetchedAt < 60 * 60 * 1000) {
      return res.json(metalsCache.quote);
    }
    const [gold, silver] = await Promise.all([
      fetch("https://api.gold-api.com/price/XAU").then((r) => r.json()),
      fetch("https://api.gold-api.com/price/XAG").then((r) => r.json()),
    ]);
    const quote = {
      gold_per_gram: Number(gramsFromTroyOunce(gold.price).toFixed(4)),
      silver_per_gram: Number(gramsFromTroyOunce(silver.price).toFixed(4)),
      source: "gold-api.com",
      updated_at: new Date().toISOString(),
    };
    metalsCache = { fetchedAt: Date.now(), quote };
    res.json(quote);
  } catch (error) {
    if (metalsCache) return res.json(metalsCache.quote);
    res.status(503).json({ error: "Metal prices unavailable" });
  }
});

app.post("/v1/auth/register", (req, res) => {
  try {
    const fullName = String(req.body?.full_name ?? "");
    const email = String(req.body?.email ?? "");
    const password = String(req.body?.password ?? "");
    if (fullName.trim().length < 2) return res.status(400).json({ error: "Enter your name." });
    if (!email.includes("@")) return res.status(400).json({ error: "Enter a valid email address." });
    if (password.length < 8) return res.status(400).json({ error: "Password must be at least 8 characters." });
    const user = store.createUser(fullName, email, password);
    const token = store.createSession(user.id);
    res.status(201).json(publicUserPayload(user, token));
  } catch (error) {
    res.status(error.status ?? 400).json({ error: error.message });
  }
});

app.post("/v1/auth/login", (req, res) => {
  try {
    const user = store.authenticate(String(req.body?.email ?? ""), String(req.body?.password ?? ""));
    const token = store.createSession(user.id);
    res.json(publicUserPayload(user, token));
  } catch (error) {
    res.status(error.status ?? 401).json({ error: error.message });
  }
});

app.get("/v1/me", requireUser, (req, res) => {
  res.json({ user: req.user });
});

app.delete("/v1/me", requireUser, (req, res) => {
  store.deleteUser(req.user.id);
  res.json({ ok: true });
});

app.get("/v1/snapshot", requireUser, (req, res) => {
  const items = store.itemsForUser(req.user.id);
  res.json({
    ...snapshotFromItems(items),
    linked_institutions: items.map((item) => ({
      id: item.institution_id,
      name: item.institution_name,
    })),
  });
});

app.post("/v1/link/token", requireUser, async (req, res) => {
  try {
    if (usePlaid) {
      const created = await plaidRequest("/link/token/create", {
        user: { client_user_id: req.user.id },
        client_name: "Zakat",
        products: ["transactions"],
        country_codes: ["US"],
        language: "en",
      });
      return res.json({ link_token: created.link_token, mode: "plaid", institutions });
    }
    res.json({ link_token: "sandbox-link-token", mode: "sandbox", institutions });
  } catch (error) {
    res.json({ link_token: "sandbox-link-token", mode: "sandbox", institutions });
  }
});

app.post("/v1/link/complete", requireUser, (req, res) => {
  const institutionID = req.body?.institution_id ?? "chase";
  const item = persistSandboxItem(req.user.id, institutionID);
  res.json(item);
});

app.delete("/v1/link/:institutionId", requireUser, (req, res) => {
  store.deleteItem(req.user.id, req.params.institutionId);
  res.json({ ok: true });
});

app.post("/link/token", async (_req, res) => {
  res.json({ link_token: "sandbox-link-token", mode: "sandbox", institutions });
});

app.post("/link/complete", (req, res) => {
  const institutionID = req.body?.institution_id ?? "chase";
  const item = catalogItem(institutionID);
  item.transactions = generateTransactions(item.institution_id);
  res.json(item);
});

app.listen(port, "0.0.0.0", () => {
  console.log(`Zakat API on http://0.0.0.0:${port} (${usePlaid ? "plaid" : "sandbox"})`);
});
