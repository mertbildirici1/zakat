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
                    Text("This flow is built like Plaid Link: a backend creates a link session, you pick an institution, and balances are mapped into zakat categories. You still confirm every line.")
                        .font(.subheadline)
                        .foregroundStyle(Palette.muted)

                    if viewModel.modeLabel.isEmpty == false {
                        Text(viewModel.modeLabel)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Palette.gold)
                    }

                    if !session.linkedAccounts.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Linked now")
                                .font(.headline)
                            ForEach(session.linkedAccounts) { account in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(account.displayName)
                                            .font(.subheadline.weight(.semibold))
                                        Text("\(account.institutionName) · \(account.type.rawValue)")
                                            .font(.caption)
                                            .foregroundStyle(Palette.muted)
                                    }
                                    Spacer()
                                    Text(Money.display(account.currentBalance))
                                        .font(.subheadline.monospacedDigit())
                                }
                                .padding(12)
                                .background(Color.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            Button("Unlink all imported accounts", role: .destructive) {
                                session.applyLinkedAccounts([])
                            }
                            .font(.subheadline.weight(.semibold))
                        }
                    }

                    if viewModel.institutions.isEmpty {
                        PrimaryButton(title: viewModel.isLoading ? "Connecting…" : "Start account link") {
                            Task { await viewModel.start(baseURL: session.backendURL) }
                        }
                        .disabled(viewModel.isLoading)
                    } else {
                        Text("Choose an institution")
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
                        Text("Review and complete manually")
                            .font(.headline)
                            .foregroundStyle(Palette.forest)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Palette.parchment, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .disabled(session.linkedAccounts.isEmpty && session.draft.bankDeposits.isEmpty)

                    Text("Real Plaid production keys never belong in the iOS app. The local backend holds the secret and exchanges public tokens.")
                        .font(.caption)
                        .foregroundStyle(Palette.muted)
                }
                .padding(20)
            }
        }
        .navigationTitle("Connect accounts")
        .navigationBarTitleDisplayMode(.inline)
    }
}

@Observable
@MainActor
final class ConnectedAccountsViewModel {
    var institutions: [SandboxInstitution] = []
    var isLoading = false
    var errorMessage: String?
    var modeLabel = ""
    private var linkToken = ""
    private var usingOfflineFallback = false

    func start(baseURL: URL) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let session = try await LiveBankLinkClient(baseURL: baseURL).createLinkToken()
            linkToken = session.linkToken
            institutions = session.institutions
            modeLabel = session.mode == "plaid" ? "Live Plaid sandbox" : "Local linking sandbox"
            usingOfflineFallback = false
        } catch {
            let session = try? await OfflineSandboxBankLinkClient().createLinkToken()
            linkToken = session?.linkToken ?? "offline-sandbox"
            institutions = session?.institutions ?? SandboxCatalog.institutions
            modeLabel = "Offline sandbox (backend not running)"
            usingOfflineFallback = true
            errorMessage = "Using built-in sandbox data. Start backend/ to talk to a local Plaid-style server."
        }
    }

    func connect(_ institution: SandboxInstitution, session: AppSession) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let client: any BankLinkClient = usingOfflineFallback
                ? OfflineSandboxBankLinkClient()
                : LiveBankLinkClient(baseURL: session.backendURL)
            let item = try await client.completeLink(
                publicToken: linkToken,
                institutionID: institution.id
            )
            var accounts = session.linkedAccounts.filter { $0.institutionName != item.institutionName }
            accounts.append(contentsOf: item.accounts)
            session.applyLinkedAccounts(accounts)
            modeLabel = "Imported \(item.institutionName)"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
