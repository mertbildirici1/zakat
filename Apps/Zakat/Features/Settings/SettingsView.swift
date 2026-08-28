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
                    Text("Gold 87.48 g · silver 612.36 g.")
                        .font(.caption)
                        .foregroundStyle(Palette.muted)
                }

                Section("Metal prices") {
                    AmountField(title: "Gold / gram", value: $session.draft.settings.goldPricePerGram)
                    AmountField(title: "Silver / gram", value: $session.draft.settings.silverPricePerGram)
                    Button(isRefreshingMetals ? "Refreshing…" : "Refresh prices") {
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
                        "Remind me when due",
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
                    Toggle("Include personal jewelry", isOn: $session.draft.settings.includePersonalJewelry)
                    Toggle("Include retirement", isOn: $session.draft.settings.includeRetirementAccounts)
                    Toggle("Only debts due now", isOn: $session.draft.settings.deductOnlyImmediateDebts)
                }

                Section("Legal") {
                    NavigationLink("Terms & privacy") {
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
            return "\(days) days left in this hawl. Reminder only."
        }
        if days == 0 {
            return "Hawl is due today."
        }
        return "Hawl date was \(abs(days)) days ago. Update if already paid."
    }
}
