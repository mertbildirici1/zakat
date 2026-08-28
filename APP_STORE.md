# App Store submission (v1)

v1 is **offline only**. Bank linking is gated behind Coming soon. No Plaid, Render, or hosted accounts are required to ship.

Privacy and support URLs:

- Support: `https://mertbildirici1.github.io/zakat/`
- Privacy: `https://mertbildirici1.github.io/zakat/privacy.html`

Turn on GitHub Pages: repo **Settings → Pages → Deploy from a branch → `main` / `docs`**.

## Apple steps (you)

1. [developer.apple.com](https://developer.apple.com) → Membership → confirm **Active** → copy **Team ID**.
2. Identifiers → **+** → App IDs → App → explicit bundle ID `app.zakat.calculator` (no extra capabilities).
3. [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → My Apps → **+** → New App:
   - Platform: iOS
   - Name: Zakat (if taken: Zakat Calculator)
   - Primary language: English (US)
   - Bundle ID: `app.zakat.calculator`
   - SKU: `zakat`
4. In Xcode: open `Zakat.xcodeproj` → Signing & Capabilities → Team. Product → Archive → Distribute App → App Store Connect.
5. Paste the listing below. Category: **Finance**. Price: **Free**.
6. Export compliance: encryption used only for HTTPS (`ITSAppUsesNonExemptEncryption` is already NO).
7. Screenshots: iPhone 6.7" and 6.1". Capture Welcome, holdings, result, settings.

## Listing

**Name:** Zakat  
**Subtitle:** Estimate what you owe  
**Promotional text:** Enter your holdings on this iPhone and estimate 2.5% of net zakatable wealth. No account required.

**Description:**

Zakat helps you estimate 2.5% of net zakatable wealth. Everything stays on this iPhone.

• Enter cash, gold, silver, investments, crypto, business inventory, receivables, and debts.  
• Gold or silver nisab, karat-aware gold, and settings for jewelry, retirement accounts, and debts.  
• A 354-day hawl reminder.  
• Optional live metal prices when a network is available.

This is an estimate, not a fatwa. Confirm with a scholar you trust before you distribute.

**Keywords:** zakat,nisab,islam,charity,gold,calculator,finance,sadaqah,hawl,muslim  
**Support email:** hmertbildirici@gmail.com  
**Privacy URL:** https://mertbildirici1.github.io/zakat/privacy.html  
**Support URL:** https://mertbildirici1.github.io/zakat/

## App privacy (nutrition labels)

Data not collected. Tracking: No.

Do not declare Contact Info or Financial Info as collected. Holdings stay on device. Support email is outside the app.

## Review notes

v1 is offline. Tap Continue offline after accepting legal documents. Sign in / Create account show Coming soon and return to the offline calculator. There is no demo account and no bank login to review.

## Legal

Terms, privacy, and the zakat disclaimer ship in the app (first launch + Settings → Legal) and at the GitHub Pages URLs above.
