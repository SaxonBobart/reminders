import Foundation
import SQLiteData

@Table
nonisolated struct Tag: Hashable, Identifiable, Sendable {
    let id: UUID
    var name: String
    var colorHex = "#888888"
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

extension Tag.Draft: Identifiable {}
