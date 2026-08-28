# App Store submission

Zakat is ready to archive once you have an Apple Developer account ($99/year) and a public HTTPS backend for the privacy policy URL.

## You must do in Apple’s tools

1. Open `Zakat.xcodeproj` in Xcode.
2. Signing & Capabilities → your Team. Change the bundle ID from `app.zakat.calculator` if that ID is taken.
3. For a **Release** build, set `API_BASE_URL` on the Zakat target to your deployed backend (see `backend/render.yaml`). Debug already uses `http://127.0.0.1:8787`.
4. Product → Archive → Distribute App → App Store Connect.
5. In App Store Connect, create the app (category: Finance). Paste the listing copy below.
6. Privacy Policy URL: `https://YOUR-BACKEND/privacy`  
   Support URL: `https://YOUR-BACKEND/`  
   Marketing URL: optional.
7. Export compliance: the app uses HTTPS only. Answer that you use encryption only for HTTPS (ITSAppUsesNonExemptEncryption is already NO).
8. Attach screenshots (iPhone 6.7" and 6.1" at minimum). Capture Welcome, Offline gateway, Calculator, Result, Profile.

## Listing

**Name:** Zakat  
**Subtitle:** Estimate what you owe  
**Promotional text:** Calculate zakat offline, or sign in on this iPhone to link accounts and review every line.

**Description:**

Zakat helps you estimate 2.5% of net zakatable wealth.

• Offline mode — enter cash, gold, silver, investments, crypto, business inventory, receivables, and debts. Nothing is required to leave your iPhone.  
• Optional local profile — save a name on this device, link banks when you choose, and keep history.  
• Gold or silver nisab, karat-aware gold, and settings for jewelry, retirement accounts, and debts.  
• Optional live metal prices and a 354-day hawl reminder.

This is an estimate, not a fatwa. Confirm with a scholar you trust before you distribute.

**Keywords:** zakat,nisab,islam,charity,gold,calculator,finance,sadaqah,hawl,muslim  
**Support email:** hmertbildirici@gmail.com

## App privacy (nutrition labels)

Data not collected for tracking.

On-device only (not “collected” off device unless the user links banks or emails support):
• Contact Info (name, email) — App Functionality, not linked to identity off-device, not used for tracking.  
• Financial Info (holdings the user enters) — App Functionality.

If the user links accounts, the linking provider (Plaid) and your backend receive account names and balances. Disclose that third party in App Store Connect.

## Review notes

The calculator works without an account (Continue offline).  
Demo local account: create any email on the simulator; passwords never leave the device.  
Bank linking uses sandbox institutions unless PLAID_CLIENT_ID and PLAID_SECRET are set on the backend.  
Please do not require a production Plaid login; sandbox cards are enough to review mapping.

## Legal

Terms, privacy, and the zakat disclaimer ship in the app (first launch + Profile → Legal) and on the backend (`/terms`, `/privacy`, `/disclaimer`). Have a lawyer review before you rely on them in production.
