import Foundation
import Testing
@testable import Reminders

@Suite("SmartPredicate Codable round-trip")
struct SmartPredicateCodingTests {
    private func roundTrip(_ value: SmartPredicate) throws -> SmartPredicate {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(SmartPredicate.self, from: data)
    }

    @Test func allCases() throws {
        let cases: [SmartPredicate] = [
            .and([.isCompleted(true), .not(.isFlagged(true))]),
            .or([.hasDueDate, .isDeleted(false)]),
            .not(.isCompleted(false)),
            .isCompleted(false),
            .isFlagged(true),
            .isDeleted(false),
            .hasDueDate,
            .dueOn(.today),
            .dueOn(.tomorrow),
            .dueOn(.yesterday),
            .dueOn(.exact(Date(timeIntervalSince1970: 1_700_000_000))),
            .dueBefore(.today),
            .dueAfter(.tomorrow),
            .dueInRange(start: .yesterday, end: .today),
            .priorityIn([0, 1, 5, 9]),
            .listIdIn([UUID(), UUID()]),
            .tagNameIn(["home", "Work"]),
            .titleContains("hello", caseInsensitive: true),
            .titleContains("exact", caseInsensitive: false),
        ]
        for value in cases {
            let decoded = try roundTrip(value)
            #expect(decoded == value)
        }
    }

    @Test func smartQueryWrapperRoundTrips() throws {
        let query = SmartQuery(
            filter: .and([.isFlagged(true), .not(.isDeleted(true))]),
            sort: [SortClause(field: .dueDate, order: .asc)],
            limit: 10
        )
        let data = try JSONEncoder().encode(query)
        let decoded = try JSONDecoder().decode(SmartQuery.self, from: data)
        #expect(decoded == query)
    }

    @Test func builtinJSONStringsAreValid() async throws {
        let env = try TestSupport.makeEnvironment()
        let builtins = try await env.smartLists.fetchBuiltins()
        #expect(builtins.count == 5)
        for list in builtins {
            // Each builtin's queryJSON must decode to a valid SmartQuery.
            _ = try SmartListQueryCompiler.decode(list.queryJSON)
        }
    }
}
