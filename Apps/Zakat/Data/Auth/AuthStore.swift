import CryptoKit
import Foundation

enum AuthError: LocalizedError {
    case invalidName
    case invalidEmail
    case shortPassword
    case passwordMismatch
    case emailTaken
    case invalidCredentials
    case notSignedIn
    case mustAcceptLegal

    var errorDescription: String? {
        switch self {
        case .invalidName: return "Enter your name."
        case .invalidEmail: return "Enter a valid email address."
        case .shortPassword: return "Password must be at least 8 characters."
        case .passwordMismatch: return "Passwords do not match."
        case .emailTaken: return "An account with this email already exists."
        case .invalidCredentials: return "Email or password is incorrect."
        case .notSignedIn: return "You are not signed in."
        case .mustAcceptLegal: return "Accept the terms to continue."
        }
    }
}

enum AuthStore {
    private static let usersKey = "zakat.users.v1"
    private static let sessionKey = "zakat.sessionUserID.v1"
    private static let routeKey = "zakat.route.v1"
    private static let legalKey = "zakat.legalAccepted.v1"

    static var hasAcceptedLegal: Bool {
        get { UserDefaults.standard.bool(forKey: legalKey) }
        set { UserDefaults.standard.set(newValue, forKey: legalKey) }
    }

    static var route: SessionRoute {
        get {
            guard let raw = UserDefaults.standard.string(forKey: routeKey) else { return .welcome }
            return SessionRoute(rawValue: raw) ?? .welcome
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: routeKey)
        }
    }

    static var currentUserID: UUID? {
        get {
            guard let value = UserDefaults.standard.string(forKey: sessionKey) else { return nil }
            return UUID(uuidString: value)
        }
        set {
            UserDefaults.standard.set(newValue?.uuidString, forKey: sessionKey)
        }
    }

    static func currentUser() -> UserAccount? {
        guard let id = currentUserID else { return nil }
        return allUsers().first { $0.id == id }
    }

    static func allUsers() -> [UserAccount] {
        guard let data = UserDefaults.standard.data(forKey: usersKey) else { return [] }
        return (try? JSONDecoder().decode([UserAccount].self, from: data)) ?? []
    }

    static func createAccount(fullName: String, email: String, password: String, confirmPassword: String) throws -> UserAccount {
        let name = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEmail = Self.normalize(email)
        guard name.count >= 2 else { throw AuthError.invalidName }
        guard isValidEmail(normalizedEmail) else { throw AuthError.invalidEmail }
        guard password.count >= 8 else { throw AuthError.shortPassword }
        guard password == confirmPassword else { throw AuthError.passwordMismatch }
        guard allUsers().contains(where: { $0.email == normalizedEmail }) == false else { throw AuthError.emailTaken }

        let salt = UUID().uuidString
        let account = UserAccount(
            id: UUID(),
            fullName: name,
            email: normalizedEmail,
            salt: salt,
            passwordHash: hash(password, salt: salt),
            createdAt: Date()
        )
        save(allUsers() + [account])
        currentUserID = account.id
        route = .signedIn
        return account
    }

    static func signIn(email: String, password: String) throws -> UserAccount {
        let normalizedEmail = Self.normalize(email)
        guard let account = allUsers().first(where: { $0.email == normalizedEmail }) else {
            throw AuthError.invalidCredentials
        }
        let candidate = hash(password, salt: account.salt)
        guard candidate == account.passwordHash else { throw AuthError.invalidCredentials }
        currentUserID = account.id
        route = .signedIn
        return account
    }

    static func updateCurrentUser(fullName: String) throws -> UserAccount {
        let name = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard name.count >= 2 else { throw AuthError.invalidName }
        guard var account = currentUser() else { throw AuthError.notSignedIn }
        account.fullName = name
        var users = allUsers()
        if let index = users.firstIndex(where: { $0.id == account.id }) {
            users[index] = account
            save(users)
        }
        return account
    }

    static func resetPassword(email: String, newPassword: String, confirmPassword: String) throws {
        let normalizedEmail = Self.normalize(email)
        guard var account = allUsers().first(where: { $0.email == normalizedEmail }) else {
            throw AuthError.invalidCredentials
        }
        guard newPassword.count >= 8 else { throw AuthError.shortPassword }
        guard newPassword == confirmPassword else { throw AuthError.passwordMismatch }
        let salt = UUID().uuidString
        account.salt = salt
        account.passwordHash = hash(newPassword, salt: salt)
        var users = allUsers()
        if let index = users.firstIndex(where: { $0.id == account.id }) {
            users[index] = account
            save(users)
        }
    }

    static func signOut() {
        currentUserID = nil
        route = .welcome
    }

    static func deleteCurrentAccount() {
        guard let id = currentUserID else { return }
        save(allUsers().filter { $0.id != id })
        DraftStore.clearNamespace("user-\(id.uuidString)")
        currentUserID = nil
        route = .welcome
    }

    static func enterOffline() {
        currentUserID = nil
        route = .offline
    }

    static func leaveOffline() {
        route = .welcome
    }

    private static func save(_ users: [UserAccount]) {
        guard let data = try? JSONEncoder().encode(users) else { return }
        UserDefaults.standard.set(data, forKey: usersKey)
    }

    private static func normalize(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func isValidEmail(_ email: String) -> Bool {
        email.contains("@") && email.contains(".") && email.count >= 5
    }

    private static func hash(_ password: String, salt: String) -> String {
        let data = Data((salt + password).utf8)
        return SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
    }
}
