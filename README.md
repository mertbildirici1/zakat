# Zakat

iPhone app to estimate zakat — offline, or with a local profile and optional bank linking.

Open `Zakat.xcodeproj` in Xcode, select your signing team, and run the **Zakat** scheme.

## Run locally

```bash
swift test
cd backend && npm install && npm start
```

The iOS debug build talks to `http://127.0.0.1:8787` for metal prices, legal URLs, and sandbox bank linking. The calculator works if the backend is down.

## What you get

- First-launch Terms, Privacy Policy, and Zakat Disclaimer
- Offline path with no account
- Sign in / create account / reset password / delete account (on-device)
- Manual holdings, result, share, history, hawl reminder
- Optional live gold/silver prices and Plaid-style linking
- App icon, privacy manifest, finance category, export-compliance flag
- Backend you can deploy (Docker / Render) so App Store has public `/privacy` and `/terms` URLs

Publishing steps, listing copy, and privacy nutrition answers: [APP_STORE.md](APP_STORE.md).  
Architecture and fiqh defaults: [IMPLEMENTATION.md](IMPLEMENTATION.md).

This is an estimate, not a fatwa.
