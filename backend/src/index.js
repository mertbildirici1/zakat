import cors from "cors";
import express from "express";
import { disclaimerPage, privacyPage, supportPage, termsPage } from "./legal.js";

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
app.use(express.json({ limit: "32kb" }));

const hits = new Map();
app.use((req, res, next) => {
  const key = req.ip ?? "unknown";
  const now = Date.now();
  const windowMs = 60_000;
  const entry = hits.get(key);
  if (!entry || now - entry.start > windowMs) {
    hits.set(key, { start: now, count: 1 });
    return next();
  }
  entry.count += 1;
  if (entry.count > 120) {
    return res.status(429).json({ error: "Too many requests" });
  }
  next();
});

const institutions = [
  { id: "chase", name: "Chase", detail: "Checking, savings, and a credit card" },
  { id: "fidelity", name: "Fidelity", detail: "Brokerage and 401(k)" },
  { id: "coinbase", name: "Coinbase", detail: "Crypto wallet" },
];

const catalog = {
  chase: item("item-chase", "Chase", [
    account("ch-checking", "Chase", "Total Checking", "1234", "checking", 4250),
    account("ch-savings", "Chase", "Savings", "9876", "savings", 12800),
    account("ch-card", "Chase", "Freedom", "4411", "credit", -1240),
  ]),
  fidelity: item("item-fidelity", "Fidelity", [
    account("fid-brokerage", "Fidelity", "Brokerage", "8821", "brokerage", 33100),
    account("fid-401k", "Fidelity", "401(k)", "1044", "retirement", 88000),
  ]),
  coinbase: item("item-coinbase", "Coinbase", [
    account("cb-btc", "Coinbase", "Bitcoin", null, "crypto", 2140),
  ]),
};

let metalsCache = null;

function account(id, institutionName, name, mask, type, currentBalance) {
  return {
    id,
    institution_name: institutionName,
    name,
    mask,
    type,
    current_balance: currentBalance,
    iso_currency_code: "USD",
  };
}

function item(itemId, institutionName, accounts) {
  return { item_id: itemId, institution_name: institutionName, accounts };
}

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
    const error = new Error(json.error_message ?? "Plaid request failed");
    error.payload = json;
    throw error;
  }
  return json;
}

function mapPlaidAccount(institutionName, raw) {
  const type = String(raw.type ?? "other").toLowerCase();
  const subtype = String(raw.subtype ?? "").toLowerCase();
  let mapped = "other";
  if (type === "depository") mapped = subtype === "savings" ? "savings" : "checking";
  else if (type === "investment") mapped = ["401k", "403b", "ira", "roth", "pension"].includes(subtype)
    ? "retirement"
    : "brokerage";
  else if (type === "credit") mapped = "credit";
  else if (type === "loan") mapped = "loan";
  const balance = raw.balances?.current ?? 0;
  return account(raw.account_id, institutionName, raw.name ?? "Account", raw.mask ?? null, mapped, balance);
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
    res.status(503).json({ error: "Metal prices unavailable", detail: String(error.message ?? error) });
  }
});

app.post("/link/token", async (_req, res) => {
  try {
    if (usePlaid) {
      const created = await plaidRequest("/link/token/create", {
        user: { client_user_id: "zakat-user" },
        client_name: "Zakat",
        products: ["transactions"],
        optional_products: ["investments"],
        country_codes: ["US"],
        language: "en",
      });
      return res.json({
        link_token: created.link_token,
        mode: "plaid",
        institutions,
      });
    }
    res.json({ link_token: "sandbox-link-token", mode: "sandbox", institutions });
  } catch (error) {
    res.status(502).json({ error: error.message, mode: "sandbox", institutions, link_token: "sandbox-link-token" });
  }
});

app.post("/link/complete", async (req, res) => {
  try {
    if (usePlaid && req.body?.public_token && req.body.public_token !== "sandbox-link-token") {
      const exchanged = await plaidRequest("/item/public_token/exchange", {
        public_token: req.body.public_token,
      });
      const accounts = await plaidRequest("/accounts/get", {
        access_token: exchanged.access_token,
      });
      const institutionName = accounts.item?.institution_id ?? "Linked institution";
      return res.json({
        item_id: exchanged.item_id,
        institution_name: institutionName,
        accounts: (accounts.accounts ?? []).map((row) => mapPlaidAccount(institutionName, row)),
      });
    }
    const institutionID = req.body?.institution_id ?? "chase";
    res.json(catalog[institutionID] ?? catalog.chase);
  } catch (error) {
    res.status(502).json({ error: error.message });
  }
});

app.listen(port, () => {
  console.log(`Zakat API on http://127.0.0.1:${port} (${usePlaid ? "plaid" : "sandbox"})`);
});
