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
    var transactions: [BankTransaction]?

    enum CodingKeys: String, CodingKey {
        case itemID = "itemId"
        case institutionName
        case accounts
        case transactions
    }
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
            throw BankLinkError(errorDescription: "Couldn’t reach the linking service.")
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
        decoder.dateDecodingStrategy = .custom { decoder in
            let raw = try decoder.singleValueContainer().decode(String.self)
            let fractional = ISO8601DateFormatter()
            fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = fractional.date(from: raw) { return date }
            let basic = ISO8601DateFormatter()
            basic.formatOptions = [.withInternetDateTime]
            if let date = basic.date(from: raw) { return date }
            let day = DateFormatter()
            day.calendar = Calendar(identifier: .gregorian)
            day.locale = Locale(identifier: "en_US_POSIX")
            day.timeZone = TimeZone(secondsFromGMT: 0)
            day.dateFormat = "yyyy-MM-dd"
            if let date = day.date(from: raw) { return date }
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Bad date \(raw)"))
        }
        return decoder
    }()
}

enum SandboxCatalog {
    static let institutions = [
        SandboxInstitution(id: "chase", name: "Chase", detail: "Checking, savings, card"),
        SandboxInstitution(id: "fidelity", name: "Fidelity", detail: "Brokerage and 401(k)"),
        SandboxInstitution(id: "coinbase", name: "Coinbase", detail: "Crypto"),
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
                ],
                transactions: transactions(for: "fidelity")
            )
        case "coinbase":
            LinkedItem(
                itemID: "item-coinbase",
                institutionName: "Coinbase",
                accounts: [
                    LinkedAccount(id: "cb-btc", institutionName: "Coinbase", name: "Bitcoin", type: .crypto, currentBalance: 2_140),
                ],
                transactions: transactions(for: "coinbase")
            )
        default:
            LinkedItem(
                itemID: "item-chase",
                institutionName: "Chase",
                accounts: [
                    LinkedAccount(id: "ch-checking", institutionName: "Chase", name: "Total Checking", mask: "1234", type: .checking, currentBalance: 4_250),
                    LinkedAccount(id: "ch-savings", institutionName: "Chase", name: "Savings", mask: "9876", type: .savings, currentBalance: 12_800),
                    LinkedAccount(id: "ch-card", institutionName: "Chase", name: "Freedom", mask: "4411", type: .credit, currentBalance: -1_240),
                ],
                transactions: transactions(for: "chase")
            )
        }
    }

    static func transactions(for institutionID: String) -> [BankTransaction] {
        let calendar = Calendar(identifier: .gregorian)
        let end = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -354, to: end) ?? end
        func day(_ offset: Int) -> Date {
            calendar.date(byAdding: .day, value: offset, to: start) ?? start
        }

        var rows: [BankTransaction] = []
        if institutionID == "chase" {
            for offset in stride(from: 0, through: 354, by: 14) {
                rows.append(BankTransaction(id: "pay-\(offset)", accountID: "ch-checking", date: day(offset), name: "Payroll", amount: 3180, kind: .income))
            }
            for month in 0..<12 {
                let offset = 8 + month * 30
                rows.append(BankTransaction(id: "rent-\(month)", accountID: "ch-checking", date: day(offset), name: "Rent", amount: -1850, kind: .spending))
                rows.append(BankTransaction(id: "util-\(month)", accountID: "ch-checking", date: day(offset), name: "Utilities", amount: -140, kind: .spending))
                rows.append(BankTransaction(id: "save-\(month)", accountID: "ch-checking", date: day(offset), name: "Transfer to savings", amount: -400, kind: .transfer))
                rows.append(BankTransaction(id: "save-in-\(month)", accountID: "ch-savings", date: day(offset), name: "Transfer from checking", amount: 400, kind: .transfer))
            }
            for week in 0..<50 {
                let offset = 3 + week * 7
                rows.append(BankTransaction(id: "groc-\(week)", accountID: "ch-checking", date: day(offset), name: "Groceries", amount: Decimal(-92 - (week % 5) * 4), kind: .spending))
            }
        } else if institutionID == "fidelity" {
            for month in 0..<12 {
                let offset = 4 + month * 30
                rows.append(BankTransaction(id: "401k-\(month)", accountID: "fid-401k", date: day(offset), name: "401(k) contribution", amount: 500, kind: .investment))
                rows.append(BankTransaction(id: "broker-\(month)", accountID: "fid-brokerage", date: day(offset), name: "Brokerage deposit", amount: 300, kind: .investment))
            }
            for quarter in 0..<4 {
                rows.append(BankTransaction(id: "div-\(quarter)", accountID: "fid-brokerage", date: day(40 + quarter * 90), name: "Dividend", amount: 165, kind: .income))
            }
        } else if institutionID == "coinbase" {
            rows.append(BankTransaction(id: "cb-buy-1", accountID: "cb-btc", date: day(40), name: "Buy Bitcoin", amount: 400, kind: .investment))
            rows.append(BankTransaction(id: "cb-buy-2", accountID: "cb-btc", date: day(180), name: "Buy Bitcoin", amount: 250, kind: .investment))
        }
        return rows.filter { $0.date >= start && $0.date <= end }
    }
}
