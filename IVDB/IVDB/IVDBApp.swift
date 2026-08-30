//
//  IVDBApp.swift
//  IVDB
//
//  Created by Brett Roper on 30/8/2026.
//

import SwiftUI
import SwiftData

@main
struct IVDBApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [
            Vehicle.self,
            ServiceScheduleOverride.self,
            ServiceHistory.self
        ])
    }
}
