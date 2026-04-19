import Foundation
import Testing
@testable import Reminders

@Suite("ReminderList repository")
struct ReminderListRepositoryTests {
    @Test func createAssignsIncreasingPositions() async throws {
        let env = try TestSupport.makeEnvironment()
        let a = try await env.lists.create(title: "A")
        let b = try await env.lists.create(title: "B")
        let c = try await env.lists.create(title: "C")
        #expect(a.position == 0)
        #expect(b.position == 1)
        #expect(c.position == 2)
    }

    @Test func softDeleteExcludesFromActive() async throws {
        let env = try TestSupport.makeEnvironment()
        let a = try await env.lists.create(title: "A")
        let b = try await env.lists.create(title: "B")
        try await env.lists.softDelete(id: a.id)
        let active = try await env.lists.fetchActive()
        #expect(active.count == 1)
        #expect(active.first?.id == b.id)
    }

    @Test func fetchByIdReturnsNilForMissing() async throws {
        let env = try TestSupport.makeEnvironment()
        let missing = try await env.lists.fetchById(UUID())
        #expect(missing == nil)
    }
}

@Suite("Reminder repository")
struct ReminderRepositoryTests {
    @Test func createAndFetch() async throws {
        let env = try TestSupport.makeEnvironment()
        let list = try await env.lists.create(title: "Inbox")
        let r = try await env.reminders.create(listId: list.id, title: "Buy milk")
        #expect(r.title == "Buy milk")
        #expect(r.isCompleted == false)
        #expect(r.completedAt == nil)

        let fetched = try await env.reminders.fetchById(r.id)
        #expect(fetched?.title == "Buy milk")
    }

    @Test func toggleCompletionSetsAndClearsCompletedAt() async throws {
        let env = try TestSupport.makeEnvironment()
        let list = try await env.lists.create(title: "Inbox")
        let r = try await env.reminders.create(listId: list.id, title: "Do a thing")

        try await env.reminders.toggleCompletion(id: r.id)
        var fetched = try await env.reminders.fetchById(r.id)
        #expect(fetched?.isCompleted == true)
        #expect(fetched?.completedAt != nil)

        try await env.reminders.toggleCompletion(id: r.id)
        fetched = try await env.reminders.fetchById(r.id)
        #expect(fetched?.isCompleted == false)
        #expect(fetched?.completedAt == nil)
    }

    @Test func softDeleteRemovesFromListFetch() async throws {
        let env = try TestSupport.makeEnvironment()
        let list = try await env.lists.create(title: "Inbox")
        let a = try await env.reminders.create(listId: list.id, title: "A")
        _ = try await env.reminders.create(listId: list.id, title: "B")
        try await env.reminders.softDelete(id: a.id)

        let remaining = try await env.reminders.fetchByList(list.id)
        #expect(remaining.count == 1)
        #expect(remaining.first?.title == "B")
    }

    @Test func subtaskOfSubtaskIsRejected() async throws {
        let env = try TestSupport.makeEnvironment()
        let list = try await env.lists.create(title: "Inbox")
        let parent = try await env.reminders.create(listId: list.id, title: "Parent")
        let child = try await env.reminders.create(listId: list.id, title: "Child", parentId: parent.id)

        // Now try to add a grandchild by creating a new reminder whose parent is `child`.
        // The BEFORE INSERT trigger should raise ABORT.
        await #expect(throws: (any Error).self) {
            _ = try await env.reminders.create(listId: list.id, title: "Grandchild", parentId: child.id)
        }
    }

    @Test func setParentToSubtaskIsRejected() async throws {
        let env = try TestSupport.makeEnvironment()
        let list = try await env.lists.create(title: "Inbox")
        let parent = try await env.reminders.create(listId: list.id, title: "Parent")
        let child = try await env.reminders.create(listId: list.id, title: "Child", parentId: parent.id)
        let standalone = try await env.reminders.create(listId: list.id, title: "Standalone")

        await #expect(throws: (any Error).self) {
            try await env.reminders.setParent(childId: standalone.id, parentId: child.id)
        }
    }

    @Test func fetchSubtasks() async throws {
        let env = try TestSupport.makeEnvironment()
        let list = try await env.lists.create(title: "Inbox")
        let parent = try await env.reminders.create(listId: list.id, title: "Parent")
        _ = try await env.reminders.create(listId: list.id, title: "C1", parentId: parent.id)
        _ = try await env.reminders.create(listId: list.id, title: "C2", parentId: parent.id)

        let subs = try await env.reminders.fetchSubtasks(of: parent.id)
        #expect(subs.count == 2)
    }
}

@Suite("Tag repository")
struct TagRepositoryTests {
    @Test func findOrCreateIsCaseInsensitive() async throws {
        let env = try TestSupport.makeEnvironment()
        let home1 = try await env.tags.findOrCreate(name: "Home")
        let home2 = try await env.tags.findOrCreate(name: "home")
        let home3 = try await env.tags.findOrCreate(name: "HOME")
        #expect(home1.id == home2.id)
        #expect(home1.id == home3.id)
        #expect(home1.name == "Home")  // preserves original casing
    }

    @Test func attachAndDetach() async throws {
        let env = try TestSupport.makeEnvironment()
        let list = try await env.lists.create(title: "Inbox")
        let r = try await env.reminders.create(listId: list.id, title: "X")
        let tag = try await env.tags.findOrCreate(name: "urgent")

        try await env.tags.attach(reminderId: r.id, tagId: tag.id)
        var tags = try await env.tags.tags(forReminder: r.id)
        #expect(tags.count == 1)
        #expect(tags.first?.name == "urgent")

        try await env.tags.detach(reminderId: r.id, tagId: tag.id)
        tags = try await env.tags.tags(forReminder: r.id)
        #expect(tags.isEmpty)
    }
}

@Suite("SmartList repository")
struct SmartListRepositoryTests {
    @Test func fiveBuiltinsSeeded() async throws {
        let env = try TestSupport.makeEnvironment()
        let builtins = try await env.smartLists.fetchBuiltins()
        #expect(builtins.count == 5)
        let slugs = builtins.compactMap(\.slug)
        #expect(Set(slugs) == Set(["today", "scheduled", "all", "flagged", "completed"]))
    }
}
