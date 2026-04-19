import Foundation
import SQLiteData

nonisolated struct ReminderRepository: Sendable {
    let database: any DatabaseWriter

    // MARK: - Create / update

    func create(
        listId: UUID,
        title: String,
        parentId: UUID? = nil,
        sectionId: UUID? = nil,
        dueDate: Date? = nil,
        hasTimeComponent: Bool = false,
        priority: Reminder.Priority = .none,
        notes: String = "",
        isFlagged: Bool = false
    ) async throws -> Reminder {
        try await database.write { db in
            let position = try Self.nextPosition(listId: listId, sectionId: sectionId, db: db)
            let id = try Reminder.insert {
                Reminder.Draft(
                    listId: listId,
                    sectionId: sectionId,
                    parentId: parentId,
                    title: title,
                    notes: notes,
                    dueDate: dueDate,
                    hasTimeComponent: hasTimeComponent,
                    priority: priority,
                    isFlagged: isFlagged,
                    position: position
                )
            }
            .returning(\.id)
            .fetchOne(db)!
            return try Reminder.find(id).fetchOne(db)!
        }
    }

    func update(_ reminder: Reminder) async throws {
        try await database.write { db in
            try Reminder
                .find(reminder.id)
                .update { row in
                    row.title = #bind(reminder.title)
                    row.notes = #bind(reminder.notes)
                    row.url = #bind(reminder.url)
                    row.dueDate = #bind(reminder.dueDate)
                    row.hasTimeComponent = #bind(reminder.hasTimeComponent)
                    row.priority = #bind(reminder.priority)
                    row.isFlagged = #bind(reminder.isFlagged)
                    row.sectionId = #bind(reminder.sectionId)
                    row.parentId = #bind(reminder.parentId)
                    row.earlyReminder = #bind(reminder.earlyReminder)
                    row.recurrenceRule = #bind(reminder.recurrenceRule)
                    row.locationLatitude = #bind(reminder.locationLatitude)
                    row.locationLongitude = #bind(reminder.locationLongitude)
                    row.locationRadius = #bind(reminder.locationRadius)
                    row.locationTrigger = #bind(reminder.locationTrigger)
                    row.locationName = #bind(reminder.locationName)
                    row.updatedAt = #bind(Date())
                }
                .execute(db)
        }
    }

    func toggleCompletion(id: UUID) async throws {
        try await database.write { db in
            guard let current = try Reminder.find(id).fetchOne(db) else { return }
            let nowCompleted = !current.isCompleted
            try Reminder
                .find(id)
                .update { row in
                    row.isCompleted = #bind(nowCompleted)
                    row.completedAt = #bind(nowCompleted ? Date() : nil)
                    row.updatedAt = #bind(Date())
                }
                .execute(db)
        }
    }

    func setFlag(id: UUID, flagged: Bool) async throws {
        try await database.write { db in
            try Reminder
                .find(id)
                .update { $0.isFlagged = #bind(flagged); $0.updatedAt = #bind(Date()) }
                .execute(db)
        }
    }

    func setParent(childId: UUID, parentId: UUID?) async throws {
        // The BEFORE UPDATE trigger will RAISE(ABORT) if the new parent is itself a subtask.
        try await database.write { db in
            try Reminder
                .find(childId)
                .update { $0.parentId = #bind(parentId); $0.updatedAt = #bind(Date()) }
                .execute(db)
        }
    }

    func softDelete(id: UUID) async throws {
        try await database.write { db in
            try Reminder
                .find(id)
                .update { $0.deletedAt = #bind(Date()); $0.updatedAt = #bind(Date()) }
                .execute(db)
        }
    }

    // MARK: - Fetches

    func fetchById(_ id: UUID) async throws -> Reminder? {
        try await database.read { db in
            try Reminder.find(id).fetchOne(db)
        }
    }

    func fetchByList(_ listId: UUID, includeCompleted: Bool = true) async throws -> [Reminder] {
        try await database.read { db in
            if includeCompleted {
                return try Reminder
                    .where { r in r.listId.eq(listId) && r.deletedAt.is(nil) }
                    .order(by: \.position)
                    .fetchAll(db)
            } else {
                return try Reminder
                    .where { r in r.listId.eq(listId) && r.deletedAt.is(nil) && !r.isCompleted }
                    .order(by: \.position)
                    .fetchAll(db)
            }
        }
    }

    func fetchSubtasks(of parentId: UUID) async throws -> [Reminder] {
        try await database.read { db in
            try Reminder
                .where { r in r.parentId.is(parentId) && r.deletedAt.is(nil) }
                .order(by: \.position)
                .fetchAll(db)
        }
    }

    func fetchBuiltinSmartList(
        _ slug: SmartList.BuiltinSlug,
        now: Date = Date()
    ) async throws -> [Reminder] {
        try await database.read { db in
            try SmartListQueryCompiler.builtinWhere(slug, now: now).fetchAll(db)
        }
    }

    // MARK: - Private

    private static func nextPosition(listId: UUID, sectionId: UUID?, db: Database) throws -> Int {
        let current = try Reminder
            .where { r in r.listId.eq(listId) && r.sectionId.is(sectionId) }
            .select { $0.position.max() }
            .fetchOne(db) ?? nil
        return (current ?? -1) + 1
    }
}
