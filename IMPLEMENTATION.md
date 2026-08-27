# Zakat app — implementation plan

This is the working plan for the iOS zakat calculator in this folder. The first slice is already in the repo: a testable calculation engine, a SwiftUI app with both entry modes, and a local linking backend.

The app is an **estimate helper**, not a fatwa. Defaults are documented below so they can be changed when you pick a scholarly view.

## Product

Two ways to reach the same result screen:

1. **Manual / offline** — the user enters holdings by category. No network. Drafts stay on device.
2. **Connected** — the user links banks, brokerages, and crypto (Plaid-style), reviews the mapped lines, then adds anything Plaid cannot see (cash, gold, private loans).

Both modes share one `ZakatDraft` and one `ZakatCalculator`. Connected mode never bypasses review: retirement accounts and long-term loans arrive **excluded** until the user turns them on.

### First-run experience

```
Home
 ├─ Manual entry → category editors → live total → Result
 ├─ Connect accounts → link session → institution → mapped lines → Manual entry / Result
 └─ Settings → nisab standard, metal prices, include/exclude rules
```

## Zakat rules this version implements

These are engineering defaults. Call them out in the UI (already on the result screen).

| Topic | Default | Why |
| --- | --- | --- |
| Rate | 2.5% (1/40) | Standard rate for cash, trade wealth, gold, silver |
| Gold nisab | 87.48 g | Common conversion of 7.5 tola / 20 dinars |
| Silver nisab | 612.36 g | Common conversion of 52.5 tola / 200 dirhams |
| Which nisab | Gold, user-selectable | Silver nisab is much lower at today's prices; do not hide that |
| Hawl | Snapshot "if I paid today" | Lunar-year tracking is phase 2 |
| Gold/silver | Weight × (karat/24) × price/gram | Purity matters; dollar-only entry can be added later |
| Personal jewelry | Included, toggle to exclude | Hanafi-leaning default; Shafi'i/Maliki often exempt personal jewelry |
| Retirement accounts | Present, **off** | Accessibility differs; user must opt in |
| Debts | Immediate debts deducted; mortgages/loans off unless setting changed | Avoid wiping zakat with a home loan |
| Primary home, cars, furniture | Not in the model | Personal use assets, out of scope |
| Agriculture / livestock | Out of scope | Different rates; this is a personal-finance calculator |

**Zakatable net wealth**

```
cash on hand
+ bank deposits
+ gold value (respect jewelry toggle)
+ silver value
+ investments
+ retirement (only if enabled)
+ crypto
+ business inventory / trade goods
+ receivables likely collectible
− immediate debts (and long-term debts only if enabled)

if net >= selected nisab: due = round(net × 0.025, cents)
else: due = 0
```

Result UI always shows **both** gold and silver nisab values so the user can see the gap.

## Architecture

```
ZakatEngine (Swift package, iOS + macOS)
  models, calculator, Plaid-type → category mapper
  unit tests via `swift test`

Apps/Zakat (SwiftUI, iOS 17+)
  Home / Manual / Connected / Result / Settings
  BankLinkClient protocol
    LiveBankLinkClient → local backend
    OfflineSandboxBankLinkClient → built-in demo data

backend/ (Node)
  POST /link/token
  POST /link/complete
  sandbox now; real Plaid secrets stay here, never in the app
```

### Why the engine is a package

Zakat math should be testable without the simulator. The iOS app is a client of `ZakatEngine`. If a number is wrong, it is wrong in one place.

### Data flow

```
User edits draft  ─┐
Linked accounts  ─┼→ ZakatDraft → ZakatCalculator → ZakatResult
Settings         ─┘                     │
                                        ▼
                               UserDefaults snapshot
```

`AccountCategoryMapper` replaces previous **linked** rows but keeps **manual** rows. That is how someone can connect Chase and still type gold by hand.

Plaid-style mapping:

| Plaid type / subtype | Zakat bucket | Included by default |
| --- | --- | --- |
| depository checking/savings | Bank deposits | Yes |
| investment (brokerage) | Investments | Yes |
| investment 401k/IRA/403b | Retirement | No |
| crypto | Crypto | Yes |
| credit | Immediate debts | Yes (absolute balance) |
| loan / mortgage | Long-term debts | No |

## Connected accounts and Plaid

