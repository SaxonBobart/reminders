#if DEBUG
import Foundation
import SQLiteData

/// A bundle of repositories wired to an in-memory database, for use in tests.
/// Isolates SQLiteData types from the test target so tests only depend on the
/// Reminders module (via `@testable import Reminders`).
nonisolated struct TestEnvironment: Sendable {
    let listGroups: ListGroupRepository
    let lists: ReminderListRepository
    let sections: ListSectionRepository
    let reminders: ReminderRepository
    let tags: TagRepository
    let smartLists: SmartListRepository
}

nonisolated enum TestSupport {
    /// Build a fresh in-memory database, run all migrations, seed built-in smart
    /// lists (but no sample data), and return repositories wired to it.
    static func makeEnvironment() throws -> TestEnvironment {
        var configuration = Configuration()
        configuration.foreignKeysEnabled = true
        let database = try DatabaseQueue(configuration: configuration)

        var migrator = DatabaseMigrator()
        registerMigrations(in: &migrator)
        try migrator.migrate(database)

        try database.write { db in
            try seedBuiltinSmartListsIfNeeded(db)
        }

        return TestEnvironment(
            listGroups: ListGroupRepository(database: database),
            lists: ReminderListRepository(database: database),
            sections: ListSectionRepository(database: database),
            reminders: ReminderRepository(database: database),
            tags: TagRepository(database: database),
            smartLists: SmartListRepository(database: database)
        )
    }
}
#endif
