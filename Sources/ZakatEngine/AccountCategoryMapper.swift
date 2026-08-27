import Foundation

public enum LinkedAccountType: String, Codable, Sendable {
    case checking
    case savings
    case moneyMarket
    case brokerage
    case retirement
    case crypto
    case credit
    case loan
    case other
}

public struct LinkedAccount: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var institutionName: String
    public var name: String
    public var mask: String?
    public var type: LinkedAccountType
    public var currentBalance: Decimal
    public var isoCurrencyCode: String

    public init(
        id: String,
        institutionName: String,
        name: String,
        mask: String? = nil,
        type: LinkedAccountType,
        currentBalance: Decimal,
        isoCurrencyCode: String = "USD"
    ) {
        self.id = id
        self.institutionName = institutionName
        self.name = name
        self.mask = mask
        self.type = type
        self.currentBalance = currentBalance
        self.isoCurrencyCode = isoCurrencyCode
    }

    public var displayName: String {
        if let mask {
            return "\(name) ••\(mask)"
        }
        return name
    }
}

public struct AccountCategoryMapper: Sendable {
    public init() {}

    public func apply(_ accounts: [LinkedAccount], to draft: ZakatDraft) -> ZakatDraft {
        var next = draft
        next.bankDeposits = next.bankDeposits.filter { $0.source != .linked }
        next.investments = next.investments.filter { $0.source != .linked }
        next.retirement = next.retirement.filter { $0.source != .linked }
        next.crypto = next.crypto.filter { $0.source != .linked }
        next.immediateDebts = next.immediateDebts.filter { $0.source != .linked }
        next.longTermDebts = next.longTermDebts.filter { $0.source != .linked }

        for account in accounts {
            let item = namedAmount(from: account)
            switch account.type {
            case .checking, .savings, .moneyMarket:
                next.bankDeposits.append(item)
            case .brokerage:
                next.investments.append(item)
            case .retirement:
                next.retirement.append(item)
            case .crypto:
                next.crypto.append(item)
            case .credit:
                next.immediateDebts.append(item)
            case .loan:
                next.longTermDebts.append(item)
            case .other:
                next.bankDeposits.append(item)
            }
        }

        return next
    }

    public func plaidType(from type: String, subtype: String?) -> LinkedAccountType {
        switch type.lowercased() {
        case "depository":
            switch subtype?.lowercased() {
            case "savings": return .savings
            case "money market", "moneymarket": return .moneyMarket
            default: return .checking
            }
        case "investment":
            switch subtype?.lowercased() {
            case "401k", "403b", "ira", "roth", "pension", "retirement":
                return .retirement
            case "crypto exchange", "crypto":
                return .crypto
            default:
                return .brokerage
            }
        case "credit":
            return .credit
        case "loan":
            return .loan
        default:
            return .other
        }
    }

    private func namedAmount(from account: LinkedAccount) -> NamedAmount {
        let isLiability = account.type == .credit || account.type == .loan
        let amount = isLiability ? abs(account.currentBalance) : max(0, account.currentBalance)
        let included: Bool = {
            switch account.type {
            case .retirement: return false
            case .loan: return false
            default: return true
            }
        }()

        return NamedAmount(
            name: "\(account.institutionName) · \(account.displayName)",
            amount: amount,
            included: included,
            source: .linked,
            externalAccountID: account.id
        )
    }
}
