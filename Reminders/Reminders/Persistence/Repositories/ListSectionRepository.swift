import Foundation
import SQLiteData

nonisolated struct ListSectionRepository: Sendable {
    let database: any DatabaseWriter

    func create(listId: UUID, title: String) async throws -> ListSection {
        try await database.write { db in
            let position = try ListSection
                .where { $0.listId.eq(listId) }
                .select { $0.position.max() }
                .fetchOne(db) ?? nil
            let id = try ListSection.insert {
                ListSection.Draft(listId: listId, title: title, position: (position ?? -1) + 1)
            }
            .returning(\.id)
            .fetchOne(db)!
            return try ListSection.find(id).fetchOne(db)!
        }
    }

    func softDelete(id: UUID) async throws {
        try await database.write { db in
            try ListSection
                .find(id)
                .update { $0.deletedAt = #bind(Date()); $0.updatedAt = #bind(Date()) }
                .execute(db)
        }
    }

    func fetchByList(_ listId: UUID) async throws -> [ListSection] {
        try await database.read { db in
            try ListSection
                .where { $0.listId.eq(listId) && $0.deletedAt.is(nil) }
                .order(by: \.position)
                .fetchAll(db)
        }
    }
}
