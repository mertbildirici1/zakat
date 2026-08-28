import SwiftUI
import ZakatEngine

struct DashboardView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        let result = session.lastResult ?? ZakatCalculator().calculate(session.draft)
        let year = session.yearSummary

        ZStack {
            ScreenBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    if let status = session.cloudStatus {
                        Text(status)
                            .font(.caption)
                            .foregroundStyle(Palette.muted)
                    }

                    NavigationLink {
                        ResultView(result: result)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Zakat due")
                                .font(.caption.weight(.semibold))
                                .tracking(0.8)
                                .foregroundStyle(Palette.gold)
                            Text(result.meetsNisab ? result.formattedDue : "Below nisab")
                                .font(.system(size: 36, weight: .semibold, design: .serif))
                                .foregroundStyle(Palette.ink)
                            Text("2.5% of \(result.formattedNet)")
                                .font(.subheadline)
                                .foregroundStyle(Palette.muted)
                            Text("Tap for breakdown")
                                .font(.caption)
                                .foregroundStyle(Palette.muted)
                                .padding(.top, 4)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(Palette.forest.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        session.selectedTab = 1
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("This hawl")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Palette.gold)
                                Text(session.transactions.isEmpty ? "Link a bank to see this year" : year.formattedGain)
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(Palette.ink)
                                Text(session.transactions.isEmpty
                                     ? "Income minus spending."
                                     : "Income \(year.formattedIncome) · spending \(year.formattedSpending)")
                                    .font(.caption)
                                    .foregroundStyle(Palette.muted)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Palette.muted)
                        }
                        .padding(18)
                        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 8) {
                        Text("Hawl")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Palette.gold)
                        Text(session.hawlDaysRemaining > 0
                             ? "\(session.hawlDaysRemaining) days remaining"
                             : session.hawlDaysRemaining == 0 ? "Due today"
                             : "Anniversary passed")
                            .font(.caption)
                            .foregroundStyle(Palette.muted)
                    }

                    NavigationLink {
                        ManualCalculatorView()
                    } label: {
                        ModeCard(
                            eyebrow: "Holdings",
                            title: "Gold & cash",
                            detail: "Add jewelry and cash banks can’t see.",
                            systemImage: "banknote"
                        )
                    }
                    .buttonStyle(.plain)

                    if session.linkedAccounts.isEmpty {
                        Button {
                            session.selectedTab = 2
                        } label: {
                            ModeCard(
                                eyebrow: "Accounts",
                                title: "Connect a bank",
                                detail: "Import balances and this year’s activity.",
                                systemImage: "building.columns"
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Linked")
                                    .font(.headline)
                                Spacer()
                                Button("Manage") { session.selectedTab = 2 }
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Palette.forest)
                            }
                            ForEach(session.linkedAccounts.prefix(5)) { account in
                                HStack {
                                    Text(account.displayName)
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                    Text(Money.display(account.currentBalance, currencyCode: account.isoCurrencyCode))
                                        .font(.subheadline.monospacedDigit())
                                        .foregroundStyle(Palette.muted)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }

                    NavigationLink {
                        SettingsView()
                    } label: {
                        ModeCard(
                            eyebrow: "Rules",
                            title: "Nisab & rules",
                            detail: session.draft.settings.nisabStandard == .gold
                                ? "Using gold nisab."
                                : "Using silver nisab.",
                            systemImage: "slider.horizontal.3"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        HistoryView()
                    } label: {
                        ModeCard(
                            eyebrow: "Saved",
                            title: "History",
                            detail: session.history.isEmpty ? "Estimates you open are saved here." : "\(session.history.count) saved estimates.",
                            systemImage: "clock"
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(24)
            }
            .refreshable {
                await session.refreshFromCloud()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { session.recalculate() }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.greeting)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Palette.gold)
                Text(session.currentUser?.firstName ?? "there")
                    .font(.system(size: 34, weight: .semibold, design: .serif))
                    .foregroundStyle(Palette.forest)
            }
            Spacer()
            AvatarView(initials: session.currentUser?.initials ?? "Z", size: 52)
        }
    }
}
