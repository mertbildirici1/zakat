import SwiftUI
import ZakatEngine

struct SettingsView: View {
    @Environment(AppSession.self) private var session
    @State private var isRefreshingMetals = false

    var body: some View {
        @Bindable var session = session

        ZStack {
            ScreenBackground()
            Form {
                Section("Nisab") {
                    Picker("Standard", selection: $session.draft.settings.nisabStandard) {
                        ForEach(NisabStandard.allCases) { standard in
                            Text(standard.title).tag(standard)
                        }
                    }
                    Text("Gold nisab is 87.48 g. Silver nisab is 612.36 g. Choose the view you follow.")
                        .font(.caption)
                        .foregroundStyle(Palette.muted)
                }

                Section("Metal prices") {
                    AmountField(title: "Gold price per gram", value: $session.draft.settings.goldPricePerGram)
                    AmountField(title: "Silver price per gram", value: $session.draft.settings.silverPricePerGram)
                    Button(isRefreshingMetals ? "Refreshing…" : "Refresh from market") {
                        isRefreshingMetals = true
                        Task {
                            await session.refreshMetalPrices()
                            isRefreshingMetals = false
                        }
                    }
                    .disabled(isRefreshingMetals)
                    if let status = session.metalsStatus {
                        Text(status)
                            .font(.caption)
                            .foregroundStyle(Palette.muted)
                    }
                }

                Section("Hawl") {
                    DatePicker(
                        "Hawl start",
                        selection: Binding(
                            get: { session.meta.hawlStartDate },
                            set: { session.updateHawl(start: $0, reminder: session.meta.hawlReminderEnabled) }
                        ),
                        displayedComponents: .date
                    )
                    Toggle(
                        "Remind me on the anniversary",
                        isOn: Binding(
                            get: { session.meta.hawlReminderEnabled },
                            set: { session.updateHawl(start: session.meta.hawlStartDate, reminder: $0) }
                        )
                    )
                    Text(hawlCaption)
                        .font(.caption)
                        .foregroundStyle(Palette.muted)
                }

                Section("What to include") {
                    Toggle("Include personal gold/silver jewelry", isOn: $session.draft.settings.includePersonalJewelry)
                    Toggle("Include retirement accounts", isOn: $session.draft.settings.includeRetirementAccounts)
                    Toggle("Deduct only debts due now", isOn: $session.draft.settings.deductOnlyImmediateDebts)
                }

                Section("Legal") {
                    NavigationLink("Terms, privacy, and disclaimer") {
                        LegalIndexView()
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .onChange(of: session.draft.settings) { _, _ in
            session.recalculate()
        }
    }

    private var hawlCaption: String {
        let days = session.hawlDaysRemaining
        if days > 0 {
            return "About \(days) days remain in this 354-day hawl. This is a reminder, not a ruling."
        }
        if days == 0 {
            return "Your recorded hawl is due today. Review your estimate with a scholar if needed."
        }
        return "Your recorded hawl date is \(abs(days)) days ago. Update the start date if you have already paid."
    }
}
