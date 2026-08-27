import SwiftUI

struct LabeledField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType?
    var autocapitalization: TextInputAutocapitalization = .never

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Palette.muted)
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboard)
                        .textInputAutocapitalization(autocapitalization)
                        .autocorrectionDisabled()
                }
            }
            .textContentType(contentType)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

struct AvatarView: View {
    let initials: String
    var size: CGFloat = 64

    var body: some View {
        Text(initials)
            .font(.system(size: size * 0.34, weight: .semibold, design: .serif))
            .foregroundStyle(Palette.cream)
            .frame(width: size, height: size)
            .background(Palette.forest, in: Circle())
    }
}

struct ProfileRow: View {
    let title: String
    var systemImage: String
    var detail: String? = nil

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(Palette.gold)
                .frame(width: 28)
            Text(title)
                .foregroundStyle(Palette.ink)
            Spacer()
            if let detail {
                Text(detail)
                    .foregroundStyle(Palette.muted)
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.muted.opacity(0.7))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
