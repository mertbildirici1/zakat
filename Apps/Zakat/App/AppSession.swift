import Foundation
import Observation
import ZakatEngine

@Observable
@MainActor
final class AppSession {
    var hasAcceptedLegal: Bool
    var route: SessionRoute
    var currentUser: UserAccount?
    var draft: ZakatDraft
    var lastResult: ZakatResult?
    var linkedAccounts: [LinkedAccount]
    var transactions: [BankTransaction]
    var history: [SavedSnapshot]
    var meta: WorkspaceMeta
    var backendURL: URL
    var selectedTab: Int
    var metalsStatus: String?
    var cloudStatus: String?
    var isRefreshing: Bool

    init(
        draft: ZakatDraft = .empty,
        lastResult: ZakatResult? = nil,
        linkedAccounts: [LinkedAccount] = [],
        backendURL: URL = APIConfig.defaultBaseURL
    ) {
        self.hasAcceptedLegal = AuthStore.hasAcceptedLegal
        self.route = AuthStore.route
        self.currentUser = AuthStore.currentUser()
        self.draft = draft
        self.lastResult = lastResult
        self.linkedAccounts = linkedAccounts
        self.transactions = []
        self.history = []
        self.meta = WorkspaceMeta()
        self.backendURL = backendURL
        self.selectedTab = 0
        self.metalsStatus = nil
        self.cloudStatus = nil
        self.isRefreshing = false

        if AppConfig.accountsEnabled == false, route == .signedIn {
            currentUser = nil
            route = .welcome
            AuthStore.route = .welcome
        } else if route == .signedIn && currentUser == nil {
            route = .welcome
            AuthStore.route = .welcome
        }
        loadWorkspace()
    }

    var storageNamespace: String {
        if let currentUser, route == .signedIn {
            return "user-\(currentUser.id.uuidString)"
        }
        return "offline"
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    var hawlDaysRemaining: Int {
        Hawl.daysRemaining(from: meta.hawlStartDate)
    }

    var yearSummary: YearSummary {
        YearAnalyzer().summarize(transactions, from: meta.hawlStartDate)
    }

    var hasCloudSession: Bool {
        SessionTokenStore.token != nil
    }

    func acceptLegal() {
        AuthStore.hasAcceptedLegal = true
        hasAcceptedLegal = true
    }

    func enterOffline() {
        currentUser = nil
        linkedAccounts = []
        transactions = []
        cloudStatus = nil
        AuthStore.enterOffline()
        route = .offline
        loadWorkspace()
    }

    func leaveOffline() {
        persist()
        AuthStore.leaveOffline()
        route = .welcome
    }

    func createAccount(fullName: String, email: String, password: String, confirmPassword: String) async throws {
        guard hasAcceptedLegal else { throw AuthError.mustAcceptLegal }
        persist()
        currentUser = try AuthStore.createAccount(
            fullName: fullName,
            email: email,
            password: password,
            confirmPassword: confirmPassword
        )
        route = .signedIn
        loadWorkspace()
        do {
            let cloud = try await CloudAPI(baseURL: backendURL).register(
                fullName: fullName,
                email: email,
                password: password
            )
            SessionTokenStore.token = cloud.token
            cloudStatus = nil
            await refreshFromCloud()
        } catch {
            do {
                let cloud = try await CloudAPI(baseURL: backendURL).login(email: email, password: password)
                SessionTokenStore.token = cloud.token
                cloudStatus = nil
                await refreshFromCloud()
            } catch {
                cloudStatus = "On this iPhone only."
            }
        }
    }

    func signIn(email: String, password: String) async throws {
        persist()
        do {
            let cloud = try await CloudAPI(baseURL: backendURL).login(email: email, password: password)
            SessionTokenStore.token = cloud.token
            currentUser = AuthStore.upsertCloudProfile(fullName: cloud.user.fullName, email: cloud.user.email)
            route = .signedIn
            loadWorkspace()
            cloudStatus = nil
            await refreshFromCloud()
            return
        } catch {
            currentUser = try AuthStore.signIn(email: email, password: password)
            route = .signedIn
            loadWorkspace()
        }

        do {
            let cloud = try await CloudAPI(baseURL: backendURL).register(
                fullName: currentUser?.fullName ?? "User",
                email: email,
                password: password
            )
            SessionTokenStore.token = cloud.token
            cloudStatus = nil
            await refreshFromCloud()
        } catch {
            do {
                let cloud = try await CloudAPI(baseURL: backendURL).login(email: email, password: password)
                SessionTokenStore.token = cloud.token
                cloudStatus = nil
                await refreshFromCloud()
            } catch {
                cloudStatus = "On this iPhone only."
            }
        }
    }

    func resetPassword(email: String, newPassword: String, confirmPassword: String) throws {
        try AuthStore.resetPassword(email: email, newPassword: newPassword, confirmPassword: confirmPassword)
    }

    func updateProfile(fullName: String) throws {
        currentUser = try AuthStore.updateCurrentUser(fullName: fullName)
    }

    func signOut() {
        persist()
        draft = .empty
        lastResult = nil
        linkedAccounts = []
        transactions = []
        history = []
        meta = WorkspaceMeta()
        cloudStatus = nil
        currentUser = nil
        route = .welcome
        AuthStore.signOut()
    }

    func deleteAccount() {
        if let token = SessionTokenStore.token {
            let url = backendURL
            Task { try? await CloudAPI(baseURL: url, token: token).deleteAccount() }
        }
        draft = .empty
        lastResult = nil
        linkedAccounts = []
        transactions = []
        history = []
        meta = WorkspaceMeta()
        cloudStatus = nil
        currentUser = nil
        route = .welcome
        AuthStore.deleteCurrentAccount()
    }

    func recalculate() {
        lastResult = ZakatCalculator().calculate(draft)
        persist()
    }

    func applyLinkedAccounts(_ accounts: [LinkedAccount]) {
        linkedAccounts = accounts
        draft = AccountCategoryMapper().apply(accounts, to: draft)
        recalculate()
    }

    func applyTransactions(_ items: [BankTransaction]) {
        transactions = items.sorted { $0.date > $1.date }
        persist()
    }

    func applyLinkedItem(_ item: LinkedItem) {
        var accounts = linkedAccounts.filter { $0.institutionName != item.institutionName }
        accounts.append(contentsOf: item.accounts)
        let incomingIDs = Set(item.accounts.map(\.id))
        var txs = transactions.filter { incomingIDs.contains($0.accountID) == false }
        if let newTx = item.transactions {
            txs.append(contentsOf: newTx)
        }
        applyTransactions(txs)
        applyLinkedAccounts(accounts)
    }

    func refreshFromCloud() async {
        guard let token = SessionTokenStore.token else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let snapshot = try await CloudAPI(baseURL: backendURL, token: token).snapshot()
            applyTransactions(snapshot.transactions)
            applyLinkedAccounts(snapshot.accounts)
            if snapshot.accounts.isEmpty {
                cloudStatus = "Link a bank to import this year."
            } else {
                cloudStatus = "\(snapshot.accounts.count) linked · \(snapshot.transactions.count) transactions"
            }
        } catch {
            cloudStatus = error.localizedDescription
        }
    }

