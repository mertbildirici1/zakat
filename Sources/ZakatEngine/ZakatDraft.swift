import Foundation

public struct ZakatDraft: Codable, Equatable, Sendable {
    public var settings: CalculationSettings
    public var cashOnHand: Decimal
    public var bankDeposits: [NamedAmount]
    public var gold: [MetalItem]
    public var silver: [MetalItem]
    public var investments: [NamedAmount]
    public var retirement: [NamedAmount]
    public var crypto: [NamedAmount]
    public var businessInventory: [NamedAmount]
    public var receivables: [NamedAmount]
    public var immediateDebts: [NamedAmount]
    public var longTermDebts: [NamedAmount]

    public init(
        settings: CalculationSettings = CalculationSettings(),
        cashOnHand: Decimal = 0,
        bankDeposits: [NamedAmount] = [],
        gold: [MetalItem] = [],
        silver: [MetalItem] = [],
        investments: [NamedAmount] = [],
        retirement: [NamedAmount] = [],
        crypto: [NamedAmount] = [],
        businessInventory: [NamedAmount] = [],
        receivables: [NamedAmount] = [],
        immediateDebts: [NamedAmount] = [],
        longTermDebts: [NamedAmount] = []
    ) {
        self.settings = settings
        self.cashOnHand = cashOnHand
        self.bankDeposits = bankDeposits
        self.gold = gold
        self.silver = silver
        self.investments = investments
        self.retirement = retirement
        self.crypto = crypto
        self.businessInventory = businessInventory
        self.receivables = receivables
        self.immediateDebts = immediateDebts
        self.longTermDebts = longTermDebts
    }

    public static var empty: ZakatDraft { ZakatDraft() }

    public static var example: ZakatDraft {
        ZakatDraft(
            cashOnHand: 450,
            bankDeposits: [
                NamedAmount(name: "Checking", amount: 3_250),
                NamedAmount(name: "Savings", amount: 11_800),
            ],
            gold: [
                MetalItem(name: "Investment gold", grams: 20, karat: 24),
                MetalItem(name: "Jewelry", grams: 35, karat: 18, isPersonalJewelry: true),
            ],
            silver: [],
            investments: [
                NamedAmount(name: "Brokerage", amount: 18_400),
            ],
            retirement: [
                NamedAmount(name: "401(k)", amount: 62_000, included: false),
            ],
            crypto: [
                NamedAmount(name: "Bitcoin", amount: 2_100),
            ],
            businessInventory: [],
            receivables: [
                NamedAmount(name: "Personal loan owed to me", amount: 500),
            ],
            immediateDebts: [
                NamedAmount(name: "Credit card", amount: 1_240),
            ]
        )
    }

    public func removingLinkedRows() -> ZakatDraft {
        var next = self
        next.bankDeposits.removeAll { $0.source == .linked }
        next.investments.removeAll { $0.source == .linked }
        next.retirement.removeAll { $0.source == .linked }
        next.crypto.removeAll { $0.source == .linked }
        next.businessInventory.removeAll { $0.source == .linked }
        next.receivables.removeAll { $0.source == .linked }
        next.immediateDebts.removeAll { $0.source == .linked }
        next.longTermDebts.removeAll { $0.source == .linked }
        return next
    }
}
