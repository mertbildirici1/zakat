import Foundation
import ZakatEngine

struct CloudAuthResponse: Codable, Sendable {
    var token: String
    var user: CloudUser
}

struct CloudUser: Codable, Sendable {
    var id: String
    var fullName: String
    var email: String
    var createdAt: Date?
}

struct CloudSnapshot: Codable, Sendable {
    var accounts: [LinkedAccount]
    var transactions: [BankTransaction]
}

enum SessionTokenStore {
    private static let key = "zakat.cloud.token"

    static var token: String? {
        get { UserDefaults.standard.string(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}

struct CloudAPI {
    var baseURL: URL
    var token: String?

    func register(fullName: String, email: String, password: String) async throws -> CloudAuthResponse {
        try await post("/v1/auth/register", body: RegisterBody(fullName: fullName, email: email, password: password), authed: false)
    }

    func login(email: String, password: String) async throws -> CloudAuthResponse {
        try await post("/v1/auth/login", body: LoginBody(email: email, password: password), authed: false)
    }

    func snapshot() async throws -> CloudSnapshot {
        try await get("/v1/snapshot")
    }

    func linkToken() async throws -> LinkSession {
        try await post("/v1/link/token", body: EmptyBody(), authed: true)
    }

    func completeLink(institutionID: String) async throws -> LinkedItem {
        try await post("/v1/link/complete", body: CompleteInstitutionBody(institutionID: institutionID), authed: true)
    }

    func unlink(institutionID: String) async throws {
        var request = URLRequest(url: baseURL.appending(path: "/v1/link/\(institutionID)"))
        request.httpMethod = "DELETE"
        request.timeoutInterval = 8
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw BankLinkError(errorDescription: "Couldn’t unlink that bank.")
        }
    }

    func deleteAccount() async throws {
        var request = URLRequest(url: baseURL.appending(path: "/v1/me"))
        request.httpMethod = "DELETE"
        request.timeoutInterval = 8
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        _ = try await URLSession.shared.data(for: request)
    }

    private func get<Response: Decodable>(_ path: String) async throws -> Response {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.timeoutInterval = 8
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw BankLinkError(errorDescription: "Couldn’t load linked accounts.")
        }
        return try JSONDecoder.api.decode(Response.self, from: data)
    }

    private func post<Response: Decodable>(_ path: String, body: some Encodable, authed: Bool) async throws -> Response {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 8
        if authed, let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if body is EmptyBody {
            request.httpBody = Data("{}".utf8)
        } else {
            request.httpBody = try JSONEncoder.api.encode(body)
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            if let payload = try? JSONDecoder().decode(APIErrorBody.self, from: data) {
                throw BankLinkError(errorDescription: payload.error)
            }
            throw BankLinkError(errorDescription: "Couldn’t reach Zakat.")
        }
        return try JSONDecoder.api.decode(Response.self, from: data)
    }
}

private struct APIErrorBody: Decodable {
    var error: String
}

private struct EmptyBody: Encodable {}
private struct RegisterBody: Encodable {
    var fullName: String
    var email: String
    var password: String
}
private struct LoginBody: Encodable {
    var email: String
    var password: String
}
private struct CompleteInstitutionBody: Encodable {
    var institutionID: String
}
