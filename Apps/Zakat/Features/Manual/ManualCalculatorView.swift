import SwiftUI
import ZakatEngine

struct ManualCalculatorView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        @Bindable var session = session
        let result = session.lastResult ?? ZakatCalculator().calculate(session.draft)

        ZStack(alignment: .bottom) {
            ScreenBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(session.route == .offline
                         ? "Enter what you own. Toggle anything you do not want included."
                         : "Edit holdings here. Linked accounts appear as imported rows you can turn off.")
                        .font(.subheadline)
                        .foregroundStyle(Palette.muted)

                    section("Cash") {
                        AmountField(title: "Cash on hand", value: $session.draft.cashOnHand)
                    }

                    section("Bank deposits") {
                        NamedAmountEditor(
                            items: $session.draft.bankDeposits,
                            placeholderName: "Account name",
                            emptyTitle: "Add a bank account"
                        )
                    }

                    section("Gold") {
                        MetalEditor(items: $session.draft.gold, metalName: "gold")
                    }

                    section("Silver") {
                        MetalEditor(items: $session.draft.silver, metalName: "silver")
                    }

                    section("Investments") {
                        NamedAmountEditor(
                            items: $session.draft.investments,
                            placeholderName: "Brokerage or fund",
                            emptyTitle: "Add an investment"
                        )
                    }

                    section("Retirement") {
                        Text("Off by default. Turn on in Settings if you treat accessible retirement wealth as zakatable.")
                            .font(.caption)
                            .foregroundStyle(Palette.muted)
                        NamedAmountEditor(
                            items: $session.draft.retirement,
                            placeholderName: "401(k), IRA…",
                            emptyTitle: "Add a retirement account"
                        )
                    }

                    section("Crypto") {
                        NamedAmountEditor(
                            items: $session.draft.crypto,
                            placeholderName: "Wallet or exchange",
                            emptyTitle: "Add crypto"
                        )
                    }

                    section("Business inventory") {
                        NamedAmountEditor(
                            items: $session.draft.businessInventory,
                            placeholderName: "Inventory or trade goods",
                            emptyTitle: "Add inventory"
                        )
                    }

                    section("Money owed to you") {
                        NamedAmountEditor(
                            items: $session.draft.receivables,
                            placeholderName: "Who owes you",
                            emptyTitle: "Add a receivable"
                        )
                    }

                    section("Debts due now") {
                        NamedAmountEditor(
                            items: $session.draft.immediateDebts,
                            placeholderName: "Credit card, bill…",
                            emptyTitle: "Add a debt"
                        )
                    }

                    HStack {
                        Button("Load example") {
                            let settings = session.draft.settings
                            session.draft = .example
                            session.draft.settings = settings
                            session.recalculate()
                        }
                        Spacer()
                        Button("Clear all", role: .destructive) {
                            session.resetDraft()
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.bottom, session.route == .signedIn ? 140 : 120)
                }
                .padding(20)
            }

            NavigationLink {
                ResultView(result: result)
            } label: {
                VStack(spacing: 4) {
                    Text(result.meetsNisab ? "Zakat due \(result.formattedDue)" : "Below nisab")
                        .font(.headline)
                    Text("Net zakatable \(result.formattedNet)")
                        .font(.caption)
                        .opacity(0.8)
                }
                .foregroundStyle(Palette.cream)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Palette.forest, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
        }
        .navigationTitle(session.route == .offline ? "Manual entry" : "Calculate")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: session.draft) { _, _ in
            session.recalculate()
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Palette.forest)
            content()
        }
    }
}

struct MetalEditor: View {
    @Binding var items: [MetalItem]
    var metalName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach($items) { $item in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        TextField("Description", text: $item.name)
                            .font(.headline)
                        Toggle("", isOn: $item.included)
                            .labelsHidden()
                            .tint(Palette.moss)
                        Button(role: .destructive) {
                            items.removeAll { $0.id == item.id }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(Palette.rust)
                        }
                    }
                    AmountField(title: "Weight (grams)", value: $item.grams, prefix: "g")
                    HStack {
                        Text("Karat")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Palette.muted)
                        Spacer()
                        Picker("Karat", selection: $item.karat) {
                            ForEach([24, 22, 21, 18, 14, 10], id: \.self) { karat in
                                Text("\(karat)k").tag(karat)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    Toggle("Personal jewelry", isOn: $item.isPersonalJewelry)
                        .tint(Palette.moss)
                }
                .padding(14)
                .background(Color.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            Button {
                items.append(MetalItem(name: "", grams: 0))
            } label: {
                Label("Add \(metalName)", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.forest)
            }
        }
    }
}
