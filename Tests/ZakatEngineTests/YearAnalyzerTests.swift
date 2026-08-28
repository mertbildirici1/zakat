import Foundation
@testable import ZakatEngine
import Testing

struct YearAnalyzerTests {
    let analyzer = YearAnalyzer()
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    @Test func incomeMinusSpendingIsNetGain() {
        let start = date(2026, 1, 1)
        let tx = [
            txn("1", start, 3_000, .income),
            txn("2", date(2026, 1, 5), -1_200, .spending),
        ]
        let summary = analyzer.summarize(tx, from: start, to: date(2026, 1, 31), calendar: calendar)
        #expect(summary.income == 3_000)
        #expect(summary.spending == 1_200)
        #expect(summary.netGain == 1_800)
        #expect(summary.transactionCount == 2)
    }

    @Test func transfersDoNotChangeGain() {
        let start = date(2026, 1, 1)
        let tx = [
            txn("1", start, 2_000, .income),
            txn("2", date(2026, 1, 2), -500, .transfer),
            txn("3", date(2026, 1, 2), 500, .transfer),
        ]
        let summary = analyzer.summarize(tx, from: start, to: date(2026, 1, 31), calendar: calendar)
        #expect(summary.netGain == 2_000)
        #expect(summary.transfers == 0)
    }

    @Test func datesOutsideHawlAreIgnored() {
        let start = date(2026, 6, 1)
        let tx = [
            txn("old", date(2026, 1, 1), 9_000, .income),
            txn("in", date(2026, 6, 10), 100, .income),
        ]
        let summary = analyzer.summarize(tx, from: start, to: date(2026, 6, 30), calendar: calendar)
        #expect(summary.income == 100)
        #expect(summary.transactionCount == 1)
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func txn(_ id: String, _ date: Date, _ amount: Decimal, _ kind: CashflowKind) -> BankTransaction {
        BankTransaction(id: id, accountID: "a", date: date, name: id, amount: amount, kind: kind)
    }
}
