import SwiftUI

struct ComingSoonView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        ZStack {
            ScreenBackground()
            VStack(spacing: 28) {
                Spacer(minLength: 24)
                Image(systemName: "hammer.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Palette.gold)
                    .frame(width: 72, height: 72)
                    .background(Palette.forest, in: Circle())

                VStack(spacing: 10) {
                    Text("Coming soon")
                        .font(.system(size: 34, weight: .semibold, design: .serif))
                        .foregroundStyle(Palette.forest)
                    Text("Bank linking is being worked on. Calculate offline for now.")
                        .font(.body)
                        .foregroundStyle(Palette.muted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    session.enterOffline()
                } label: {
                    Text("Continue offline")
                        .font(.headline)
                        .foregroundStyle(Palette.cream)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Palette.forest, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .navigationTitle("Sign in")
        .navigationBarTitleDisplayMode(.inline)
    }
}