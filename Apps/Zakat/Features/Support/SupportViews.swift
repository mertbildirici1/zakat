import SwiftUI
import ZakatEngine

struct HistoryView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        ZStack {
            ScreenBackground()
            if session.history.isEmpty {
                VStack(spacing: 10) {
                    Text("No saved estimates yet")
                        .font(.headline)
                    Text("Open a result and it will be stored on this phone.")
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
        ("Do I need an account?", "No. Continue offline to calculate without a profile. Create an account only if you want a named profile and connected banks on this phone."),
        ("Is this a fatwa?", "No. It is an estimate helper. Confirm with a scholar you trust."),
        ("Where is my data?", "Holdings, history, and local passwords stay on this iPhone. Metal prices and optional bank linking use the network."),
        ("How do I delete my account?", "Signed-in: Profile → Delete account. That removes the local profile from this device."),
        ("What is nisab?", "A minimum threshold. This App uses 87.48 g of gold or 612.36 g of silver, converted at the prices you set or refresh."),
        ("What is hawl?", "A lunar year, treated here as 354 days from the start date you record. The reminder is optional."),
        ("Forgot password?", "On the sign-in screen, reset the local password if this device still has that email."),
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
                    Text("For product questions, bugs, or data-deletion requests, email us. Include your iOS version. Do not send account passwords.")
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
                        ProfileRow(title: "Frequently asked questions", systemImage: "questionmark.circle")
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
                    Text("This only works for a profile already saved on this iPhone.")
                        .font(.subheadline)
                        .foregroundStyle(Palette.muted)
                    LabeledField(title: "Email", placeholder: "you@example.com", text: $email, keyboard: .emailAddress, contentType: .emailAddress)
                    LabeledField(title: "New password", placeholder: "At least 8 characters", text: $password, isSecure: true, contentType: .newPassword)
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
                            message = "Password updated. You can sign in."
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
