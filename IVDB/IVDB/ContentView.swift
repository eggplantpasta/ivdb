import SwiftUI
import SwiftData

@main
struct IVDBApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Vehicle.self,
            ServiceScheduleOverride.self,
            ServiceHistory.self
        ])
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var vehicles: [Vehicle]

    var body: some View {
        List {

            Section("My Vehicles") {
                ForEach(vehicles) { vehicle in
                    Text(vehicle.name)
                }
            }

            Button("Add My CR-V") {
                addVehicle()
            }
        }
    }
    
    private func addVehicle() {
        let vehicle = Vehicle(
            name: "My CR-V",
            registration: "1ABC234",
            colour: "Silver",
            buildYear: 2012
        )

        modelContext.insert(vehicle)
    }
}

#Preview {
    ContentView()
}
