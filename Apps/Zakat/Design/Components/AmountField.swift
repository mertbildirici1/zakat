import SwiftUI
import ZakatEngine

struct AmountField: View {
    let title: String
    @Binding var value: Decimal
    var prefix: String = "$"

    @State private var text: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Palette.muted)
            HStack {
                Text(prefix)
                    .foregroundStyle(Palette.muted)
                TextField("0", text: $text)
                    .keyboardType(.decimalPad)
                    .textInputAutocapitalization(.never)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Palette.parchment, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .onAppear { text = Self.format(value) }
        .onChange(of: text) { _, newValue in
            let parsed = Self.parse(newValue)
            if parsed != value {
                value = parsed
            }
        }
        .onChange(of: value) { _, newValue in
            let parsed = Self.parse(text)
            if parsed != newValue {
                text = Self.format(newValue)
            }
        }
    }

    private static func parse(_ string: String) -> Decimal {
        let cleaned = string.filter { $0.isNumber || $0 == "." }
        return Decimal(string: cleaned) ?? 0
    }

    private static func format(_ value: Decimal) -> String {
        if value == 0 { return "" }
        return NSDecimalNumber(decimal: value).stringValue
    }
}

struct NamedAmountEditor: View {
    @Binding var items: [NamedAmount]
    var placeholderName: String
    var emptyTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(items) { item in
                NamedAmountRow(
                    item: binding(for: item.id),
                    placeholderName: placeholderName,
                    onDelete: { delete(item.id) }
                )
            }

            Button {
                items.append(NamedAmount(name: "", amount: 0))
            } label: {
                Label(emptyTitle, systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.forest)
            }
        }
    }

    private func binding(for id: UUID) -> Binding<NamedAmount> {
        Binding(
            get: {
                items.first(where: { $0.id == id }) ?? NamedAmount(id: id, name: "", amount: 0)
            },
            set: { updated in
                guard let index = items.firstIndex(where: { $0.id == id }) else { return }
                items[index] = updated
            }
        )
    }

    private func delete(_ id: UUID) {
        items.removeAll { $0.id == id }
    }
}

private struct NamedAmountRow: View {
    @Binding var item: NamedAmount
    var placeholderName: String
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField(placeholderName, text: $item.name)
                    .font(.headline)
                Toggle("", isOn: $item.included)
                    .labelsHidden()
                    .tint(Palette.moss)
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundStyle(Palette.rust)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete")
            }
            AmountField(title: "Amount", value: $item.amount)
            if item.source == .linked {
                Text("Imported")
                    .font(.caption)
                    .foregroundStyle(Palette.gold)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
