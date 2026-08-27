import SwiftUI

enum Palette {
    static let forest = Color(red: 0.09, green: 0.22, blue: 0.18)
    static let moss = Color(red: 0.18, green: 0.40, blue: 0.31)
    static let cream = Color(red: 0.97, green: 0.95, blue: 0.91)
    static let parchment = Color(red: 0.94, green: 0.91, blue: 0.85)
    static let gold = Color(red: 0.70, green: 0.55, blue: 0.30)
    static let ink = Color(red: 0.12, green: 0.14, blue: 0.13)
    static let muted = Color(red: 0.39, green: 0.41, blue: 0.39)
    static let rust = Color(red: 0.55, green: 0.27, blue: 0.22)
}

struct ScreenBackground: View {
    var body: some View {
        Palette.cream
            .ignoresSafeArea()
    }
}
