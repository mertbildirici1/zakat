import Foundation
@testable import ZakatEngine
import Testing

struct ZakatCalculatorTests {
    let calculator = ZakatCalculator()

    @Test func emptyDraftPaysNothing() {
        let result = calculator.calculate(.empty)
        #expect(result.zakatDue == 0)
        #expect(result.meetsNisab == false)
        #expect(result.netZakatable == 0)
    }

    @Test func belowNisabPaysNothing() {
        var draft = ZakatDraft()
        draft.settings.goldPricePerGram = 100
        draft.settings.nisabStandard = .gold
        draft.cashOnHand = 1_000
        let result = calculator.calculate(draft)
        #expect(result.meetsNisab == false)
        #expect(result.zakatDue == 0)
        #expect(result.selectedNisab == Decimal(string: "8748")!)
    }

    @Test func atNisabPaysTwoPointFivePercent() {
        var draft = ZakatDraft()
        draft.settings.goldPricePerGram = 100
        draft.settings.nisabStandard = .gold
        draft.cashOnHand = Decimal(string: "8748")!
        let result = calculator.calculate(draft)
        #expect(result.meetsNisab)
        #expect(result.zakatDue == Decimal(string: "218.70")!)
    }

    @Test func debtsReduceZakatableWealth() {
        var draft = ZakatDraft()
        draft.settings.goldPricePerGram = 100
        draft.cashOnHand = 20_000
        draft.immediateDebts = [NamedAmount(name: "Card", amount: 5_000)]
        let result = calculator.calculate(draft)
        #expect(result.netZakatable == 15_000)
        #expect(result.zakatDue == 375)
    }

    @Test func excludedRetirementIsIgnoredByDefault() {
        var draft = ZakatDraft()
        draft.settings.goldPricePerGram = 100
        draft.settings.includeRetirementAccounts = false
        draft.cashOnHand = 20_000
        draft.retirement = [NamedAmount(name: "401k", amount: 80_000)]
        let result = calculator.calculate(draft)
        #expect(result.retirement == 0)
        #expect(result.netZakatable == 20_000)
    }

    @Test func includedRetirementIsZakatable() {
        var draft = ZakatDraft()
        draft.settings.goldPricePerGram = 100
        draft.settings.includeRetirementAccounts = true
        draft.cashOnHand = 20_000
        draft.retirement = [NamedAmount(name: "401k", amount: 80_000)]
        let result = calculator.calculate(draft)
        #expect(result.retirement == 80_000)
        #expect(result.netZakatable == 100_000)
        #expect(result.zakatDue == 2_500)
    }

    @Test func goldKaratConvertsToFineGold() {
        var draft = ZakatDraft()
        draft.settings.goldPricePerGram = 100
        draft.gold = [MetalItem(name: "18k", grams: 24, karat: 18)]
        let result = calculator.calculate(draft)
        #expect(result.goldValue == 1_800)
    }

    @Test func personalJewelryCanBeExcluded() {
        var draft = ZakatDraft()
        draft.settings.goldPricePerGram = 100
        draft.settings.includePersonalJewelry = false
        draft.gold = [
            MetalItem(name: "Bar", grams: 10, karat: 24),
            MetalItem(name: "Ring", grams: 10, karat: 24, isPersonalJewelry: true),
        ]
        let result = calculator.calculate(draft)
        #expect(result.goldValue == 1_000)
    }

    @Test func longTermDebtIsIgnoredWhenSettingIsOn() {
        var draft = ZakatDraft()
        draft.settings.goldPricePerGram = 100
        draft.settings.deductOnlyImmediateDebts = true
        draft.cashOnHand = 20_000
        draft.longTermDebts = [NamedAmount(name: "Mortgage", amount: 250_000)]
        let result = calculator.calculate(draft)
        #expect(result.netZakatable == 20_000)
        #expect(result.deductibleLiabilities == 0)
    }

    @Test func negativeCashDoesNotCreateZakatCredit() {
        var draft = ZakatDraft()
        draft.cashOnHand = -500
        draft.immediateDebts = [NamedAmount(name: "Card", amount: 1_000)]
        let result = calculator.calculate(draft)
        #expect(result.netZakatable == 0)
        #expect(result.zakatDue == 0)
    }
}

struct AccountCategoryMapperTests {
    let mapper = AccountCategoryMapper()

    @Test func mapsPlaidTypes() {
        #expect(mapper.plaidType(from: "depository", subtype: "savings") == .savings)
        #expect(mapper.plaidType(from: "investment", subtype: "401k") == .retirement)
        #expect(mapper.plaidType(from: "investment", subtype: "brokerage") == .brokerage)
        #expect(mapper.plaidType(from: "credit", subtype: "credit card") == .credit)
        #expect(mapper.plaidType(from: "loan", subtype: "mortgage") == .loan)
    }

    @Test func linkedAccountsReplacePreviousLinkedRows() {
        var draft = ZakatDraft()
        draft.bankDeposits = [
            NamedAmount(name: "Manual cash", amount: 100, source: .manual),
            NamedAmount(name: "Old linked", amount: 50, source: .linked, externalAccountID: "old"),
        ]

        let accounts = [
            LinkedAccount(
                id: "new",
                institutionName: "Chase",
                name: "Checking",
                mask: "1234",
                type: .checking,
                currentBalance: 4_250
            ),
        ]

        let next = mapper.apply(accounts, to: draft)
        #expect(next.bankDeposits.count == 2)
        #expect(next.bankDeposits.contains { $0.source == .manual && $0.amount == 100 })
        #expect(next.bankDeposits.contains { $0.externalAccountID == "new" && $0.amount == 4_250 })
    }

    @Test func removingLinkedRowsKeepsManualEntries() {
        var draft = ZakatDraft()
        draft.cashOnHand = 200
        draft.bankDeposits = [
            NamedAmount(name: "Manual", amount: 100, source: .manual),
            NamedAmount(name: "Chase", amount: 4_250, source: .linked, externalAccountID: "ch"),
        ]
        let cleaned = draft.removingLinkedRows()
        #expect(cleaned.cashOnHand == 200)
        #expect(cleaned.bankDeposits.count == 1)
        #expect(cleaned.bankDeposits.first?.name == "Manual")
    }

    @Test func retirementAndLoansAreOffByDefault() {
        let accounts = [
            LinkedAccount(id: "1", institutionName: "Vanguard", name: "401k", type: .retirement, currentBalance: 10_000),
            LinkedAccount(id: "2", institutionName: "Chase", name: "Mortgage", type: .loan, currentBalance: 200_000),
            LinkedAccount(id: "3", institutionName: "Amex", name: "Card", type: .credit, currentBalance: -900),
        ]
        let draft = mapper.apply(accounts, to: .empty)
        #expect(draft.retirement.first?.included == false)
        #expect(draft.longTermDebts.first?.included == false)
        #expect(draft.immediateDebts.first?.amount == 900)
        #expect(draft.immediateDebts.first?.included == true)
    }
}
