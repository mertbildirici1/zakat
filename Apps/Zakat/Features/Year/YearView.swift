import SwiftUI
import ZakatEngine

struct YearView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        let summary = session.yearSummary

        ZStack {
            ScreenBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("This hawl")
                            .font(.caption.weight(.semibold))
                            .tracking(0.8)
                            .foregroundStyle(Palette.gold)
                        Text(summary.formattedGain)
                            .font(.system(size: 40, weight: .semibold, design: .serif))
                            .foregroundStyle(summary.netGain >= 0 ? Palette.forest : Palette.rust)
                        Text("\(summary.start.formatted(date: .abbreviated, time: .omitted)) – \(summary.end.formatted(date: .abbreviated, time: .omitted)). Transfers omitted.")
                            .font(.subheadline)
                            .foregroundStyle(Palette.muted)
                    }

                    if session.transactions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("No activity yet")
                                .font(.headline)
                            Text("Link a bank to import this year’s activity.")
                                .font(.subheadline)
                                .foregroundStyle(Palette.muted)
                            Button("Connect a bank") {
                                session.selectedTab = 2
                            }
                            .font(.headline)
                            .foregroundStyle(Palette.cream)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Palette.forest, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .padding(18)
                        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    } else {
                        HStack(spacing: 10) {
                            yearStat(title: "Income", value: summary.formattedIncome, color: Palette.forest)
                            yearStat(title: "Spending", value: summary.formattedSpending, color: Palette.rust)
                        }

                        monthChart(summary.months)

                        insightCard

                        if summary.topIncome.isEmpty == false {
                            txList(title: "Largest income", items: summary.topIncome, positive: true)
                        }
                        if summary.topSpending.isEmpty == false {
                            txList(title: "Largest spending", items: summary.topSpending, positive: false)
                        }

                        Text("\(summary.transactionCount) transactions this hawl.")
                            .font(.caption)
                            .foregroundStyle(Palette.muted)
                    }
                }
                .padding(24)
            }
            .refreshable {
                await session.refreshFromCloud()
            }
        }
        .navigationTitle("Year")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var insightCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About zakat")
                .font(.headline)
            Text("Zakat is 2.5% of wealth now, not of this gain.")
                .font(.subheadline)
                .foregroundStyle(Palette.muted)
        }
        .padding(16)
        .background(Palette.forest.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func yearStat(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.muted)
            Text(value)
                .font(.title3.weight(.semibold).monospacedDigit())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func monthChart(_ months: [MonthBucket]) -> some View {
        let peak = months.map { max($0.income, $0.spending) }.max() ?? 1
        return VStack(alignment: .leading, spacing: 12) {
            Text("By month")
                .font(.headline)
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(months) { month in
                    VStack(spacing: 4) {
                        HStack(alignment: .bottom, spacing: 2) {
                            Capsule()
                                .fill(Palette.moss)
                                .frame(width: 6, height: barHeight(month.income, peak: peak))
                            Capsule()
                                .fill(Palette.rust.opacity(0.75))
                                .frame(width: 6, height: barHeight(month.spending, peak: peak))
                        }
                        Text(month.label)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Palette.muted)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 132, alignment: .bottom)
            HStack(spacing: 16) {
                legendDot(Palette.moss, "Income")
                legendDot(Palette.rust.opacity(0.75), "Spending")
            }
            .font(.caption)
            .foregroundStyle(Palette.muted)
        }
        .padding(16)
        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func barHeight(_ value: Decimal, peak: Decimal) -> CGFloat {
        let ratio = NSDecimalNumber(decimal: value).doubleValue / max(NSDecimalNumber(decimal: peak).doubleValue, 1)
        return max(4, CGFloat(ratio) * 96)
    }

    private func legendDot(_ color: Color, _ title: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(title)
        }
    }

    private func txList(title: String, items: [BankTransaction], positive: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            ForEach(items) { item in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.subheadline.weight(.medium))
                        Text(item.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(Palette.muted)
                    }
                    Spacer()
                    Text((positive ? "+" : "") + Money.display(item.amount))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(positive ? Palette.forest : Palette.rust)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
