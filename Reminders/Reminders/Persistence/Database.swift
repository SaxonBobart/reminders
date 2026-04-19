import Foundation
import SQLiteData

/// Opens the app's database, runs migrations, and seeds built-in smart lists
/// (plus sample data in DEBUG on first launch). Returns a `DatabaseWriter` to
/// be wired into `Dependencies.defaultDatabase`.
nonisolated func appDatabase() throws -> any DatabaseWriter {
    var configuration = Configuration()
    configuration.foreignKeysEnabled = true

    let database = try defaultDatabase(configuration: configuration)

    var migrator = DatabaseMigrator()
    #if DEBUG
    migrator.eraseDatabaseOnSchemaChange = true
    #endif
    registerMigrations(in: &migrator)
    try migrator.migrate(database)

    try database.write { db in
        try seedBuiltinSmartListsIfNeeded(db)
    }

    #if DEBUG
    try database.seedSampleDataIfEmpty()
    #endif

    return database
}
