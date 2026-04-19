import Foundation
import SQLiteData

@Table
nonisolated struct ListGroup: Hashable, Identifiable, Sendable {
    let id: UUID
    var title = ""
    var position = 0
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var deletedAt: Date?
}

extension ListGroup.Draft: Identifiable {}
