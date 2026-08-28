import SwiftUI
import ZakatEngine

struct HistoryView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        ZStack {
            ScreenBackground()
            if session.history.isEmpty {
                VStack(spacing: 10) {
                    Text("No saved estimates")
                        .font(.headline)
                    Text("Open a result to save it here.")
                        .font(.subheadline)
                        .foregroundStyle(Palette.muted)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
            } else {
                List {
                    ForEach(session.history) { snapshot in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(snapshot.formattedDue)
                                .font(.headline)
                            Text("\(snapshot.createdAt.formatted(date: .abbreviated, time: .shortened)) · \(snapshot.mode)")
                                .font(.caption)
                                .foregroundStyle(Palette.muted)
                            Text("Net \(Money.display(snapshot.netZakatable, currencyCode: snapshot.currencyCode))")
                                .font(.subheadline)
                                .foregroundStyle(Palette.muted)
                        }
                        .listRowBackground(Color.white.opacity(0.6))
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FAQView: View {
    private let items: [(String, String)] = [
        ("Do I need an account?", "No. v1 is offline only. Bank linking is coming soon."),
        ("Is this a fatwa?", "No. It is an estimate. Confirm with a scholar you trust."),
        ("Where is my data?", "Holdings stay on this iPhone."),
        ("How do I delete my data?", "Clear holdings in the calculator, or uninstall the app."),
        ("What is nisab?", "A minimum threshold: 87.48 g gold or 612.36 g silver."),
        ("What is hawl?", "A lunar year, treated here as 354 days."),
        ("Is zakat 2.5% of my gain?", "No. It is 2.5% of wealth now, if you are above nisab."),
    ]

    var body: some View {
        ZStack {
            ScreenBackground()
            List {
                ForEach(items, id: \.0) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.0)
                            .font(.headline)
                        Text(item.1)
                            .font(.subheadline)
                            .foregroundStyle(Palette.muted)
                    }
                    .listRowBackground(Color.white.opacity(0.6))
                    .padding(.vertical, 4)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("FAQ")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SupportView: View {
    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Version \(AppConfig.version)")
                        .font(.subheadline)
                        .foregroundStyle(Palette.muted)
                    Text("Questions or data deletion: email us. Don’t send passwords.")
                        .font(.body)
                        .foregroundStyle(Palette.muted)
                    if let url = URL(string: "mailto:\(AppConfig.supportEmail)") {
                        Link(destination: url) {
                            Text("Email \(AppConfig.supportEmail)")
                                .font(.headline)
                                .foregroundStyle(Palette.cream)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Palette.forest, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                    NavigationLink {
                        FAQView()
                    } label: {
                            ProfileRow(title: "FAQ", systemImage: "questionmark.circle")
                    }
                    .buttonStyle(.plain)
                    NavigationLink {
                        LegalIndexView()
                    } label: {
                        ProfileRow(title: "Legal", systemImage: "doc.text")
                    }
                    .buttonStyle(.plain)
                }
                .padding(24)
            }
        }
        .navigationTitle("Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ResetPasswordView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var confirm = ""
    @State private var message: String?
    @State private var isError = false

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Only for a profile saved on this iPhone.")
                        .font(.subheadline)
                        .foregroundStyle(Palette.muted)
                    LabeledField(title: "Email", placeholder: "you@example.com", text: $email, keyboard: .emailAddress, contentType: .emailAddress)
                    LabeledField(title: "New password", placeholder: "8+ characters", text: $password, isSecure: true, contentType: .newPassword)
                    LabeledField(title: "Confirm", placeholder: "Re-enter password", text: $confirm, isSecure: true, contentType: .newPassword)
                    if let message {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(isError ? Palette.rust : Palette.forest)
                    }
                    PrimaryButton(title: "Reset password") {
                        do {
                            try session.resetPassword(email: email, newPassword: password, confirmPassword: confirm)
                            isError = false
                            message = "Password updated."
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { dismiss() }
                        } catch {
                            isError = true
                            message = error.localizedDescription
                        }
                    }
                }
                .padding(24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Reset password")
        .navigationBarTitleDisplayMode(.inline)
    }
}
