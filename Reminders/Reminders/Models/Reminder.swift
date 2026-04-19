import Foundation
import SQLiteData

@Table
nonisolated struct Reminder: Hashable, Identifiable, Sendable {
    let id: UUID
    var listId: ReminderList.ID
    var sectionId: ListSection.ID?
    var parentId: Reminder.ID?
    var title = ""
    var notes = ""
    var url: String?
    var dueDate: Date?
    var hasTimeComponent = false
    var priority: Priority = .none
    var isFlagged = false
    var isCompleted = false
    var completedAt: Date?
    var position = 0
    var earlyReminder: TimeInterval?
    var recurrenceRule: String?
    var locationLatitude: Double?
    var locationLongitude: Double?
    var locationRadius: Double?
    var locationTrigger: String?
    var locationName: String?
    var assignedUserId: String?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var deletedAt: Date?

    enum Priority: Int, QueryBindable, Sendable, Codable, CaseIterable {
        case none = 0
        case low = 1
        case medium = 5
        case high = 9
    }
}

extension Reminder.Draft: Identifiable {}
