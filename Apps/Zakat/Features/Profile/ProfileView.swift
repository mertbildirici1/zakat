import SwiftUI

struct ProfileView: View {
    @Environment(AppSession.self) private var session
    @State private var showSignOut = false
    @State private var showDelete = false

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView {
                VStack(spacing: 22) {
                    if let user = session.currentUser {
                        VStack(spacing: 10) {
                            AvatarView(initials: user.initials, size: 84)
                            Text(user.fullName)
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(Palette.ink)
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundStyle(Palette.muted)
                            Text("On this phone since \(user.createdAt.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(Palette.muted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                    }

                    VStack(spacing: 10) {
                        NavigationLink {
                            HistoryView()
                        } label: {
                            ProfileRow(title: "History", systemImage: "clock", detail: session.history.isEmpty ? "None" : "\(session.history.count)")
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            EditProfileView()
                        } label: {
                            ProfileRow(title: "Edit profile", systemImage: "pencil")
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            SettingsView()
                        } label: {
                            ProfileRow(
                                title: "Calculation settings",
                                systemImage: "slider.horizontal.3",
                                detail: session.draft.settings.nisabStandard == .gold ? "Gold nisab" : "Silver nisab"
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            ConnectedAccountsView()
                        } label: {
                            ProfileRow(
                                title: "Linked accounts",
                                systemImage: "building.columns",
                                detail: session.linkedAccounts.isEmpty ? "None" : "\(session.linkedAccounts.count)"
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(spacing: 10) {
                        NavigationLink {
                            SupportView()
                        } label: {
                            ProfileRow(title: "Support", systemImage: "envelope")
                        }
                        .buttonStyle(.plain)
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

                    VStack(spacing: 10) {
                        Button {
                            showSignOut = true
                        } label: {
                            ProfileRow(title: "Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                        .buttonStyle(.plain)

                        Button {
                            showDelete = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(Palette.rust)
                                    .frame(width: 28)
                                Text("Delete account")
                                    .foregroundStyle(Palette.rust)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }

                    Text("Your profile and passwords stay on this iPhone. This is not a cloud account yet.")
                        .font(.caption)
                        .foregroundStyle(Palette.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .padding(24)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Sign out?", isPresented: $showSignOut) {
            Button("Sign out", role: .destructive) { session.signOut() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You can sign back in on this phone with the same email.")
        }
        .alert("Delete this account?", isPresented: $showDelete) {
            Button("Delete", role: .destructive) { session.deleteAccount() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the local profile and its saved estimate from this iPhone.")
        }
    }
}

struct EditProfileView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var fullName = ""
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            ScreenBackground()
            VStack(alignment: .leading, spacing: 20) {
                LabeledField(
                    title: "Full name",
                    placeholder: "Your name",
                    text: $fullName,
                    contentType: .name,
                    autocapitalization: .words
                )
                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Palette.rust)
                }
                PrimaryButton(title: "Save") {
                    do {
                        try session.updateProfile(fullName: fullName)
                        dismiss()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
                Spacer()
            }
            .padding(24)
        }
        .navigationTitle("Edit profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fullName = session.currentUser?.fullName ?? ""
        }
    }
}
