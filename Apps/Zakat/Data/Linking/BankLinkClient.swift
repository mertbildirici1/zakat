import Foundation
import ZakatEngine

protocol BankLinkClient: Sendable {
    func createLinkToken() async throws -> LinkSession
    func completeLink(publicToken: String, institutionID: String?) async throws -> LinkedItem
}

struct LinkSession: Codable, Sendable {
    var linkToken: String
    var mode: String
    var institutions: [SandboxInstitution]
}

struct SandboxInstitution: Codable, Identifiable, Sendable {
    var id: String
    var name: String
    var detail: String
}

struct LinkedItem: Codable, Sendable {
    var itemID: String
    var institutionName: String
    var accounts: [LinkedAccount]
}

struct BankLinkError: LocalizedError {
    var errorDescription: String?
}

struct LiveBankLinkClient: BankLinkClient {
    var baseURL: URL

    func createLinkToken() async throws -> LinkSession {
        try await post("/link/token", body: EmptyBody())
    }

    func completeLink(publicToken: String, institutionID: String?) async throws -> LinkedItem {
        try await post(
            "/link/complete",
            body: CompleteLinkRequest(publicToken: publicToken, institutionID: institutionID)
        )
    }

    private func post<Body: Encodable, Response: Decodable>(_ path: String, body: Body) async throws -> Response {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 8
        request.httpBody = try JSONEncoder.api.encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw BankLinkError(errorDescription: "Could not reach the linking service. Start the local backend or try manual entry.")
        }
        return try JSONDecoder.api.decode(Response.self, from: data)
    }
}

struct OfflineSandboxBankLinkClient: BankLinkClient {
    func createLinkToken() async throws -> LinkSession {
        LinkSession(
            linkToken: "offline-sandbox",
            mode: "sandbox",
            institutions: SandboxCatalog.institutions
        )
    }

    func completeLink(publicToken: String, institutionID: String?) async throws -> LinkedItem {
        SandboxCatalog.item(for: institutionID ?? "chase")
    }
}

private struct EmptyBody: Encodable {}
private struct CompleteLinkRequest: Encodable {
    var publicToken: String
    var institutionID: String?

    enum CodingKeys: String, CodingKey {
        case publicToken = "public_token"
        case institutionID = "institution_id"
    }
}

extension JSONEncoder {
    static let api: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
}

extension JSONDecoder {
    static let api: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
}

enum SandboxCatalog {
    static let institutions = [
        SandboxInstitution(id: "chase", name: "Chase", detail: "Checking, savings, and a credit card"),
        SandboxInstitution(id: "fidelity", name: "Fidelity", detail: "Brokerage and 401(k)"),
        SandboxInstitution(id: "coinbase", name: "Coinbase", detail: "Crypto wallet"),
    ]

    static func item(for id: String) -> LinkedItem {
        switch id {
        case "fidelity":
            LinkedItem(
                itemID: "item-fidelity",
                institutionName: "Fidelity",
                accounts: [
                    LinkedAccount(id: "fid-brokerage", institutionName: "Fidelity", name: "Brokerage", mask: "8821", type: .brokerage, currentBalance: 33_100),
                    LinkedAccount(id: "fid-401k", institutionName: "Fidelity", name: "401(k)", mask: "1044", type: .retirement, currentBalance: 88_000),
                ]
            )
        case "coinbase":
            LinkedItem(
                itemID: "item-coinbase",
                institutionName: "Coinbase",
                accounts: [
                    LinkedAccount(id: "cb-btc", institutionName: "Coinbase", name: "Bitcoin", type: .crypto, currentBalance: 2_140),
                ]
            )
        default:
            LinkedItem(
                itemID: "item-chase",
                institutionName: "Chase",
                accounts: [
                    LinkedAccount(id: "ch-checking", institutionName: "Chase", name: "Total Checking", mask: "1234", type: .checking, currentBalance: 4_250),
                    LinkedAccount(id: "ch-savings", institutionName: "Chase", name: "Savings", mask: "9876", type: .savings, currentBalance: 12_800),
                    LinkedAccount(id: "ch-card", institutionName: "Chase", name: "Freedom", mask: "4411", type: .credit, currentBalance: -1_240),
                ]
            )
        }
    }
}
