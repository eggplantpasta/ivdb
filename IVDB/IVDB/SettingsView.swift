//
//  SettingsView.swift
//  IVDB
//
//  Created by Brett Roper on 31/8/2026.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    private var appVersion: String {
        Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "Unknown"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("About") {
                    LabeledContent("Application", value: "IVDB")
                    LabeledContent("Version", value: appVersion)

                    Link(
                        "View source code",
                        destination: URL(
                            string: "https://github.com/eggplantpasta/ivdb"
                        )!
                    )
                }

                Section("Data") {
                    Text(
                        """
                        Vehicle and service records are stored locally \
                        using SwiftData. The vehicle catalogue is supplied \
                        with the application as a read-only database.
                        """
                    )
                }

                Section("License") {
                    Text(
                        "IVDB is open-source software released under the MIT License."
                    )
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                #if !os(macOS)
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #endif
            }
        }
    }
}

#Preview {
    SettingsView()
}