Plaid **must not** live only on the phone.

```
iOS                         backend                         Plaid
 |  POST /link/token          |  linkTokenCreate (sandbox/prod)
 | ← link_token               |
 |  LinkKit / sandbox picker  |
 |  POST /link/complete       |  itemPublicTokenExchange
 | ← accounts + balances      |  accountsGet / investmentsHoldingsGet
```

**Security rules**

- `PLAID_SECRET` only on the server (see `backend/.env.example`).
- The app stores balances in the local draft, not the Plaid access token, in this phase.
- Phase 2: keep `access_token` in Keychain if you add refresh; still never ship the secret in the IPA.
- Production Plaid requires a legal entity, privacy policy, and often a backend hosted with TLS. Sandbox is enough to build UX.

**What is in this repo today**

- Protocol + live HTTP client + offline fallback.
- Backend that returns Chase / Fidelity / Coinbase sandbox balances.
- UI that explains the Plaid pattern and lets you review mapped lines.
- Next wiring: add [LinkKit](https://github.com/plaid/plaid-link-ios-spm) (v7 session API, iOS 15+, Xcode 16.1), create a real `link_token` when `PLAID_CLIENT_ID` / `PLAID_SECRET` are set, present `Plaid.createPlaidLinkSession`, then exchange `public_token` on the server.

Do not add LinkKit until you have sandbox keys; the app is usable without them.

## iOS app structure

```
Apps/Zakat
  ZakatApp.swift
  App/           session + root navigation
  Design/        palette, buttons, amount fields
  Data/          draft persistence, bank link clients
  Features/
    Home         choose a mode
    Manual       all categories, live footer
    Connected    link session + institution picker
    Result       due amount, nisab, breakdown
    Settings     nisab, metal prices, inclusion toggles
```

Stack: SwiftUI, `@Observable`, iOS 17, portrait iPhone. Persistence is `UserDefaults` JSON for speed; SwiftData can replace it when history / multiple years exist.

## Phased roadmap

### Phase 0 — this folder (done)

- Domain engine and tests
- Manual calculator UI
- Connected sandbox (backend + offline fallback)
- Settings for nisab and inclusion rules
- Result breakdown and disclaimer

### Phase 1 — make the calculator feel finished

- Currency picker and locale-aware input
- Gold/silver by dollar value as well as grams
- Saved calculation history and share sheet
- App icon, launch screen, Dynamic Type pass
- Accessibility: VoiceOver labels on every amount field

### Phase 2 — real Plaid

- Node (or another) host with TLS
- `linkTokenCreate` + `itemPublicTokenExchange` + `accountsGet`
- Investments product for brokerage cost/quantity if you need more than cash balance
- LinkKit 7 SwiftUI session
- Disconnect / unlink institution
- Error states: login required, product not supported, institution down

### Phase 3 — zakat-year product

- Hawl start date and 354-day reminder
- Live metal prices (cached for offline)
- Multiple madhhab presets (Hanafi jewelry on, others off, etc.)
- Optional zakat-eligible investment screening (later, high controversy)

### Phase 4 — ship

- Privacy nutrition labels (financial info)
- Account deletion / data export
- Scholar review of copy
- App Store screenshots and a real privacy policy URL (Plaid will require this)

## Privacy and compliance

The manual path should remain fully functional if the user refuses linking. That is both a product requirement and a Plaid/App Store reality.

Connected mode is **data minimization**: balances and account names, not full transaction history, unless a later feature needs cash-flow for hawl. Say that in the connect screen before Link opens.

## Testing strategy

- Engine: edge cases around nisab, karat, excluded retirement, debts, linked vs manual merge (`swift test`).
- App: walk Home → Manual (example data) → Result; Home → Connect (offline sandbox) → Review.
- Backend: `/health`, `/link/token`, `/link/complete` with each institution id.

## Open decisions for you

1. **Default nisab** — gold (current) vs silver vs “show both, user picks at result time.”
2. **Jewelry** — keep included-by-default or flip it off.
3. **Retirement** — stay opt-in, or add a “accessible now” vs “locked” split.
4. **Plaid timing** — stay on sandbox until you have a company entity, or apply for Plaid sandbox this week.
5. **Backend language** — Node is already here; swap for Swift/Vapor later if you want one language.

Until those change, the code follows the table at the top of this document.
