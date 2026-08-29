//
//  CatalogueDatabase.swift
//  IVDB
//
//  Created by Brett Roper on 29/8/2026.
//

import Foundation
import SQLite3

enum CatalogueDatabaseError: Error {
    case databaseNotFound
    case openFailed(String)
}

final class CatalogueDatabase {
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
    }

    deinit {
        sqlite3_close(connection)
    }
}
