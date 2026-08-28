import SwiftUI
import SwiftData

@main
struct IVDBApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: VehicleSpecification.self)
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var vehicleSpecifications: [VehicleSpecification]

    var body: some View {
        List {
            ForEach(vehicleSpecifications) { specification in
                Text("\(specification.make) \(specification.model)")
            }
            .onDelete(perform: deleteSpecifications)

            Button("Add Honda CR-V") {
                let specification = VehicleSpecification(
                    make: "Honda",
                    model: "CR-V",
                    generation: "4th generation",
                    yearFrom: 2012,
                    yearTo: 2016
                )

                modelContext.insert(specification)
            }
        }
    }
    
    private func deleteSpecifications(at offsets: IndexSet) {
        for offset in offsets {
            let specification = vehicleSpecifications[offset]
            modelContext.delete(specification)
        }
    }
}

#Preview {
    ContentView()
}
