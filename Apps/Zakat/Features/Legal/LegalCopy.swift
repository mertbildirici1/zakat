import Foundation

enum LegalDocument: String, CaseIterable, Identifiable {
    case terms
    case privacy
    case disclaimer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .terms: return "Terms of Use"
        case .privacy: return "Privacy Policy"
        case .disclaimer: return "Zakat Disclaimer"
        }
    }

    var body: String {
        switch self {
        case .terms: return LegalCopy.terms
        case .privacy: return LegalCopy.privacy
        case .disclaimer: return LegalCopy.disclaimer
        }
    }
}

enum AppConfig {
    static let appName = "Zakat"
    static let operatorName = "the developer of Zakat"
    static let supportEmail = "support@zakat.app"
    static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
}

enum LegalCopy {
    static let lastUpdated = "August 27, 2026"

    static let terms = """
Last updated: \(lastUpdated)

These Terms of Use (“Terms”) govern your use of the Zakat mobile application (the “App”). By downloading, accessing, or using the App, you agree to these Terms. If you do not agree, do not use the App.

1. Who we are
The App is provided by \(AppConfig.operatorName) (“we,” “us”). It is a personal-finance tool that estimates zakat. It is not a bank, broker, tax advisor, or religious authority.

2. Eligibility
You must be at least 18 years old to create an account. You are responsible for the information you enter and for keeping this device secure.

3. The service
The App lets you:
• estimate zakat from amounts you enter yourself (offline mode);
• optionally create a local profile on this device;
• optionally connect financial accounts through a linking provider (when configured) to prefill balances that you then review.

The App may fetch public metal prices from a network service. Offline calculation still works if the network is unavailable.

4. Not advice
All results are estimates only. They are not a fatwa, legal opinion, tax opinion, or professional advice. Schools of Islamic law differ on nisab, jewelry, retirement accounts, debts, and other issues. Confirm amounts with a qualified scholar and, where relevant, a licensed professional before you pay or file anything.

5. Accounts
Profiles created in the App are stored on this iPhone. We do not operate a cloud login in this version. Anyone with access to your unlocked device may be able to use a local profile. You may delete your local account at any time from Profile.

6. Connected accounts
If you link a bank or brokerage, you authorize the linking provider (for example Plaid) and our backend to retrieve account names and balances so the App can map them into zakat categories. You must review every imported line. You can unlink accounts in the App. The linking provider’s terms also apply.

7. Acceptable use
You agree not to misuse the App, attempt to disrupt it, or use it to violate law. You will not submit information you do not have the right to provide.

8. Intellectual property
The App, its design, and its content are owned by us or our licensors. You receive a personal, non-exclusive, non-transferable license to use the App on Apple devices you own or control, in line with the App Store terms.

9. Disclaimer of warranties
THE APP IS PROVIDED “AS IS.” TO THE FULLEST EXTENT PERMITTED BY LAW, WE DISCLAIM ALL WARRANTIES, EXPRESS OR IMPLIED, INCLUDING MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT. We do not warrant that estimates are complete, that metal prices are accurate, or that connected balances are current.

10. Limitation of liability
TO THE FULLEST EXTENT PERMITTED BY LAW, WE ARE NOT LIABLE FOR INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, OR FOR LOST PROFITS, DATA, OR CHARITABLE UNDER- OR OVER-PAYMENT, ARISING FROM YOUR USE OF THE APP. OUR TOTAL LIABILITY FOR ANY CLAIM RELATING TO THE APP WILL NOT EXCEED USD $50.

11. Indemnity
You will indemnify us against claims arising from your misuse of the App, your entered data, or your distribution of zakat based on an estimate.

12. Changes and termination
We may update these Terms. Continued use after an update means you accept the revised Terms. We may stop offering features. You may stop using the App at any time and delete your local data.

13. Governing law
These Terms are governed by the laws of the United States and the state in which the operator resides, without regard to conflict-of-law rules. If a consumer protection law in your place of residence requires a different result, that law applies to the extent required.

14. Contact
Questions: \(AppConfig.supportEmail)
"""

    static let privacy = """
Last updated: \(lastUpdated)

This Privacy Policy explains how the Zakat app (“App”) handles information. The App is designed so that your holdings and profile can stay on your iPhone.

1. What we mean by “collect”
Apple treats data as “collected” when it is transmitted off the device in a way that we or a partner can access. Calculation drafts, local profiles, and history that never leave your phone are stored on-device only.

2. Information on your device
Depending on how you use the App, it may store on this iPhone:
• your name, email, and a hashed password for a local profile;
• zakat holdings you enter (cash, metals, investments, debts, and similar);
• linked account names and balances you imported;
• calculation history and your nisab / hawl preferences;
• whether you accepted these legal terms.

Passwords are stored as a salted hash, not in plain text. We cannot recover a forgotten password from a server because there is no cloud account in this version. You can reset a local password on this device if you still know the email.

3. Information that may leave the device
• Metal prices. The App or its backend may request public gold and silver spot prices. That request does not include your holdings.
• Connected accounts. If you choose to link a bank, brokerage, or crypto venue, account identifiers and balances are retrieved through the linking provider (such as Plaid) and our backend so they can be shown to you. Do not link accounts unless you accept that provider’s privacy policy as well.
• Support. If you email \(AppConfig.supportEmail), we receive whatever you send.

We do not sell your information. We do not use your data for advertising. We do not track you across apps or websites.

4. Account deletion
You can delete a local profile from Profile → Delete account. That removes the profile and its saved estimate from this iPhone. Uninstalling the App also removes local App data.

5. Children
The App is not directed to children under 13, and we do not knowingly collect personal information from children.

6. International
The App is intended for use where Apple makes it available. Metal-price and linking providers may process data in the United States or other countries.

7. Changes
We may update this Policy. The “Last updated” date will change. Material changes will be presented in the App when we can.

8. Contact
\(AppConfig.supportEmail)
"""

    static let disclaimer = """
Last updated: \(lastUpdated)

Zakat is an act of worship with legal and spiritual conditions that this App cannot decide for you.

The App estimates 2.5% of net zakatable wealth against a gold or silver nisab using rules you can change in Settings. Defaults (including jewelry, retirement accounts, and which debts are deducted) are engineering choices, not a ruling of a madhhab.

A lunar year (hawl) of 354 days is offered as a reminder only. Whether your wealth has been above nisab for a full hawl is your determination.

Do not rely on this App as a substitute for a scholar, an accountant, or your own records. If an estimate and your circumstances disagree, follow qualified guidance.

By using the App you acknowledge this disclaimer.
"""
}
