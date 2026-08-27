import Foundation

public struct NamedAmount: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var amount: Decimal
    public var included: Bool
    public var source: EntrySource
    public var externalAccountID: String?

    public init(
        id: UUID = UUID(),
        name: String,
        amount: Decimal,
        included: Bool = true,
        source: EntrySource = .manual,
        externalAccountID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.included = included
        self.source = source
        self.externalAccountID = externalAccountID
    }

    public var contribution: Decimal {
        included ? max(0, amount) : 0
    }
}

public enum EntrySource: String, Codable, Sendable {
    case manual
    case linked
}
