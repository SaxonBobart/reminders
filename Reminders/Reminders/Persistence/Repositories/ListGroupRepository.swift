import Foundation
import SQLiteData

nonisolated struct ListGroupRepository: Sendable {
    let database: any DatabaseWriter

    func create(title: String) async throws -> ListGroup {
        try await database.write { db in
            let position = try ListGroup
                .select { $0.position.max() }
                .fetchOne(db) ?? nil
            let id = try ListGroup.insert {
                ListGroup.Draft(title: title, position: (position ?? -1) + 1)
            }
            .returning(\.id)
            .fetchOne(db)!
            return try ListGroup.find(id).fetchOne(db)!
        }
    }

    func rename(id: UUID, to title: String) async throws {
        try await database.write { db in
            try ListGroup
                .find(id)
                .update { $0.title = #bind(title); $0.updatedAt = #bind(Date()) }
                .execute(db)
        }
    }

    func delete(id: UUID) async throws {
        try await database.write { db in
            try ListGroup.find(id).delete().execute(db)
        }
    }

    func fetchActive() async throws -> [ListGroup] {
        try await database.read { db in
            try ListGroup
                .where { $0.deletedAt.is(nil) }
                .order(by: \.position)
                .fetchAll(db)
        }
    }
}
