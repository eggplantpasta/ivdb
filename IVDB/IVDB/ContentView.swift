import SwiftUI
import SwiftData

@main
struct IVDBApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            VehicleSpecification.self,
            Vehicle.self,
            ServiceItem.self,
            ServiceSchedule.self,
            ServiceScheduleOverride.self,
            ServiceHistory.self
        ])
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var vehicleSpecifications: [VehicleSpecification]
    @Query private var vehicles: [Vehicle]

    var body: some View {
        List {
            Section("Vehicle Specifications") {
                ForEach(vehicleSpecifications) { specification in
                    Text("\(specification.make) \(specification.model)")
                }
            }

            Section("My Vehicles") {
                ForEach(vehicles) { vehicle in
                    VStack(alignment: .leading) {
                        Text(vehicle.name)

                        if let specificationId = vehicle.vehicleSpecificationId,
                           let specification = vehicleSpecifications.first(where: { $0.id == specificationId }) {
                            Text("\(specification.make) \(specification.model)")
                                .font(.caption)
                        }
                    }
                }
            }

            Button("Add My CR-V") {
                addVehicle()
            }
        }
    }
    
    private func addVehicle() {
        guard let crvSpecification = vehicleSpecifications.first else {
            return
        }

        let vehicle = Vehicle(
            vehicleSpecificationId: crvSpecification.id,
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
