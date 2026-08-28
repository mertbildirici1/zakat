import Foundation
import UserNotifications
import ZakatEngine

enum MetalsClient {
    static func fetchQuote(baseURL: URL) async throws -> MetalQuote {
        var request = URLRequest(url: baseURL.appending(path: "/v1/metals"))
        request.timeoutInterval = 8
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder.api.decode(MetalQuote.self, from: data)
    }
}

enum HawlReminder {
    static let identifier = "zakat.hawl.reminder"

    static func sync(enabled: Bool, startDate: Date) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        guard enabled else { return }

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            let due = Hawl.dueDate(from: startDate)
            var components = Calendar.current.dateComponents([.year, .month, .day], from: due)
            components.hour = 9
            components.minute = 0
            let content = UNMutableNotificationContent()
            content.title = "Zakat anniversary"
            content.body = "Your hawl is due. Open Zakat to review."
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            center.add(request)
        }
    }
}
