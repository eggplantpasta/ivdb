//
//  VehicleSpecificationPickerView.swift
//  IVDB
//
//  Created by Brett Roper on 1/9/2026.
//

import SwiftUI

struct VehicleSpecificationPickerView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var specifications: [VehicleSpecification]
    @Binding var selection: UUID?

    @State private var searchText = ""

    private var filteredSpecifications: [VehicleSpecification] {
        guard !searchText.isEmpty else {
            return specifications
        }

        return specifications.filter { specification in
            [
                specification.make,
                specification.model,
                specification.generation,
                specification.series,
                specification.engine,
                specification.transmission
            ]
            .compactMap { $0 }
            .contains { value in
                value.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        List {
            Button {
                selection = nil
                dismiss()
            } label: {
                selectionRow(
                    title: "Not listed",
                    isSelected: selection == nil
                )
            }

            ForEach(filteredSpecifications) { specification in
                Button {
                    selection = specification.id
                    dismiss()
                } label: {
                    selectionRow(
                        title: specification.displayName,
                        isSelected: selection == specification.id
                    )
                }
            }
        }
        .navigationTitle("Select Specification")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $searchText,
            prompt: "Make, model, engine or series"
        )
    }

    private func selectionRow(
        title: String,
        isSelected: Bool
    ) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.primary)

            Spacer()

            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(.tint)
            }
        }
        .contentShape(Rectangle())
    }
}
