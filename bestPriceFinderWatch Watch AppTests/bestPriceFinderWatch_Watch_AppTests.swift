import Testing
import Foundation
@testable import bestPriceFinderWatch_Watch_App

@Suite struct PriceServiceTests {

    func makeSlots(prices: [Double], startingAt base: Date = Date()) -> [PriceSlot] {
        prices.enumerated().map { i, price in
            PriceSlot(date: base.addingTimeInterval(Double(i) * 15 * 60), pricePerKWh: price)
        }
    }

    @Test func computeCostMatchesManualCalculation() {
        // profile = [0.5, 0.5], prices at slot 0 = 0.2, slot 1 = 0.4
        // cost = 0.5 * 0.2 + 0.5 * 0.4 = 0.30
        let slots = makeSlots(prices: [0.2, 0.4])
        let profile = [0.5, 0.5]
        let service = PriceService()
        let result = service.computeCost(startIndex: 0, slots: slots, profile: profile)
        #expect(abs(result - 0.30) < 0.0001)
    }

    @Test func findBestStartPicksLowestCost() {
        // prices: [0.3, 0.1, 0.05, 0.3, 0.3], profile: [1.0, 1.0]
        // costs: index0=0.40, index1=0.15, index2=0.35, index3=0.60 → best is index 1 with €0.15
        let slots = makeSlots(prices: [0.3, 0.1, 0.05, 0.3, 0.3])
        let profile = [1.0, 1.0]
        let service = PriceService()
        let recommendation = service.findBestStart(in: slots, profile: profile, window: nil)
        #expect(recommendation != nil)
        #expect(abs(recommendation!.estimatedCost - 0.15) < 0.0001)
    }

    @Test func daytimeWindowFiltersCorrectly() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 0; components.minute = 0; components.second = 0
        let midnight = calendar.date(from: components)!

        // Slots at 09:00, 11:00, 13:00, 17:00
        let times = [9, 11, 13, 17].map { h in
            midnight.addingTimeInterval(Double(h) * 3600)
        }
        let slots = times.map { PriceSlot(date: $0, pricePerKWh: 0.2) }

        let service = PriceService()
        let result = service.findBestStart(in: slots, profile: [1.0], window: 10...15)
        #expect(result != nil)
        let hour = calendar.component(.hour, from: result!.startTime)
        #expect(hour >= 10 && hour < 16)
    }

    @Test func returnsNilWhenProfileExceedsAvailableSlots() {
        let slots = makeSlots(prices: [0.2, 0.3])
        let profile = [1.0, 1.0, 1.0]
        let service = PriceService()
        let result = service.findBestStart(in: slots, profile: profile, window: nil)
        #expect(result == nil)
    }
}
