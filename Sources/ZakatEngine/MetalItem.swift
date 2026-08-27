import Foundation

public struct MetalItem: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var grams: Decimal
    public var karat: Int
    public var isPersonalJewelry: Bool
    public var included: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        grams: Decimal,
        karat: Int = 24,
        isPersonalJewelry: Bool = false,
        included: Bool = true
    ) {
        self.id = id
        self.name = name
        self.grams = grams
        self.karat = min(24, max(1, karat))
        self.isPersonalJewelry = isPersonalJewelry
        self.included = included
    }

    public var fineGrams: Decimal {
        grams * Decimal(karat) / Decimal(24)
    }

    public func value(pricePerGram: Decimal) -> Decimal {
        guard included else { return 0 }
        return max(0, fineGrams * pricePerGram)
    }
}
