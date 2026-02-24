import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List(CycleProfile.allCases) { cycle in
                NavigationLink(cycle.rawValue, value: cycle)
            }
            .navigationTitle("Best Price")
            .navigationDestination(for: CycleProfile.self) { cycle in
                ResultView(cycle: cycle)
            }
        }
    }
}

#Preview {
    ContentView()
}
