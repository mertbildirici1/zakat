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
    var history: [SavedSnapshot]
    var meta: WorkspaceMeta
    var backendURL: URL
    var selectedTab: Int
    var metalsStatus: String?

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
        self.history = []
        self.meta = WorkspaceMeta()
        self.backendURL = backendURL
        self.selectedTab = 0
        self.metalsStatus = nil

        if route == .signedIn && currentUser == nil {
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

    func acceptLegal() {
        AuthStore.hasAcceptedLegal = true
        hasAcceptedLegal = true
    }

    func enterOffline() {
        AuthStore.enterOffline()
        currentUser = nil
        route = .offline
        loadWorkspace()
    }

    func leaveOffline() {
        persist()
        AuthStore.leaveOffline()
        route = .welcome
    }

    func createAccount(fullName: String, email: String, password: String, confirmPassword: String) throws {
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
    }

    func signIn(email: String, password: String) throws {
        persist()
        currentUser = try AuthStore.signIn(email: email, password: password)
        route = .signedIn
        loadWorkspace()
    }

    func resetPassword(email: String, newPassword: String, confirmPassword: String) throws {
        try AuthStore.resetPassword(email: email, newPassword: newPassword, confirmPassword: confirmPassword)
    }

    func updateProfile(fullName: String) throws {
        currentUser = try AuthStore.updateCurrentUser(fullName: fullName)
    }

    func signOut() {
        persist()
        AuthStore.signOut()
        currentUser = nil
        route = .welcome
        draft = .empty
        lastResult = nil
        linkedAccounts = []
        history = []
        meta = WorkspaceMeta()
    }

    func deleteAccount() {
        AuthStore.deleteCurrentAccount()
        currentUser = nil
        route = .welcome
        draft = .empty
        lastResult = nil
        linkedAccounts = []
        history = []
        meta = WorkspaceMeta()
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

    func unlinkInstitution(_ name: String) {
        linkedAccounts.removeAll { $0.institutionName == name }
        applyLinkedAccounts(linkedAccounts)
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
            metalsStatus = "Could not refresh prices. Enter them yourself."
        }
    }

    func persist() {
        DraftStore.save(draft, namespace: storageNamespace)
        DraftStore.saveAccounts(linkedAccounts, namespace: storageNamespace)
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
        history = DraftStore.loadHistory(namespace: storageNamespace)
        meta = DraftStore.loadMeta(namespace: storageNamespace)
        recalculate()
    }

    func resetDraft() {
        let settings = draft.settings
        draft = ZakatDraft(settings: settings)
        linkedAccounts = []
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
