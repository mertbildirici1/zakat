import SwiftUI
import ZakatEngine

struct DashboardView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        let result = session.lastResult ?? ZakatCalculator().calculate(session.draft)

        ZStack {
            ScreenBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    NavigationLink {
                        ResultView(result: result)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current estimate")
                                .font(.caption.weight(.semibold))
                                .tracking(0.8)
                                .foregroundStyle(Palette.gold)
                            Text(result.meetsNisab ? result.formattedDue : "Below nisab")
                                .font(.system(size: 36, weight: .semibold, design: .serif))
                                .foregroundStyle(Palette.ink)
                            Text("On \(result.formattedNet) of zakatable wealth")
                                .font(.subheadline)
                                .foregroundStyle(Palette.muted)
                            Text("Tap for the full breakdown")
                                .font(.caption)
                                .foregroundStyle(Palette.muted)
                                .padding(.top, 4)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(Palette.forest.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 8) {
                        Text("Hawl")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Palette.gold)
                        Text(session.hawlDaysRemaining >= 0
                             ? "\(session.hawlDaysRemaining) days remaining"
                             : "Anniversary passed")
                            .font(.caption)
                            .foregroundStyle(Palette.muted)
                    }

                    NavigationLink {
                        HistoryView()
                    } label: {
                        ModeCard(
                            eyebrow: "Saved",
                            title: "History",
                            detail: session.history.isEmpty ? "Results you open will be stored on this phone." : "\(session.history.count) saved estimates.",
                            systemImage: "clock"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        ConnectedAccountsView()
                    } label: {
                        ModeCard(
                            eyebrow: "Connected",
                            title: session.linkedAccounts.isEmpty ? "Link bank accounts" : "Manage linked accounts",
                            detail: session.linkedAccounts.isEmpty
                                ? "Prefill balances from banks, brokerages, and crypto. You review every line."
                                : "\(session.linkedAccounts.count) linked · tap to add another institution or review.",
                            systemImage: "building.columns"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        SettingsView()
                    } label: {
                        ModeCard(
                            eyebrow: "Rules",
                            title: "Nisab and what to include",
                            detail: session.draft.settings.nisabStandard == .gold
                                ? "Using gold nisab. Jewelry, retirement, and debts can be changed here."
                                : "Using silver nisab. Jewelry, retirement, and debts can be changed here.",
                            systemImage: "slider.horizontal.3"
                        )
                    }
                    .buttonStyle(.plain)

                    if session.linkedAccounts.isEmpty == false {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Linked")
                                .font(.headline)
                            ForEach(session.linkedAccounts.prefix(4)) { account in
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
                }
                .padding(24)
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
