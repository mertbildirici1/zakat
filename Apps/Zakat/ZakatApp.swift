import SwiftUI

@main
struct ZakatApp: App {
    @State private var session = AppSession()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(session)
                .onAppear { applyDebugLaunchHooks() }
        }
    }

    private func applyDebugLaunchHooks() {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-ui-offline") {
            session.acceptLegal()
            session.enterOffline()
        } else if args.contains("-ui-signed-in") || args.contains("-ui-profile") {
            session.acceptLegal()
            let email = "demo@zakat.app"
            do {
                try session.signIn(email: email, password: "password123")
            } catch {
                try? session.createAccount(
                    fullName: "Demo User",
                    email: email,
                    password: "password123",
                    confirmPassword: "password123"
                )
            }
            if args.contains("-ui-profile") {
                session.selectedTab = 2
            }
        }
        #endif
    }
}
