import Foundation
import SQLiteData

nonisolated struct ReminderListRepository: Sendable {
    let database: any DatabaseWriter

    func create(
        title: String,
        groupId: UUID? = nil,
        colorHex: String = ReminderList.defaultColorHex,
        symbolName: String = ReminderList.defaultSymbolName
    ) async throws -> ReminderList {
        try await database.write { db in
            let position = try Self.nextPosition(groupId: groupId, db: db)
            let id = try ReminderList.insert {
                ReminderList.Draft(
                    groupId: groupId,
                    title: title,
                    colorHex: colorHex,
                    symbolName: symbolName,
                    position: position
                )
            }
            .returning(\.id)
            .fetchOne(db)!
            return try ReminderList.find(id).fetchOne(db)!
        }
    }

    func update(_ list: ReminderList) async throws {
        try await database.write { db in
            try ReminderList
                .find(list.id)
                .update { row in
                    row.title = #bind(list.title)
                    row.colorHex = #bind(list.colorHex)
                    row.symbolName = #bind(list.symbolName)
                    row.groupId = #bind(list.groupId)
                    row.position = #bind(list.position)
                    row.updatedAt = #bind(Date())
                }
                .execute(db)
        }
    }

    /// Soft-delete: sets `deletedAt`, preserves the row.
    func softDelete(id: UUID) async throws {
        try await database.write { db in
            try ReminderList
                .find(id)
                .update { $0.deletedAt = #bind(Date()); $0.updatedAt = #bind(Date()) }
                .execute(db)
        }
    }

    func fetchActive() async throws -> [ReminderList] {
        try await database.read { db in
            try ReminderList
                .where { $0.deletedAt.is(nil) }
                .order(by: \.position)
                .fetchAll(db)
        }
    }

    func fetchById(_ id: UUID) async throws -> ReminderList? {
        try await database.read { db in
            try ReminderList.find(id).fetchOne(db)
        }
    }

    // MARK: - Private

    private static func nextPosition(groupId: UUID?, db: Database) throws -> Int {
        let current = try ReminderList
            .where { $0.groupId.is(groupId) }
            .select { $0.position.max() }
            .fetchOne(db) ?? nil
        return (current ?? -1) + 1
    }
}
