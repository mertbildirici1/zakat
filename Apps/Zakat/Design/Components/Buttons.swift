import SwiftUI

struct PrimaryButton: View {
    let title: String
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Palette.cream)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(enabled ? Palette.forest : Palette.forest.opacity(0.4), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(!enabled)
        .buttonStyle(.plain)
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Palette.forest)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Palette.parchment, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct ModeCard: View {
    let eyebrow: String
    let title: String
    let detail: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(Palette.gold)
                .frame(width: 44, height: 44)
                .background(Palette.forest, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(eyebrow.uppercased())
                    .font(.caption.weight(.semibold))
                    .tracking(1.1)
                    .foregroundStyle(Palette.gold)
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Palette.forest.opacity(0.08), lineWidth: 1)
        )
    }
}
