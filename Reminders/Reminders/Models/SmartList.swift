import Foundation
import SQLiteData

@Table
nonisolated struct SmartList: Hashable, Identifiable, Sendable {
    let id: UUID
    var kind: Kind = .user
    var slug: String?
    var title = ""
    var symbolName = "sparkles"
    var colorHex = "#4A99EF"
    var queryJSON = "{}"
    var position = 0
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    enum Kind: String, QueryBindable, Sendable, Codable {
        case builtin
        case user
    }

    enum BuiltinSlug: String, Sendable, Codable, CaseIterable {
        case today
        case scheduled
        case all
        case flagged
        case completed
    }
}

extension SmartList.Draft: Identifiable {}
