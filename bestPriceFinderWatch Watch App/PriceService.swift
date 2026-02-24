import Foundation

class PriceService {

    // MARK: - Testable pure functions

    func computeCost(startIndex: Int, slots: [PriceSlot], profile: [Double]) -> Double {
        var total = 0.0
        for (offset, kWh) in profile.enumerated() {
            total += kWh * slots[startIndex + offset].pricePerKWh
        }
        return total
    }

    func findBestStart(in slots: [PriceSlot], profile: [Double], window: ClosedRange<Int>?) -> StartRecommendation? {
        let maxStart = slots.count - profile.count
        guard maxStart >= 0 else { return nil }

        let calendar = Calendar.current
        var bestCost = Double.infinity
        var bestSlot: PriceSlot?

        for i in 0...maxStart {
            let slot = slots[i]
            if let window {
                let hour = calendar.component(.hour, from: slot.date)
                guard window.contains(hour) else { continue }
            }
            let cost = computeCost(startIndex: i, slots: slots, profile: profile)
            if cost < bestCost {
                bestCost = cost
                bestSlot = slot
            }
        }

        guard let slot = bestSlot else { return nil }
        return StartRecommendation(startTime: slot.date, estimatedCost: bestCost)
    }

    // MARK: - Network

    private let baseURL = "https://enever.nl/apiv3/"
    private let token = Secrets.eneverAPIToken

    func fetchRecommendations(for cycle: CycleProfile) async throws -> CycleResult {
        let now = Date()
        var slots = try await fetchSlots(endpoint: "stroomprijs_vandaag.php")

        let hour = Calendar.current.component(.hour, from: now)
        if hour >= 14 {
            let tomorrow = (try? await fetchSlots(endpoint: "stroomprijs_morgen.php")) ?? []
            slots += tomorrow
        }

        slots = slots.filter { $0.date > now }

        let profile = cycle.kwhProfile
        let overall = findBestStart(in: slots, profile: profile, window: nil)
        guard let overall else {
            throw AppError.noPricesAvailable
        }

        let daytime = findBestStart(in: slots, profile: profile, window: 10...15)
        return CycleResult(daytime: daytime, overall: overall)
    }

    private func fetchSlots(endpoint: String) async throws -> [PriceSlot] {
        var components = URLComponents(string: baseURL + endpoint)!
        components.queryItems = [
            URLQueryItem(name: "token", value: token),
            URLQueryItem(name: "resolution", value: "15"),
            URLQueryItem(name: "price", value: "prijsTI")
        ]
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        let response = try JSONDecoder().decode(APIResponse.self, from: data)
        return response.data.compactMap { entry -> PriceSlot? in
            guard let price = Double(entry.prijsTI) else { return nil }
            return PriceSlot(date: entry.parsedDate, pricePerKWh: price)
        }
    }
}

// MARK: - API Response Types

private struct APIResponse: Decodable {
    let data: [APIEntry]
}

private struct APIEntry: Decodable {
    let datum: String
    let prijsTI: String

    var parsedDate: Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withColonSeparatorInTimeZone]
        return formatter.date(from: datum) ?? Date.distantPast
    }
}

// MARK: - Errors

enum AppError: LocalizedError {
    case noPricesAvailable

    var errorDescription: String? {
        switch self {
        case .noPricesAvailable: return "No price data available"
        }
    }
}
