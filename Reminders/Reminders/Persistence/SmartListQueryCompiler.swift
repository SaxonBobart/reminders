import Foundation
import SQLiteData

/// Compiles a ``SmartList`` (built-in or user-defined) into a query over ``Reminder``.
///
/// Chunk 1 supports the 5 built-in slugs with hand-written queries. The JSON
/// filter is decoded for round-trip testing and forward compatibility, but
/// user-defined predicate-to-SQL compilation is deferred to Chunk 2.
nonisolated enum SmartListQueryCompiler {
    /// Decode a JSON string into a ``SmartQuery`` value. Pure; no DB access.
    static func decode(_ json: String) throws -> SmartQuery {
        let data = Data(json.utf8)
        return try JSONDecoder().decode(SmartQuery.self, from: data)
    }

    /// Build a `Where<Reminder>` clause for a built-in smart list.
    /// `now` is injected for testability.
    static func builtinWhere(
        _ slug: SmartList.BuiltinSlug,
        now: Date = Date()
    ) -> Where<Reminder> {
        switch slug {
        case .today:
            return Reminder.where { r in
                !r.isCompleted && r.deletedAt.is(nil) && r.isDueOn(now)
            }
        case .scheduled:
            return Reminder.where { r in
                !r.isCompleted && r.deletedAt.is(nil) && r.dueDate.isNot(nil)
            }
        case .all:
            return Reminder.where { r in
                !r.isCompleted && r.deletedAt.is(nil)
            }
        case .flagged:
            return Reminder.where { r in
                r.isFlagged && r.deletedAt.is(nil)
            }
        case .completed:
            return Reminder.where { r in
                r.isCompleted && r.deletedAt.is(nil)
            }
        }
    }
}

// MARK: - Reminder column helpers

nonisolated extension Reminder.TableColumns {
    /// True when `dueDate` falls on the same calendar day as `reference`.
    func isDueOn(_ reference: Date) -> some QueryExpression<Bool> {
        #sql("coalesce(date(\(dueDate)) = date(\(reference)), 0)")
    }

    /// True when `dueDate` is strictly before the day of `reference`.
    func isOverdue(_ reference: Date) -> some QueryExpression<Bool> {
        #sql("coalesce(date(\(dueDate)) < date(\(reference)), 0)")
    }
}
