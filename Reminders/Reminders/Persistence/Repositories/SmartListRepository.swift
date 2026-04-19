import Foundation
import SQLiteData

nonisolated struct SmartListRepository: Sendable {
    let database: any DatabaseWriter

    func fetchBuiltins() async throws -> [SmartList] {
        try await database.read { db in
            try SmartList
                .where { $0.kind.eq(SmartList.Kind.builtin) }
                .order(by: \.position)
                .fetchAll(db)
        }
    }

    func fetchUserDefined() async throws -> [SmartList] {
        try await database.read { db in
            try SmartList
                .where { $0.kind.eq(SmartList.Kind.user) }
                .order(by: \.position)
                .fetchAll(db)
        }
    }

    func fetchAll() async throws -> [SmartList] {
        try await database.read { db in
            try SmartList.order(by: \.position).fetchAll(db)
        }
    }
}