    func connectCloudInstitution(_ institutionID: String) async throws {
        guard let token = SessionTokenStore.token else {
            throw BankLinkError(errorDescription: "Sign in to save a bank link.")
        }
        _ = try await CloudAPI(baseURL: backendURL, token: token).completeLink(institutionID: institutionID)
        await refreshFromCloud()
    }

    func unlinkInstitution(_ name: String) {
        let remaining = linkedAccounts.filter { $0.institutionName != name }
        let remainingIDs = Set(remaining.map(\.id))
        transactions.removeAll { remainingIDs.contains($0.accountID) == false }
        applyLinkedAccounts(remaining)
        persist()
        if let token = SessionTokenStore.token {
            let url = backendURL
            let institutionID = Self.institutionID(for: name)
            Task {
                try? await CloudAPI(baseURL: url, token: token).unlink(institutionID: institutionID)
            }
        }
    }

    static func institutionID(for name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("fidelity") { return "fidelity" }
        if lower.contains("coinbase") { return "coinbase" }
        return "chase"
    }

    func saveSnapshot() {
        guard let lastResult else { return }
        let mode = route == .offline ? "offline" : "account"
        if let last = history.first,
           last.netZakatable == lastResult.netZakatable,
           last.zakatDue == lastResult.zakatDue,
           Date().timeIntervalSince(last.createdAt) < 60 {
            return
        }
        history.insert(SavedSnapshot(result: lastResult, mode: mode), at: 0)
        if history.count > 50 { history = Array(history.prefix(50)) }
        persist()
    }

    func updateHawl(start: Date, reminder: Bool) {
        meta.hawlStartDate = start
        meta.hawlReminderEnabled = reminder
        persist()
        HawlReminder.sync(enabled: reminder, startDate: start)
    }

    func refreshMetalPrices() async {
        do {
            let quote = try await MetalsClient.fetchQuote(baseURL: backendURL)
            draft.settings.goldPricePerGram = quote.goldPerGram
            draft.settings.silverPricePerGram = quote.silverPerGram
            metalsStatus = "Updated from \(quote.source)"
            recalculate()
        } catch {
            metalsStatus = "Couldn’t refresh. Enter prices yourself."
        }
    }

    func persist() {
        if route == .welcome { return }
        let isOffline = storageNamespace == "offline"
        DraftStore.save(isOffline ? draft.removingLinkedRows() : draft, namespace: storageNamespace)
        DraftStore.saveAccounts(isOffline ? [] : linkedAccounts, namespace: storageNamespace)
        DraftStore.saveTransactions(isOffline ? [] : transactions, namespace: storageNamespace)
        DraftStore.saveHistory(history, namespace: storageNamespace)
        DraftStore.saveMeta(meta, namespace: storageNamespace)
        if let lastResult {
            DraftStore.saveResult(lastResult, namespace: storageNamespace)
        }
    }

    func loadWorkspace() {
        draft = DraftStore.load(namespace: storageNamespace) ?? .empty
        lastResult = DraftStore.loadResult(namespace: storageNamespace)
        linkedAccounts = DraftStore.loadAccounts(namespace: storageNamespace)
        transactions = DraftStore.loadTransactions(namespace: storageNamespace)
        history = DraftStore.loadHistory(namespace: storageNamespace)
        meta = DraftStore.loadMeta(namespace: storageNamespace)
        if storageNamespace == "offline" {
            draft = draft.removingLinkedRows()
            linkedAccounts = []
            transactions = []
        }
        recalculate()
    }

    func resetDraft() {
        let settings = draft.settings
        draft = ZakatDraft(settings: settings)
        if route == .offline {
            linkedAccounts = []
            transactions = []
        } else {
            draft = AccountCategoryMapper().apply(linkedAccounts, to: draft)
        }
        lastResult = ZakatCalculator().calculate(draft)
        persist()
    }
}

enum APIConfig {
    static var defaultBaseURL: URL {
        if let raw = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty == false, trimmed.contains("$(") == false, let url = URL(string: trimmed) {
                return url
            }
        }
        #if DEBUG
        return URL(string: "http://127.0.0.1:8787")!
        #else
        return URL(string: "https://api.example.com")!
        #endif
    }
}
