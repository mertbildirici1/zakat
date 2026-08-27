import SwiftUI

struct OfflineGatewayView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        ZStack {
            ScreenBackground()
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Offline")
                        .font(.caption.weight(.semibold))
                        .tracking(1.2)
                        .foregroundStyle(Palette.gold)
                    Text("Calculate on this phone")
                        .font(.system(size: 34, weight: .semibold, design: .serif))
                        .foregroundStyle(Palette.forest)
                    Text("No sign-in and no bank connection. Enter cash, gold, investments, and debts yourself, then see what you owe.")
                        .font(.body)
                        .foregroundStyle(Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 12) {
                    NavigationLink {
                        ManualCalculatorView()
                    } label: {
                        Text("Start calculating")
                            .font(.headline)
                            .foregroundStyle(Palette.cream)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Palette.forest, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    NavigationLink {
                        SettingsView()
                    } label: {
                        Text("Nisab and metal prices")
                            .font(.headline)
                            .foregroundStyle(Palette.forest)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Palette.parchment, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    NavigationLink {
                        HistoryView()
                    } label: {
                        Text("History")
                            .font(.headline)
                            .foregroundStyle(Palette.forest)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Palette.parchment, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }

                NavigationLink {
                    LegalIndexView()
                } label: {
                    Text("Terms and privacy")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.forest)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("Stays on this device", systemImage: "lock.fill")
                    Label("You can sign in later if you want to link accounts", systemImage: "person.crop.circle")
                }
                .font(.subheadline)
                .foregroundStyle(Palette.muted)

                Spacer()
            }
            .padding(24)
        }
        .navigationTitle("Offline")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back") {
                    session.leaveOffline()
                }
            }
        }
    }
}
