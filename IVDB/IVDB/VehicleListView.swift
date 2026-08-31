import SwiftUI
import SwiftData

struct VehicleListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var vehicles: [Vehicle]
    @Binding var selection: Vehicle?
    @State private var isShowingSettings = false
    @State private var isShowingAddVehicle = false

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
            #if os(iOS)
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isShowingSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            }
            #endif

            ToolbarItem(placement: .primaryAction) {
                Button {
                    isShowingAddVehicle = true
                } label: {
                    Image(systemName: "plus")
                        .accessibilityLabel("Add Vehicle")
                }
                .help("Add Vehicle")
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $isShowingAddVehicle) {
            AddVehicleView()
        }
    }
}

#Preview {
    VehicleListView(selection: .constant(nil))
        .modelContainer(for: Vehicle.self, inMemory: true)
}
