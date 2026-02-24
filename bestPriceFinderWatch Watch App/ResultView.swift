import SwiftUI

struct ResultView: View {
    let cycle: CycleProfile
    @State private var state: LoadState = .loading

    private let service = PriceService()

    var body: some View {
        switch state {
        case .loading:
            ProgressView()
                .task { await load() }
        case .loaded(let result):
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    RecommendationSection(
                        label: "☀️ Daytime (10–16h)",
                        recommendation: result.daytime
                    )
                    Divider()
                    RecommendationSection(
                        label: "⚡ Best overall",
                        recommendation: result.overall
                    )
                }
                .padding(.horizontal)
            }
            .navigationTitle(cycle.rawValue)
            .navigationBarTitleDisplayMode(.inline)
        case .error(let message):
            VStack(spacing: 8) {
                Text(message).font(.footnote).multilineTextAlignment(.center)
                Button("Retry") { state = .loading }
            }
            .padding()
        }
    }

    private func load() async {
        do {
            let result = try await service.fetchRecommendations(for: cycle)
            state = .loaded(result)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}

// MARK: - Supporting views

private struct RecommendationSection: View {
    let label: String
    let recommendation: StartRecommendation?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.footnote).foregroundStyle(.secondary)
            if let rec = recommendation {
                Text(rec.formattedTime).font(.title3.bold())
                Text(rec.delayFromNow).font(.footnote)
                Text(rec.formattedCost).font(.footnote).foregroundStyle(.secondary)
            } else {
                Text("Not available").font(.footnote).foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - State

private enum LoadState {
    case loading
    case loaded(CycleResult)
    case error(String)
}

#Preview {
    NavigationStack {
        ResultView(cycle: .dishwasherEco)
    }
}
