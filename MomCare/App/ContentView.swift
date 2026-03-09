import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "heart.text.clipboard") {
                Text("Mission Control")
            }

            Tab("Feeding", systemImage: "drop.fill") {
                Text("Feeding")
            }

            Tab("Self-Care", systemImage: "sparkles") {
                Text("Self-Care")
            }

            Tab("Insights", systemImage: "chart.xyaxis.line") {
                Text("Insights")
            }
        }
    }
}

#Preview {
    ContentView()
}
