import Foundation

enum SessionRoute: String, Codable, Sendable {
    case welcome
    case offline
    case signedIn
}

struct UserAccount: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var fullName: String
    var email: String
    var salt: String
    var passwordHash: String
    var createdAt: Date

    var initials: String {
        let parts = fullName.split(separator: " ").prefix(2)
        let letters = parts.compactMap { $0.first }.map(String.init)
        if letters.isEmpty {
            return String(email.prefix(1)).uppercased()
        }
        return letters.joined().uppercased()
    }

    var firstName: String {
        fullName.split(separator: " ").first.map(String.init) ?? fullName
    }
}
