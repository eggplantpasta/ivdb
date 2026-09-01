//
//  RootView.swift
//  IVDB
//
//  Created by Brett Roper on 30/8/2026.
//

import SwiftUI


struct RootView: View {
    @State private var selectedVehicle: Vehicle?
    var body: some View {
        NavigationSplitView {
            VehicleListView(selection: $selectedVehicle)
                .navigationTitle("My Vehicles")
        } detail: {
            if let selectedVehicle {
                VehicleDetailView(
                    vehicle: selectedVehicle,
                    selection: $selectedVehicle
                )
            } else {
                ContentUnavailableView(
                    "No Vehicle Selected",
                    systemImage: "car",
                    description: Text(
                        "Select a vehicle to view its details."
                    )
                )
            }
        }
    }
}

#Preview {
    RootView()
}
