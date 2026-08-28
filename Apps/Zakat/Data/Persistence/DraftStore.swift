import Foundation
import ZakatEngine

struct SavedSnapshot: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var createdAt: Date
    var zakatDue: Decimal
    var netZakatable: Decimal
    var meetsNisab: Bool
    var currencyCode: String
    var mode: String

    init(id: UUID = UUID(), createdAt: Date = Date(), result: ZakatResult, mode: String) {
        self.id = id
        self.createdAt = createdAt
        self.zakatDue = result.zakatDue
        self.netZakatable = result.netZakatable
        self.meetsNisab = result.meetsNisab
        self.currencyCode = result.currencyCode
        self.mode = mode
    }

    var formattedDue: String {
        meetsNisab ? Money.display(zakatDue, currencyCode: currencyCode) : "Below nisab"
    }
}

struct WorkspaceMeta: Codable, Equatable, Sendable {
    var hawlStartDate: Date
    var hawlReminderEnabled: Bool

    init(hawlStartDate: Date = Calendar.current.date(byAdding: .day, value: -Hawl.lunarYearDays, to: Date()) ?? Date(), hawlReminderEnabled: Bool = false) {
        self.hawlStartDate = hawlStartDate
        self.hawlReminderEnabled = hawlReminderEnabled
    }
}

struct MetalQuote: Codable, Equatable, Sendable {
    var goldPerGram: Decimal
    var silverPerGram: Decimal
    var source: String
    var updatedAt: String
}

enum DraftStore {
    static func save(_ draft: ZakatDraft, namespace: String) {
        guard let data = try? JSONEncoder().encode(draft) else { return }
        UserDefaults.standard.set(data, forKey: draftKey(namespace))
    }

    static func load(namespace: String) -> ZakatDraft? {
        guard let data = UserDefaults.standard.data(forKey: draftKey(namespace)) else { return nil }
        return try? JSONDecoder().decode(ZakatDraft.self, from: data)
    }

    static func saveResult(_ result: ZakatResult, namespace: String) {
        guard let data = try? JSONEncoder().encode(result) else { return }
        UserDefaults.standard.set(data, forKey: resultKey(namespace))
    }

    static func loadResult(namespace: String) -> ZakatResult? {
        guard let data = UserDefaults.standard.data(forKey: resultKey(namespace)) else { return nil }
        return try? JSONDecoder().decode(ZakatResult.self, from: data)
    }

    static func saveAccounts(_ accounts: [LinkedAccount], namespace: String) {
        guard let data = try? JSONEncoder().encode(accounts) else { return }
        UserDefaults.standard.set(data, forKey: accountsKey(namespace))
    }

    static func loadAccounts(namespace: String) -> [LinkedAccount] {
        guard let data = UserDefaults.standard.data(forKey: accountsKey(namespace)) else { return [] }
        return (try? JSONDecoder().decode([LinkedAccount].self, from: data)) ?? []
    }

    static func saveHistory(_ snapshots: [SavedSnapshot], namespace: String) {
        guard let data = try? JSONEncoder().encode(snapshots) else { return }
        UserDefaults.standard.set(data, forKey: historyKey(namespace))
    }

    static func loadHistory(namespace: String) -> [SavedSnapshot] {
        guard let data = UserDefaults.standard.data(forKey: historyKey(namespace)) else { return [] }
        return (try? JSONDecoder().decode([SavedSnapshot].self, from: data)) ?? []
    }

    static func saveMeta(_ meta: WorkspaceMeta, namespace: String) {
        guard let data = try? JSONEncoder().encode(meta) else { return }
        UserDefaults.standard.set(data, forKey: metaKey(namespace))
    }

    static func loadMeta(namespace: String) -> WorkspaceMeta {
        guard let data = UserDefaults.standard.data(forKey: metaKey(namespace)),
              let meta = try? JSONDecoder().decode(WorkspaceMeta.self, from: data)
        else { return WorkspaceMeta() }
        return meta
    }

    static func saveTransactions(_ transactions: [BankTransaction], namespace: String) {
        guard let data = try? JSONEncoder().encode(transactions) else { return }
        UserDefaults.standard.set(data, forKey: txKey(namespace))
    }

    static func loadTransactions(namespace: String) -> [BankTransaction] {
        guard let data = UserDefaults.standard.data(forKey: txKey(namespace)) else { return [] }
        return (try? JSONDecoder().decode([BankTransaction].self, from: data)) ?? []
    }

    static func clearNamespace(_ namespace: String) {
        UserDefaults.standard.removeObject(forKey: draftKey(namespace))
        UserDefaults.standard.removeObject(forKey: resultKey(namespace))
        UserDefaults.standard.removeObject(forKey: accountsKey(namespace))
        UserDefaults.standard.removeObject(forKey: historyKey(namespace))
        UserDefaults.standard.removeObject(forKey: metaKey(namespace))
        UserDefaults.standard.removeObject(forKey: txKey(namespace))
    }

    private static func draftKey(_ namespace: String) -> String { "zakat.draft.v1.\(namespace)" }
    private static func resultKey(_ namespace: String) -> String { "zakat.result.v1.\(namespace)" }
    private static func accountsKey(_ namespace: String) -> String { "zakat.accounts.v1.\(namespace)" }
    private static func historyKey(_ namespace: String) -> String { "zakat.history.v1.\(namespace)" }
    private static func metaKey(_ namespace: String) -> String { "zakat.meta.v1.\(namespace)" }
    private static func txKey(_ namespace: String) -> String { "zakat.tx.v1.\(namespace)" }
}
