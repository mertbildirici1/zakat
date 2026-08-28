import SwiftUI

enum AuthMode {
    case signIn
    case createAccount

    var title: String {
        switch self {
        case .signIn: return "Sign in"
        case .createAccount: return "Create account"
        }
    }

    var submitTitle: String {
        switch self {
        case .signIn: return "Sign in"
        case .createAccount: return "Create account"
        }
    }
}

struct AuthView: View {
    @Environment(AppSession.self) private var session
    @State var mode: AuthMode

    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var isWorking = false
    @State private var acceptedTerms = false

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(mode == .signIn
                         ? "Save bank links and this year’s activity."
                         : "Keep banks and balances with your profile.")
                        .font(.subheadline)
                        .foregroundStyle(Palette.muted)

                    if mode == .createAccount {
                        LabeledField(
                            title: "Full name",
                            placeholder: "Your name",
                            text: $fullName,
                            contentType: .name,
                            autocapitalization: .words
                        )
                    }

                    LabeledField(
                        title: "Email",
                        placeholder: "you@example.com",
                        text: $email,
                        keyboard: .emailAddress,
                        contentType: .emailAddress
                    )
                    LabeledField(
                        title: "Password",
                        placeholder: "8+ characters",
                        text: $password,
                        isSecure: true,
                        contentType: mode == .createAccount ? .newPassword : .password
                    )

                    if mode == .createAccount {
                        LabeledField(
                            title: "Confirm",
                            placeholder: "Re-enter password",
                            text: $confirmPassword,
                            isSecure: true,
                            contentType: .newPassword
                        )
                        Toggle(isOn: $acceptedTerms) {
                            Text("I accept the Terms, Privacy, and Disclaimer.")
                                .font(.subheadline)
                        }
                        .tint(Palette.moss)
                        NavigationLink {
                            LegalIndexView()
                        } label: {
                            Text("Read terms")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Palette.forest)
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(Palette.rust)
                    }

                    PrimaryButton(title: isWorking ? "Working…" : mode.submitTitle, enabled: canSubmit && !isWorking) {
                        submit()
                    }

                    Button(mode == .signIn ? "Create an account" : "Sign in instead") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            mode = mode == .signIn ? .createAccount : .signIn
                            errorMessage = nil
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.forest)
                    .frame(maxWidth: .infinity)

                    if mode == .signIn {
                        NavigationLink {
                            ResetPasswordView()
                        } label: {
                            Text("Forgot password?")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Palette.muted)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle(mode.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var canSubmit: Bool {
        if mode == .createAccount {
            return fullName.isEmpty == false && email.isEmpty == false && password.count >= 8 && acceptedTerms
        }
        return email.isEmpty == false && password.isEmpty == false
    }

    private func submit() {
        errorMessage = nil
        isWorking = true
        Task {
            try? await Task.sleep(for: .milliseconds(280))
            do {
                if mode == .createAccount {
                    try await session.createAccount(
                        fullName: fullName,
                        email: email,
                        password: password,
                        confirmPassword: confirmPassword
                    )
                } else {
                    try await session.signIn(email: email, password: password)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isWorking = false
        }
    }
}
