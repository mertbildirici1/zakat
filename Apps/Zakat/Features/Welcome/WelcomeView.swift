import SwiftUI

struct WelcomeView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        ZStack {
            ScreenBackground()
            VStack(spacing: 0) {
                Spacer(minLength: 24)
                header
                Spacer(minLength: 28)
                VStack(spacing: 14) {
                    Button {
                        session.enterOffline()
                    } label: {
                        ModeCard(
                            eyebrow: "No account",
                            title: "Continue offline",
                            detail: "Enter holdings yourself. Nothing leaves this phone.",
                            systemImage: "iphone"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        ComingSoonView()
                    } label: {
                        ModeCard(
                            eyebrow: "Soon",
                            title: "Sign in",
                            detail: "Bank linking is being worked on.",
                            systemImage: "person.crop.circle"
                        )
                    }
                    .buttonStyle(.plain)
                }

                NavigationLink {
                    ComingSoonView()
                } label: {
                    Text("Create an account")
                        .font(.headline)
                        .foregroundStyle(Palette.forest)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                }
                .padding(.top, 8)

                Text("Offline needs no account.")
                    .font(.caption)
                    .foregroundStyle(Palette.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)

                NavigationLink {
                    LegalIndexView()
                } label: {
                    Text("Terms and privacy")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Palette.forest)
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 28))
                .foregroundStyle(Palette.gold)
                .frame(width: 72, height: 72)
                .background(Palette.forest, in: Circle())

            VStack(spacing: 10) {
                Text("Zakat")
                    .font(.system(size: 44, weight: .semibold, design: .serif))
                    .foregroundStyle(Palette.forest)
                Text("Estimate zakat from what you hold.")
                    .font(.body)
                    .foregroundStyle(Palette.muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
