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
        } else if AppConfig.accountsEnabled, args.contains("-ui-signed-in") || args.contains("-ui-profile") || args.contains("-ui-year") {
            session.acceptLegal()
            Task {
                let email = "demo@zakat.app"
                do {
                    try await session.signIn(email: email, password: "password123")
                } catch {
                    try? await session.createAccount(
                        fullName: "Demo User",
                        email: email,
                        password: "password123",
                        confirmPassword: "password123"
                    )
                }
                if session.hasCloudSession {
                    try? await session.connectCloudInstitution("chase")
                }
                if args.contains("-ui-profile") {
                    session.selectedTab = 3
                } else if args.contains("-ui-year") {
                    session.selectedTab = 1
                }
            }
        }
        #endif
    }
}
