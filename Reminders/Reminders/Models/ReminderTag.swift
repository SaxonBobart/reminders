import Foundation
import SQLiteData

@Table
nonisolated struct ReminderTag: Hashable, Identifiable, Sendable {
    let id: UUID
    var reminderId: Reminder.ID
    var tagId: Tag.ID
    var createdAt: Date = Date()
}

extension ReminderTag.Draft: Identifiable {}
