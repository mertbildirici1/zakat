import Foundation

public enum NisabStandard: String, Codable, CaseIterable, Identifiable, Sendable {
    case gold
    case silver

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .gold: "Gold nisab (87.48 g)"
        case .silver: "Silver nisab (612.36 g)"
        }
    }
}

public struct CalculationSettings: Codable, Equatable, Sendable {
    public var currencyCode: String
    public var nisabStandard: NisabStandard
    public var includePersonalJewelry: Bool
    public var includeRetirementAccounts: Bool
    public var deductOnlyImmediateDebts: Bool
    public var goldPricePerGram: Decimal
    public var silverPricePerGram: Decimal

    public init(
        currencyCode: String = "USD",
        nisabStandard: NisabStandard = .gold,
        includePersonalJewelry: Bool = true,
        includeRetirementAccounts: Bool = false,
        deductOnlyImmediateDebts: Bool = true,
        goldPricePerGram: Decimal = Decimal(string: "100")!,
        silverPricePerGram: Decimal = Decimal(string: "1.20")!
    ) {
        self.currencyCode = currencyCode
        self.nisabStandard = nisabStandard
        self.includePersonalJewelry = includePersonalJewelry
        self.includeRetirementAccounts = includeRetirementAccounts
        self.deductOnlyImmediateDebts = deductOnlyImmediateDebts
        self.goldPricePerGram = goldPricePerGram
        self.silverPricePerGram = silverPricePerGram
    }

    public static let goldNisabGrams = Decimal(string: "87.48")!
    public static let silverNisabGrams = Decimal(string: "612.36")!

    public var goldNisabValue: Decimal {
        Self.goldNisabGrams * goldPricePerGram
    }

    public var silverNisabValue: Decimal {
        Self.silverNisabGrams * silverPricePerGram
    }

    public var selectedNisabValue: Decimal {
        switch nisabStandard {
        case .gold: goldNisabValue
        case .silver: silverNisabValue
        }
    }
}
