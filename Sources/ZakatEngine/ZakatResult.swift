import Foundation

public struct BreakdownRow: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var title: String
    public var amount: Decimal
    public var isDeduction: Bool

    public init(id: String, title: String, amount: Decimal, isDeduction: Bool = false) {
        self.id = id
        self.title = title
        self.amount = amount
        self.isDeduction = isDeduction
    }
}

public struct ZakatResult: Codable, Equatable, Sendable {
    public var currencyCode: String
    public var rate: Decimal
    public var cashAndBanks: Decimal
    public var goldValue: Decimal
    public var silverValue: Decimal
    public var investments: Decimal
    public var retirement: Decimal
    public var crypto: Decimal
    public var businessInventory: Decimal
    public var receivables: Decimal
    public var grossZakatable: Decimal
    public var deductibleLiabilities: Decimal
    public var netZakatable: Decimal
    public var goldNisab: Decimal
    public var silverNisab: Decimal
    public var selectedNisab: Decimal
    public var nisabStandard: NisabStandard
    public var meetsNisab: Bool
    public var zakatDue: Decimal
    public var breakdown: [BreakdownRow]

    public var formattedDue: String {
        Money.display(zakatDue, currencyCode: currencyCode)
    }

    public var formattedNet: String {
        Money.display(netZakatable, currencyCode: currencyCode)
    }
}
