import SwiftUI
import ZakatEngine

struct ResultView: View {
    @Environment(AppSession.self) private var session
    let result: ZakatResult

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(result.meetsNisab ? "Zakat due" : "No zakat due yet")
                            .font(.caption.weight(.semibold))
                            .tracking(1)
                            .foregroundStyle(Palette.gold)
                        Text(result.meetsNisab ? result.formattedDue : Money.display(0, currencyCode: result.currencyCode))
                            .font(.system(size: 48, weight: .semibold, design: .serif))
                            .foregroundStyle(Palette.forest)
                        Text("2.5% of \(result.formattedNet) net wealth.")
                            .font(.subheadline)
                            .foregroundStyle(Palette.muted)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Nisab")
                            .font(.headline)
                        nisabRow("Gold standard", result.goldNisab, selected: result.nisabStandard == .gold)
                        nisabRow("Silver standard", result.silverNisab, selected: result.nisabStandard == .silver)
                        Text(result.meetsNisab
                             ? "You meet the selected nisab."
                             : "Below nisab, so this estimate is zero.")
                            .font(.caption)
                            .foregroundStyle(Palette.muted)
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Breakdown")
                            .font(.headline)
                        ForEach(result.breakdown) { row in
                            HStack {
                                Text(row.title)
                                    .foregroundStyle(Palette.ink)
                                Spacer()
                                Text((row.isDeduction ? "−" : "") + Money.display(row.amount, currencyCode: result.currencyCode))
                                    .monospacedDigit()
                                    .foregroundStyle(row.isDeduction ? Palette.rust : Palette.ink)
                            }
                            .font(.subheadline)
                        }
                    }

                    Text("An estimate, not a fatwa. Confirm with a scholar.")
                        .font(.caption)
                        .foregroundStyle(Palette.muted)

                    if session.yearSummary.transactionCount > 0 {
                        Text("This hawl: \(session.yearSummary.formattedGain). Insight only, not the zakat base.")
                            .font(.caption)
                            .foregroundStyle(Palette.muted)
                    }

                    ShareLink(item: shareText) {
                        Text("Share estimate")
                            .font(.headline)
                            .foregroundStyle(Palette.forest)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Palette.parchment, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(24)
            }
        }
        .navigationTitle("Result")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            session.saveSnapshot()
        }
    }

    private var shareText: String {
        if result.meetsNisab {
            return "Zakat estimate: \(result.formattedDue) on \(result.formattedNet). Estimate, not a fatwa."
        }
        return "Zakatable wealth \(result.formattedNet) is below nisab. Estimate, not a fatwa."
    }

    private func nisabRow(_ title: String, _ amount: Decimal, selected: Bool) -> some View {
        HStack {
            Text(title)
            if selected {
                Text("Selected")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Palette.gold.opacity(0.2), in: Capsule())
            }
            Spacer()
            Text(Money.display(amount, currencyCode: result.currencyCode))
                .monospacedDigit()
        }
        .font(.subheadline)
    }
}
