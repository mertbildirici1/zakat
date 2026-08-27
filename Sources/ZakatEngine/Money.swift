import Foundation

public enum Money {
    public static let zakatRate = Decimal(string: "0.025")!

    public static func rounded(_ value: Decimal, scale: Int = 2) -> Decimal {
        var value = value
        var result = Decimal()
        NSDecimalRound(&result, &value, scale, .plain)
        return result
    }

    public static func display(_ value: Decimal, currencyCode: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
    }
}
