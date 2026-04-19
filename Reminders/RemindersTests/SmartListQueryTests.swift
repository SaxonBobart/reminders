import Foundation
import Testing
@testable import Reminders

@Suite("Built-in smart list queries")
struct SmartListQueryTests {
    /// Seeds a fixed set of 6 reminders and returns the env + ids, so each test
    /// can check its slug returns the right subset.
    private func seeded() async throws -> (TestEnvironment, [UUID]) {
        let env = try TestSupport.makeEnvironment()
        let list = try await env.lists.create(title: "Inbox")
        let now = Date()
        let day: TimeInterval = 86_400

        let r0 = try await env.reminders.create(listId: list.id, title: "Today, incomplete", dueDate: now)
        let r1 = try await env.reminders.create(listId: list.id, title: "Tomorrow, incomplete", dueDate: now.addingTimeInterval(day))
        let r2 = try await env.reminders.create(listId: list.id, title: "Yesterday, completed",
                                                 dueDate: now.addingTimeInterval(-day))
        try await env.reminders.toggleCompletion(id: r2.id)
        let r3 = try await env.reminders.create(listId: list.id, title: "Undated, flagged", isFlagged: true)
        let r4 = try await env.reminders.create(listId: list.id, title: "Undated, plain")
        let r5 = try await env.reminders.create(listId: list.id, title: "Today, flagged",
                                                 dueDate: now, isFlagged: true)
        return (env, [r0.id, r1.id, r2.id, r3.id, r4.id, r5.id])
    }

    @Test func todayReturnsOnlyDueTodayIncomplete() async throws {
        let (env, ids) = try await seeded()
        let results = try await env.reminders.fetchBuiltinSmartList(.today)
        let resultIds = Set(results.map(\.id))
        #expect(resultIds == Set([ids[0], ids[5]]))
    }

    @Test func scheduledReturnsAllIncompleteWithDueDate() async throws {
        let (env, ids) = try await seeded()
        let results = try await env.reminders.fetchBuiltinSmartList(.scheduled)
        let resultIds = Set(results.map(\.id))
        #expect(resultIds == Set([ids[0], ids[1], ids[5]]))
    }

    @Test func allReturnsAllIncomplete() async throws {
        let (env, ids) = try await seeded()
        let results = try await env.reminders.fetchBuiltinSmartList(.all)
        let resultIds = Set(results.map(\.id))
        #expect(resultIds == Set([ids[0], ids[1], ids[3], ids[4], ids[5]]))
    }

    @Test func flaggedReturnsAllFlagged() async throws {
        let (env, ids) = try await seeded()
        let results = try await env.reminders.fetchBuiltinSmartList(.flagged)
        let resultIds = Set(results.map(\.id))
        #expect(resultIds == Set([ids[3], ids[5]]))
    }

    @Test func completedReturnsOnlyCompleted() async throws {
        let (env, ids) = try await seeded()
        let results = try await env.reminders.fetchBuiltinSmartList(.completed)
        let resultIds = Set(results.map(\.id))
        #expect(resultIds == Set([ids[2]]))
    }
}
