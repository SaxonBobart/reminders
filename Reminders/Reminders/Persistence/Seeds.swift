import Foundation
import SQLiteData

// MARK: - Built-in smart lists

/// Builtin smart lists shipped with every install. Inserted on first launch;
/// idempotent via the unique index on `smartLists.slug`.
nonisolated func seedBuiltinSmartListsIfNeeded(_ db: Database) throws {
    let existing = try SmartList
        .where { $0.kind.eq(SmartList.Kind.builtin) }
        .count()
        .fetchOne(db) ?? 0
    guard existing == 0 else { return }

    for (index, spec) in BuiltinSmartListSpec.all.enumerated() {
        try SmartList.insert {
            SmartList.Draft(
                kind: .builtin,
                slug: spec.slug.rawValue,
                title: spec.title,
                symbolName: spec.symbolName,
                colorHex: spec.colorHex,
                queryJSON: spec.queryJSON,
                position: index
            )
        }
        .execute(db)
    }
}

nonisolated private struct BuiltinSmartListSpec {
    let slug: SmartList.BuiltinSlug
    let title: String
    let symbolName: String
    let colorHex: String
    let queryJSON: String

    static let all: [BuiltinSmartListSpec] = [
        Self(
            slug: .today,
            title: "Today",
            symbolName: "calendar",
            colorHex: "#1E6BFF",
            queryJSON: encode(.and([
                .not(.isCompleted(true)),
                .not(.isDeleted(true)),
                .dueOn(.today),
            ]))
        ),
        Self(
            slug: .scheduled,
            title: "Scheduled",
            symbolName: "calendar.badge.clock",
            colorHex: "#E7453C",
            queryJSON: encode(
                .and([
                    .not(.isCompleted(true)),
                    .not(.isDeleted(true)),
                    .hasDueDate,
                ]),
                sort: [SortClause(field: .dueDate, order: .asc)]
            )
        ),
        Self(
            slug: .all,
            title: "All",
            symbolName: "tray",
            colorHex: "#444444",
            queryJSON: encode(.and([
                .not(.isCompleted(true)),
                .not(.isDeleted(true)),
            ]))
        ),
        Self(
            slug: .flagged,
            title: "Flagged",
            symbolName: "flag",
            colorHex: "#F2AE00",
            queryJSON: encode(.and([
                .isFlagged(true),
                .not(.isDeleted(true)),
            ]))
        ),
        Self(
            slug: .completed,
            title: "Completed",
            symbolName: "checkmark.circle",
            colorHex: "#8E8E93",
            queryJSON: encode(
                .and([
                    .isCompleted(true),
                    .not(.isDeleted(true)),
                ]),
                sort: [SortClause(field: .completedAt, order: .desc)]
            )
        ),
    ]
}

nonisolated private func encode(_ filter: SmartPredicate, sort: [SortClause] = []) -> String {
    let query = SmartQuery(filter: filter, sort: sort)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    return String(decoding: try! encoder.encode(query), as: UTF8.self)
}

// MARK: - DEBUG sample data

#if DEBUG
extension DatabaseWriter {
    /// Inserts a small set of demo lists, reminders, and tags if the user has
    /// no lists yet. Safe to call on every launch.
    nonisolated func seedSampleDataIfEmpty() throws {
        try write { db in
            let userListCount = try ReminderList
                .where { $0.deletedAt.is(nil) }
                .count()
                .fetchOne(db) ?? 0
            guard userListCount == 0 else { return }

            let personal = UUID()
            let family = UUID()
            let work = UUID()
            let reminders = (0..<11).map { _ in UUID() }
            let now = Date()
            let day: TimeInterval = 60 * 60 * 24

            try db.seed {
                ReminderList(id: personal, title: "Personal", colorHex: "#4A99EF", symbolName: "person.crop.circle", position: 0)
                ReminderList(id: family, title: "Family", colorHex: "#ED8935", symbolName: "house.fill", position: 1)
                ReminderList(id: work, title: "Work", colorHex: "#B25DD3", symbolName: "briefcase.fill", position: 2)

                Reminder(id: reminders[0], listId: personal, title: "Groceries", notes: "Milk\nEggs\nApples\nSpinach", position: 0)
                Reminder(id: reminders[1], listId: personal, title: "Haircut", dueDate: now.addingTimeInterval(-2 * day), isFlagged: true, position: 1)
                Reminder(id: reminders[2], listId: personal, title: "Doctor appointment", notes: "Ask about diet", dueDate: now, priority: .high, position: 2)
                Reminder(id: reminders[3], listId: personal, title: "Take a walk", dueDate: now.addingTimeInterval(-190 * day), isCompleted: true, completedAt: now.addingTimeInterval(-189 * day), position: 3)
                Reminder(id: reminders[4], listId: personal, title: "Buy concert tickets", dueDate: now, position: 4)

                Reminder(id: reminders[5], listId: family, title: "Pick up kids from school", dueDate: now.addingTimeInterval(2 * day), priority: .high, isFlagged: true, position: 0)
                Reminder(id: reminders[6], listId: family, title: "Get laundry", dueDate: now.addingTimeInterval(-2 * day), priority: .low, isCompleted: true, completedAt: now.addingTimeInterval(-1 * day), position: 1)
                Reminder(id: reminders[7], listId: family, title: "Take out trash", dueDate: now.addingTimeInterval(4 * day), priority: .high, position: 2)

                Reminder(id: reminders[8], listId: work, title: "Call accountant", notes: "Tax return / next year expenses", dueDate: now.addingTimeInterval(2 * day), position: 0)
                Reminder(id: reminders[9], listId: work, title: "Send weekly emails", dueDate: now.addingTimeInterval(-2 * day), priority: .medium, isCompleted: true, completedAt: now.addingTimeInterval(-1 * day), position: 1)
                Reminder(id: reminders[10], listId: work, title: "Prepare for WWDC", dueDate: now.addingTimeInterval(2 * day), position: 2)
            }

            let tagNames = ["home", "errands", "someday", "urgent"]
            for name in tagNames {
                try Tag.insert { Tag.Draft(name: name) }.execute(db)
            }
        }
    }
}
#endif
