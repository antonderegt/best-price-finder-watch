import Foundation

// MARK: - Cycle Profiles

enum CycleProfile: String, CaseIterable, Identifiable {
    case dishwasherEco      = "Dishwasher — Eco"
    case dishwasherHot      = "Dishwasher — Hot"
    case washingKreukvrij   = "Washing — Kreukvrij"
    case washingHeet        = "Washing — Heet"
    case washingFijn        = "Washing — Fijn"
    case washingDonker      = "Washing — Donker"

    var id: String { rawValue }

    var kwhProfile: [Double] {
        switch self {
        case .dishwasherEco:
            return [0.006, 0.302, 0.061, 0.022, 0.022, 0.022, 0.019, 0.133, 0.095]
        case .dishwasherHot:
            return [0.059, 0.185, 0.326, 0.215, 0.022, 0.021, 0.020, 0.043, 0.375, 0.084]
        case .washingKreukvrij:
            return [0.051, 0.471, 0.128, 0.041, 0.041, 0.041, 0.047, 0.019, 0.038]
        case .washingHeet:
            return [0.448, 0.562, 0.188, 0.103, 0.060, 0.019, 0.023, 0.024, 0.012, 0.041]
        case .washingFijn:
            return [0.220, 0.036, 0.018, 0.019, 0.021]
        case .washingDonker:
            return [0.255, 0.044, 0.013, 0.011, 0.011, 0.018, 0.010, 0.039]
        }
    }
}

// MARK: - Price Data

struct PriceSlot {
    let date: Date
    let pricePerKWh: Double
}

// MARK: - Results

struct StartRecommendation {
    let startTime: Date
    let estimatedCost: Double

    var delayFromNow: String {
        let seconds = startTime.timeIntervalSinceNow
        guard seconds > 0 else { return "now" }
        let totalMinutes = Int(seconds / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours == 0 { return "in \(minutes)m" }
        if minutes == 0 { return "in \(hours)h" }
        return "in \(hours)h \(minutes)m"
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: startTime)
    }

    var formattedCost: String {
        String(format: "€%.3f", estimatedCost)
    }
}

struct CycleResult {
    let daytime: StartRecommendation?
    let overall: StartRecommendation
}
