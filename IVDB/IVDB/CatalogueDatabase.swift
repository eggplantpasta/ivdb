//
//  CatalogueDatabase.swift
//  IVDB
//
//  Created by Brett Roper on 29/8/2026.
//

import Foundation
import SQLite3

private let sqliteTransient = unsafeBitCast(
    -1,
    to: sqlite3_destructor_type.self
)

enum CatalogueDatabaseError: Error {
    case databaseNotFound
    case openFailed(String)
    case queryFailed(String)
    case invalidData(String)
    case missingMetadata
    case unsupportedSchemaVersion(found: Int, supported: Int)
}

extension CatalogueDatabaseError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .databaseNotFound:
            return "The vehicle catalogue is missing."

        case .openFailed(let message):
            return "The vehicle catalogue could not be opened: \(message)"

        case .queryFailed(let message):
            return "The vehicle catalogue query failed: \(message)"

        case .invalidData(let message):
            return "The vehicle catalogue contains invalid data: \(message)"

        case .missingMetadata:
            return "The vehicle catalogue has no compatibility information."

        case .unsupportedSchemaVersion(let found, let supported):
            return """
                The vehicle catalogue uses schema version \(found), \
                but this app supports version \(supported).
                """
        }
    }
}

final class CatalogueDatabase {
    private static let supportedSchemaVersion = 1
    
    private var connection: OpaquePointer?

    init(bundle: Bundle = .main) throws {
        guard let databaseURL = bundle.url(
            forResource: "catalogue",
            withExtension: "sqlite"
        ) else {
            throw CatalogueDatabaseError.databaseNotFound
        }

        var database: OpaquePointer?

        let result = sqlite3_open_v2(
            databaseURL.path,
            &database,
            SQLITE_OPEN_READONLY,
            nil
        )

        guard result == SQLITE_OK else {
            let message = database.map {
                String(cString: sqlite3_errmsg($0))
            } ?? "Unknown SQLite error"

            if let database {
                sqlite3_close(database)
            }

            throw CatalogueDatabaseError.openFailed(message)
        }

        connection = database

        do {
            try validateCompatibility()
        } catch {
            sqlite3_close(connection)
            connection = nil
            throw error
        }
    }
    
    private func validateCompatibility() throws {
        let sql = """
            SELECT schema_version
            FROM catalogue_metadata
            WHERE metadata_id = 1
            """

        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(
            connection,
            sql,
            -1,
            &statement,
            nil
        ) == SQLITE_OK else {
            throw CatalogueDatabaseError.missingMetadata
        }

        defer {
            sqlite3_finalize(statement)
        }

        switch sqlite3_step(statement) {
        case SQLITE_ROW:
            let foundVersion = Int(
                sqlite3_column_int64(statement, 0)
            )

            guard foundVersion == Self.supportedSchemaVersion else {
                throw CatalogueDatabaseError.unsupportedSchemaVersion(
                    found: foundVersion,
                    supported: Self.supportedSchemaVersion
                )
            }

        case SQLITE_DONE:
            throw CatalogueDatabaseError.missingMetadata

        default:
            throw CatalogueDatabaseError.queryFailed(
                String(cString: sqlite3_errmsg(connection))
            )
        }
    }

    private func vehicleSpecification(
        from statement: OpaquePointer?
    ) throws -> VehicleSpecification {
        guard
            let idText = sqlite3_column_text(statement, 0),
            let id = UUID(uuidString: String(cString: idText)),
            let makeText = sqlite3_column_text(statement, 1),
            let modelText = sqlite3_column_text(statement, 2)
        else {
            throw CatalogueDatabaseError.invalidData(
                "Invalid vehicle specification row"
            )
        }

        return VehicleSpecification(
            id: id,
            make: String(cString: makeText),
            model: String(cString: modelText),
            generation: optionalText(from: statement, at: 3),
            yearFrom: optionalInt(from: statement, at: 4),
            yearTo: optionalInt(from: statement, at: 5),
            series: optionalText(from: statement, at: 6),
            trim: optionalText(from: statement, at: 7),
            bodyType: optionalText(from: statement, at: 8),
            engine: optionalText(from: statement, at: 9),
            transmission: optionalText(from: statement, at: 10)
        )
    }
    
