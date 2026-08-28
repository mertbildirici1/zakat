import Foundation

public enum CashflowKind: String, Codable, Sendable, CaseIterable {
    case income
    case spending
    case transfer
    case investment
    case other

    public var title: String {
        switch self {
        case .income: return "Income"
        case .spending: return "Spending"
        case .transfer: return "Transfers"
        case .investment: return "Investing"
        case .other: return "Other"
        }
    }
}

public struct BankTransaction: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var accountID: String
    public var date: Date
    public var name: String
    public var amount: Decimal
    public var kind: CashflowKind

    enum CodingKeys: String, CodingKey {
        case id, date, name, amount, kind
        case accountID = "accountId"
    }

    public init(
        id: String,
        accountID: String,
        date: Date,
        name: String,
        amount: Decimal,
        kind: CashflowKind
    ) {
        self.id = id
        self.accountID = accountID
        self.date = date
        self.name = name
        self.amount = amount
        self.kind = kind
    }

    public var isMoneyIn: Bool { amount > 0 }
}

public struct MonthBucket: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var label: String
    public var income: Decimal
    public var spending: Decimal

    public var net: Decimal { income - spending }

    public init(id: String, label: String, income: Decimal, spending: Decimal) {
        self.id = id
        self.label = label
        self.income = income
        self.spending = spending
    }
}

public struct YearSummary: Codable, Equatable, Sendable {
    public var start: Date
    public var end: Date
    public var income: Decimal
    public var spending: Decimal
    public var investing: Decimal
    public var transfers: Decimal
    public var netGain: Decimal
    public var transactionCount: Int
    public var months: [MonthBucket]
    public var topIncome: [BankTransaction]
    public var topSpending: [BankTransaction]

    public var formattedGain: String {
        let prefix = netGain >= 0 ? "+" : ""
        return prefix + Money.display(netGain)
    }

    public var formattedIncome: String { Money.display(income) }
    public var formattedSpending: String { Money.display(spending) }
}

public struct YearAnalyzer: Sendable {
    public init() {}

    public func summarize(
        _ transactions: [BankTransaction],
        from start: Date,
        to end: Date = Date(),
        calendar: Calendar = .current
    ) -> YearSummary {
        let ranged = transactions.filter { $0.date >= start && $0.date <= end }
        var income: Decimal = 0
        var spending: Decimal = 0
        var investing: Decimal = 0
        var transfers: Decimal = 0

        var monthMap: [String: (income: Decimal, spending: Decimal)] = [:]
        let monthFormatter = DateFormatter()
        monthFormatter.calendar = calendar
        monthFormatter.dateFormat = "yyyy-MM"
        let labelFormatter = DateFormatter()
        labelFormatter.calendar = calendar
        labelFormatter.dateFormat = "MMM"

        for item in ranged {
            let key = monthFormatter.string(from: item.date)
            var bucket = monthMap[key] ?? (0, 0)
            switch item.kind {
            case .income:
                income += max(0, item.amount)
                bucket.income += max(0, item.amount)
            case .spending:
                spending += abs(min(0, item.amount))
                bucket.spending += abs(min(0, item.amount))
            case .investment:
                investing += item.amount
            case .transfer, .other:
                transfers += item.amount
            }
            monthMap[key] = bucket
        }

        let months = monthMap.keys.sorted().map { key in
            let sample = ranged.first { monthFormatter.string(from: $0.date) == key }?.date ?? start
            let values = monthMap[key] ?? (0, 0)
            return MonthBucket(
                id: key,
                label: labelFormatter.string(from: sample),
                income: Money.rounded(values.income),
                spending: Money.rounded(values.spending)
            )
        }

        let topIncome = ranged.filter { $0.kind == .income }.sorted { $0.amount > $1.amount }.prefix(5)
        let topSpending = ranged.filter { $0.kind == .spending }.sorted { abs($0.amount) > abs($1.amount) }.prefix(5)

        return YearSummary(
            start: start,
            end: end,
            income: Money.rounded(income),
            spending: Money.rounded(spending),
            investing: Money.rounded(investing),
            transfers: Money.rounded(transfers),
            netGain: Money.rounded(income - spending),
            transactionCount: ranged.count,
            months: months,
            topIncome: Array(topIncome),
            topSpending: Array(topSpending)
        )
    }
}
