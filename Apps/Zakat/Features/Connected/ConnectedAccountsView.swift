import SwiftUI
import ZakatEngine

struct ConnectedAccountsView: View {
    @Environment(AppSession.self) private var session
    @State private var viewModel = ConnectedAccountsViewModel()

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Import balances and this year’s activity. Review every line.")
                        .font(.subheadline)
                        .foregroundStyle(Palette.muted)

                    if viewModel.modeLabel.isEmpty == false {
                        Text(viewModel.modeLabel)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Palette.gold)
                    }

                    if session.hasCloudSession == false {
                        Text("This profile is on this iPhone only.")
                            .font(.caption)
                            .foregroundStyle(Palette.muted)
                    }

                    if !session.linkedAccounts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Linked")
                                .font(.headline)
                            ForEach(groupedInstitutions, id: \.name) { group in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(group.name)
                                            .font(.subheadline.weight(.semibold))
                                        Spacer()
                                        Button("Unlink", role: .destructive) {
                                            session.unlinkInstitution(group.name)
                                        }
                                        .font(.caption.weight(.semibold))
                                    }
                                    ForEach(group.accounts) { account in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(account.displayName)
                                                    .font(.subheadline.weight(.semibold))
                                                Text(account.type.rawValue)
                                                    .font(.caption)
                                                    .foregroundStyle(Palette.muted)
                                            }
                                            Spacer()
                                            Text(Money.display(account.currentBalance))
                                                .font(.subheadline.monospacedDigit())
                                        }
                                    }
                                }
                                .padding(12)
                                .background(Color.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                    }

                    if viewModel.institutions.isEmpty {
                        PrimaryButton(title: viewModel.isLoading ? "Connecting…" : "Link an account") {
                            Task { await viewModel.start(session: session) }
                        }
                        .disabled(viewModel.isLoading)
                    } else {
                        Text("Choose a bank")
                            .font(.headline)
                        ForEach(viewModel.institutions) { institution in
                            Button {
                                Task { await viewModel.connect(institution, session: session) }
                            } label: {
                                ModeCard(
                                    eyebrow: "Sandbox",
                                    title: institution.name,
                                    detail: institution.detail,
                                    systemImage: "link"
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(viewModel.isLoading)
                        }
                    }

                    if let message = viewModel.errorMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(Palette.rust)
                    }

                    NavigationLink {
                        ManualCalculatorView()
                    } label: {
                        Text("Add gold & cash")
                            .font(.headline)
                            .foregroundStyle(Palette.forest)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Palette.parchment, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    Text("Bank keys stay on the server.")
                        .font(.caption)
                        .foregroundStyle(Palette.muted)
                }
                .padding(20)
            }
            .refreshable {
                await session.refreshFromCloud()
            }
        }
        .navigationTitle("Accounts")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.institutions.isEmpty {
                await viewModel.start(session: session)
            }
        }
    }

    private var groupedInstitutions: [(name: String, accounts: [LinkedAccount])] {
        Dictionary(grouping: session.linkedAccounts, by: \.institutionName)
            .map { ($0.key, $0.value) }
            .sorted { $0.name < $1.name }
    }
}

@Observable
@MainActor
final class ConnectedAccountsViewModel {
    var institutions: [SandboxInstitution] = []
    var isLoading = false
    var errorMessage: String?
    var modeLabel = ""
    private var usingOfflineFallback = false

    func start(session: AppSession) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        if let token = SessionTokenStore.token {
            do {
                let created = try await CloudAPI(baseURL: session.backendURL, token: token).linkToken()
                institutions = created.institutions
            modeLabel = created.mode == "plaid" ? "Plaid sandbox" : "Saved to your account"
                usingOfflineFallback = false
                return
            } catch {
                errorMessage = "Cloud linking unavailable. Using sandbox."
            }
        }

        do {
            let created = try await LiveBankLinkClient(baseURL: session.backendURL).createLinkToken()
            institutions = created.institutions
            modeLabel = created.mode == "plaid" ? "Plaid sandbox" : "Local sandbox"
            usingOfflineFallback = false
        } catch {
            let created = try? await OfflineSandboxBankLinkClient().createLinkToken()
            institutions = created?.institutions ?? SandboxCatalog.institutions
            modeLabel = "Offline sandbox"
            usingOfflineFallback = true
            errorMessage = "Using built-in sandbox. Start the API to save links."
        }
    }

    func connect(_ institution: SandboxInstitution, session: AppSession) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            if session.hasCloudSession && usingOfflineFallback == false {
                try await session.connectCloudInstitution(institution.id)
                modeLabel = "Imported \(institution.name)"
                return
            }
            let client: any BankLinkClient = usingOfflineFallback
                ? OfflineSandboxBankLinkClient()
                : LiveBankLinkClient(baseURL: session.backendURL)
            let item = try await client.completeLink(publicToken: "sandbox", institutionID: institution.id)
            session.applyLinkedItem(item)
            modeLabel = "Imported \(item.institutionName)"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