    func fetchVehicleSpecifications() throws -> [VehicleSpecification] {
        let sql = """
            SELECT
                vehicle_specification_id,
                make,
                model,
                generation,
                year_from,
                year_to,
                series,
                trim,
                body_type,
                engine,
                transmission
            FROM vehicle_specification
            ORDER BY make, model, year_from
            """
        
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(
            connection,
            sql,
            -1,
            &statement,
            nil
        ) == SQLITE_OK else {
            throw CatalogueDatabaseError.queryFailed(
                String(cString: sqlite3_errmsg(connection))
            )
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        
        var specifications: [VehicleSpecification] = []
        
        while true {
            switch sqlite3_step(statement) {
            case SQLITE_ROW:
                specifications.append(
                    try vehicleSpecification(from: statement)
                )
                
            case SQLITE_DONE:
                return specifications
                
            default:
                throw CatalogueDatabaseError.queryFailed(
                    String(cString: sqlite3_errmsg(connection))
                )
            }
        }
    }
    
    func fetchVehicleSpecification(
        id: UUID
    ) throws -> VehicleSpecification? {
        let sql = """
            SELECT
                vehicle_specification_id,
                make,
                model,
                generation,
                year_from,
                year_to,
                series,
                trim,
                body_type,
                engine,
                transmission
            FROM vehicle_specification
            WHERE vehicle_specification_id = ?
            LIMIT 1
            """

        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(
            connection,
            sql,
            -1,
            &statement,
            nil
        ) == SQLITE_OK else {
            throw CatalogueDatabaseError.queryFailed(
                String(cString: sqlite3_errmsg(connection))
            )
        }

        defer {
            sqlite3_finalize(statement)
        }

        guard sqlite3_bind_text(
            statement,
            1,
            id.uuidString.lowercased(),
            -1,
            sqliteTransient
        ) == SQLITE_OK else {
            throw CatalogueDatabaseError.queryFailed(
                String(cString: sqlite3_errmsg(connection))
            )
        }

        switch sqlite3_step(statement) {
        case SQLITE_ROW:
            return try vehicleSpecification(from: statement)

        case SQLITE_DONE:
            return nil

        default:
            throw CatalogueDatabaseError.queryFailed(
                String(cString: sqlite3_errmsg(connection))
            )
        }
    }
    
    private func serviceItem(
        from statement: OpaquePointer?
    ) throws -> ServiceItem {
        guard
            let idText = sqlite3_column_text(statement, 0),
            let id = UUID(uuidString: String(cString: idText)),
            let nameText = sqlite3_column_text(statement, 1)
        else {
            throw CatalogueDatabaseError.invalidData(
                "Invalid service item row"
            )
        }

        return ServiceItem(
            id: id,
            name: String(cString: nameText),
            itemDescription: optionalText(from: statement, at: 2)
        )
    }
    
    func fetchServiceItems() throws -> [ServiceItem] {
        let sql = """
            SELECT service_item_id, name, description
            FROM service_item
            ORDER BY name
            """

        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(
            connection,
            sql,
            -1,
            &statement,
            nil
        ) == SQLITE_OK else {
            throw CatalogueDatabaseError.queryFailed(
                String(cString: sqlite3_errmsg(connection))
            )
        }

        defer {
            sqlite3_finalize(statement)
        }

        var serviceItems: [ServiceItem] = []

        while true {
            switch sqlite3_step(statement) {
            case SQLITE_ROW:
                serviceItems.append(
                    try serviceItem(from: statement)
                )

            case SQLITE_DONE:
                return serviceItems

            default:
                throw CatalogueDatabaseError.queryFailed(
                    String(cString: sqlite3_errmsg(connection))
                )
            }
        }
    }
    
    func fetchServiceItem(
        id: UUID
    ) throws -> ServiceItem? {
        let sql = """
            SELECT service_item_id, name, description
            FROM service_item
            WHERE service_item_id = ?
            LIMIT 1
            """

        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(
            connection,
            sql,
            -1,
            &statement,
            nil
        ) == SQLITE_OK else {
            throw CatalogueDatabaseError.queryFailed(
                String(cString: sqlite3_errmsg(connection))
            )
        }

        defer {
            sqlite3_finalize(statement)
        }

        guard sqlite3_bind_text(
            statement,
            1,
            id.uuidString.lowercased(),
            -1,
            sqliteTransient
        ) == SQLITE_OK else {
            throw CatalogueDatabaseError.queryFailed(
                String(cString: sqlite3_errmsg(connection))
            )
        }

        switch sqlite3_step(statement) {
        case SQLITE_ROW:
            return try serviceItem(from: statement)

        case SQLITE_DONE:
            return nil

        default:
            throw CatalogueDatabaseError.queryFailed(
                String(cString: sqlite3_errmsg(connection))
            )
        }
    }

    private func optionalText(
        from statement: OpaquePointer?,
        at index: Int32
    ) -> String? {
        guard
            sqlite3_column_type(statement, index) != SQLITE_NULL,
            let text = sqlite3_column_text(statement, index)
        else {
            return nil
        }

        return String(cString: text)
    }

    private func optionalInt(
        from statement: OpaquePointer?,
        at index: Int32
    ) -> Int? {
        guard sqlite3_column_type(statement, index) != SQLITE_NULL else {
            return nil
        }

        return Int(sqlite3_column_int64(statement, index))
    }
    
    deinit {
        sqlite3_close(connection)
    }
}
