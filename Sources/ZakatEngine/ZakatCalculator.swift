import Foundation

public struct ZakatCalculator: Sendable {
    public init() {}

    public func calculate(_ draft: ZakatDraft) -> ZakatResult {
        let settings = draft.settings
        let cashAndBanks = max(0, draft.cashOnHand) + sum(draft.bankDeposits)

        let goldValue = draft.gold.reduce(Decimal.zero) { total, item in
            if item.isPersonalJewelry && !settings.includePersonalJewelry {
                return total
            }
            return total + item.value(pricePerGram: settings.goldPricePerGram)
        }

        let silverValue = draft.silver.reduce(Decimal.zero) { total, item in
            if item.isPersonalJewelry && !settings.includePersonalJewelry {
                return total
            }
            return total + item.value(pricePerGram: settings.silverPricePerGram)
        }

        let investments = sum(draft.investments)
        let retirement = settings.includeRetirementAccounts ? sum(draft.retirement) : 0
        let crypto = sum(draft.crypto)
        let business = sum(draft.businessInventory)
        let receivables = sum(draft.receivables)

        let gross = cashAndBanks + goldValue + silverValue + investments + retirement + crypto + business + receivables

        var deductible = sum(draft.immediateDebts)
        if !settings.deductOnlyImmediateDebts {
            deductible += sum(draft.longTermDebts)
        }

        let net = max(0, gross - deductible)
        let selectedNisab = settings.selectedNisabValue
        let meetsNisab = net >= selectedNisab
        let due = meetsNisab ? Money.rounded(net * Money.zakatRate) : 0

        let breakdown: [BreakdownRow] = [
            BreakdownRow(id: "cash", title: "Cash & banks", amount: Money.rounded(cashAndBanks)),
            BreakdownRow(id: "gold", title: "Gold", amount: Money.rounded(goldValue)),
            BreakdownRow(id: "silver", title: "Silver", amount: Money.rounded(silverValue)),
            BreakdownRow(id: "investments", title: "Investments", amount: Money.rounded(investments)),
            BreakdownRow(id: "retirement", title: "Retirement", amount: Money.rounded(retirement)),
            BreakdownRow(id: "crypto", title: "Crypto", amount: Money.rounded(crypto)),
            BreakdownRow(id: "business", title: "Business", amount: Money.rounded(business)),
            BreakdownRow(id: "receivables", title: "Owed to you", amount: Money.rounded(receivables)),
            BreakdownRow(id: "debts", title: "Debts", amount: Money.rounded(deductible), isDeduction: true),
        ].filter { $0.amount > 0 }

        return ZakatResult(
            currencyCode: settings.currencyCode,
            rate: Money.zakatRate,
            cashAndBanks: Money.rounded(cashAndBanks),
            goldValue: Money.rounded(goldValue),
            silverValue: Money.rounded(silverValue),
            investments: Money.rounded(investments),
            retirement: Money.rounded(retirement),
            crypto: Money.rounded(crypto),
            businessInventory: Money.rounded(business),
            receivables: Money.rounded(receivables),
            grossZakatable: Money.rounded(gross),
            deductibleLiabilities: Money.rounded(deductible),
            netZakatable: Money.rounded(net),
            goldNisab: Money.rounded(settings.goldNisabValue),
            silverNisab: Money.rounded(settings.silverNisabValue),
            selectedNisab: Money.rounded(selectedNisab),
            nisabStandard: settings.nisabStandard,
            meetsNisab: meetsNisab,
            zakatDue: due,
            breakdown: breakdown
        )
    }

    private func sum(_ items: [NamedAmount]) -> Decimal {
        items.reduce(0) { $0 + $1.contribution }
    }
}
