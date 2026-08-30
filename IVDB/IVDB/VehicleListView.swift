import SwiftUI
import SwiftData

struct VehicleListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var vehicles: [Vehicle]
    @Binding var selection: Vehicle?

    var body: some View {
        Group {
            if vehicles.isEmpty {
                ContentUnavailableView(
                    "No Vehicles",
                    systemImage: "car",
                    description: Text(
                        "Add a vehicle to start recording its service history."
                    )
                )
            } else {
                List(selection: $selection) {
                    Section("My Vehicles") {
                        ForEach(vehicles) { vehicle in
                            NavigationLink(value: vehicle) {
                                Text(vehicle.name)
                            }
                        }
                    }
                }
            }
        }
        .toolbar {
            Button(action: addVehicle) {
                Label("Add My CR-V", systemImage: "plus")
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
    VehicleListView(selection: .constant(nil))
        .modelContainer(for: Vehicle.self, inMemory: true)
}
