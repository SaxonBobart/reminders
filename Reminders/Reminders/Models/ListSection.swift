import Foundation
import SQLiteData

@Table
nonisolated struct ListSection: Hashable, Identifiable, Sendable {
    let id: UUID
    var listId: ReminderList.ID
    var title = ""
    var position = 0
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var deletedAt: Date?
}

extension ListSection.Draft: Identifiable {}
