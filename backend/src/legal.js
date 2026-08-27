const LEGAL_CSS = `
  :root { color-scheme: light; }
  body { font-family: ui-serif, Georgia, serif; background: #F7F3E8; color: #1F2421; margin: 0; }
  main { max-width: 42rem; margin: 0 auto; padding: 2.5rem 1.25rem 4rem; }
  a { color: #17362D; }
  h1 { font-size: 2rem; color: #17362D; }
  p, li { line-height: 1.55; }
  .muted { color: #656A66; }
  nav a { margin-right: 1rem; }
`;

function page(title, bodyHtml) {
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>${title} · Zakat</title>
  <style>${LEGAL_CSS}</style>
</head>
<body>
  <main>
    <nav>
      <a href="/">Support</a>
      <a href="/privacy">Privacy</a>
      <a href="/terms">Terms</a>
      <a href="/disclaimer">Disclaimer</a>
    </nav>
    <h1>${title}</h1>
    ${bodyHtml}
  </main>
</body>
</html>`;
}

export function supportPage() {
  return page(
    "Zakat support",
    `<p class="muted">Version 1.0. A zakat estimate helper for iPhone.</p>
     <p>Email <a href="mailto:support@zakat.app">support@zakat.app</a> for product questions, bugs, or a data-deletion request. Include your iOS version. Do not send passwords.</p>
     <p>Offline calculation does not require an account. Local profiles live on your iPhone until you delete them in the app or uninstall.</p>`
  );
}

export function privacyPage() {
  return page(
    "Privacy Policy",
    `<p class="muted">Last updated: August 27, 2026</p>
     <p>This Privacy Policy explains how the Zakat app (“App”) handles information. The App is designed so that your holdings and profile can stay on your iPhone.</p>
     <p><strong>1. What we mean by “collect.”</strong> Apple treats data as collected when it is transmitted off the device in a way that we or a partner can access. Calculation drafts, local profiles, and history that never leave your phone are stored on-device only.</p>
     <p><strong>2. Information on your device.</strong> The App may store your name, email, a hashed password, zakat holdings, linked account names and balances, history, nisab and hawl preferences, and legal acceptance. Passwords are salted hashes. There is no cloud account in this version.</p>
     <p><strong>3. Information that may leave the device.</strong> Metal-price requests do not include your holdings. If you link a bank, a linking provider (such as Plaid) and our backend retrieve account names and balances for you to review. If you email support@zakat.app, we receive what you send. We do not sell information, advertise with it, or track you across apps.</p>
     <p><strong>4. Account deletion.</strong> Profile → Delete account removes the local profile from this iPhone. Uninstalling the App also removes local App data.</p>
     <p><strong>5. Children.</strong> The App is not directed to children under 13.</p>
     <p><strong>6. Contact.</strong> support@zakat.app</p>`
  );
}

export function termsPage() {
  return page(
    "Terms of Use",
    `<p class="muted">Last updated: August 27, 2026</p>
     <p>By using the Zakat app you agree to these Terms. If you do not agree, do not use the App.</p>
     <p><strong>1. Who we are.</strong> The App is a personal-finance tool that estimates zakat. It is not a bank, broker, tax advisor, or religious authority.</p>
     <p><strong>2. Eligibility.</strong> You must be at least 18 to create an account.</p>
     <p><strong>3. The service.</strong> Offline entry, optional local profiles, optional account linking, and optional metal-price refresh.</p>
     <p><strong>4. Not advice.</strong> Results are estimates, not a fatwa or professional advice. Confirm with a qualified scholar before paying.</p>
     <p><strong>5. Accounts.</strong> Profiles are stored on this iPhone. You may delete a local account from Profile.</p>
     <p><strong>6. Connected accounts.</strong> Linking authorizes the provider and our backend to retrieve balances. You must review every imported line.</p>
     <p><strong>7. Acceptable use.</strong> Do not misuse the App or submit information you lack the right to provide.</p>
     <p><strong>8. Warranties and liability.</strong> THE APP IS PROVIDED “AS IS.” TO THE FULLEST EXTENT PERMITTED BY LAW WE DISCLAIM IMPLIED WARRANTIES AND ARE NOT LIABLE FOR INDIRECT DAMAGES OR FOR UNDER- OR OVER-PAYMENT OF ZAKAT. TOTAL LIABILITY WILL NOT EXCEED USD $50.</p>
     <p><strong>9. Contact.</strong> support@zakat.app</p>`
  );
}

export function disclaimerPage() {
  return page(
    "Zakat Disclaimer",
    `<p class="muted">Last updated: August 27, 2026</p>
     <p>Zakat is an act of worship with conditions this App cannot decide for you.</p>
     <p>The App estimates 2.5% of net zakatable wealth against a gold or silver nisab using rules you can change in Settings. Defaults are engineering choices, not a ruling of a madhhab.</p>
     <p>A lunar year (hawl) of 354 days is a reminder only. Do not rely on this App as a substitute for a scholar or your own records.</p>`
  );
}
