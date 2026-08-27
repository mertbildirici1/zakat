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
                    SignedInRootView()
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
                ManualCalculatorView()
            }
            .tabItem { Label("Calculate", systemImage: "square.grid.2x2.fill") }
            .tag(1)

            NavigationStack {
                ProfileView()
            }
            .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
            .tag(2)
        }
        .toolbarBackground(Palette.cream, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
