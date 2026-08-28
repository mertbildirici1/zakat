import SwiftUI

struct AppRootView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        Group {
            if session.hasAcceptedLegal == false {
                LegalGateView()
            } else {
                switch session.route {
                case .welcome:
                    NavigationStack {
                        WelcomeView()
                    }
                case .offline:
                    NavigationStack {
                        OfflineGatewayView()
                    }
                case .signedIn:
                    if AppConfig.accountsEnabled {
                        SignedInRootView()
                    } else {
                        NavigationStack {
                            WelcomeView()
                        }
                    }
                }
            }
        }
        .tint(Palette.forest)
        .animation(.easeInOut(duration: 0.22), value: session.route)
        .animation(.easeInOut(duration: 0.22), value: session.hasAcceptedLegal)
    }
}

struct SignedInRootView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        @Bindable var session = session
        TabView(selection: $session.selectedTab) {
            NavigationStack {
                DashboardView()
            }
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(0)

            NavigationStack {
                YearView()
            }
            .tabItem { Label("Year", systemImage: "chart.bar.fill") }
            .tag(1)

            NavigationStack {
                ConnectedAccountsView()
            }
            .tabItem { Label("Accounts", systemImage: "building.columns.fill") }
            .tag(2)

            NavigationStack {
                ProfileView()
            }
            .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
            .tag(3)
        }
        .toolbarBackground(Palette.cream, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .task {
            await session.refreshFromCloud()
        }
    }
}
