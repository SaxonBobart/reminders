import Foundation
import SQLiteData

nonisolated struct TagRepository: Sendable {
    let database: any DatabaseWriter

    /// Find an existing tag by case-insensitive name, or create it.
    /// The `tags.name` column is `COLLATE NOCASE`, so `eq` is case-insensitive.
    func findOrCreate(name: String) async throws -> Tag {
        try await database.write { db in
            let tagName = name
            let existingQuery = Tag.where { $0.name.eq(tagName) }
            if let existing = try existingQuery.fetchOne(db) {
                return existing
            }
            let insertQuery = Tag.insert { Tag.Draft(name: tagName) }.returning(\.id)
            let id = try insertQuery.fetchOne(db)!
            return try Tag.find(id).fetchOne(db)!
        }
    }

    func delete(id: UUID) async throws {
        try await database.write { db in
            try Tag.find(id).delete().execute(db)
        }
    }

    func fetchAll() async throws -> [Tag] {
        try await database.read { db in
            try Tag.order(by: \.name).fetchAll(db)
        }
    }

    func attach(reminderId: UUID, tagId: UUID) async throws {
        try await database.write { db in
            try ReminderTag.insert {
                ReminderTag.Draft(reminderId: reminderId, tagId: tagId)
            }
            .execute(db)
        }
    }

    func detach(reminderId: UUID, tagId: UUID) async throws {
        try await database.write { db in
            try ReminderTag
                .where { rt in rt.reminderId.eq(reminderId) && rt.tagId.eq(tagId) }
                .delete()
                .execute(db)
        }
    }

    func tags(forReminder reminderId: UUID) async throws -> [Tag] {
        try await database.read { db in
            try Tag
                .join(ReminderTag.all) { $0.id.eq($1.tagId) }
                .where { _, rt in rt.reminderId.eq(reminderId) }
                .select { tag, _ in tag }
                .fetchAll(db)
        }
    }
}
