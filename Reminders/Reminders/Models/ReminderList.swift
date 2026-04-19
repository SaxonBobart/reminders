import Foundation
import SQLiteData

@Table
nonisolated struct ReminderList: Hashable, Identifiable, Sendable {
    static let defaultColorHex = "#4A99EF"
    static let defaultSymbolName = "list.bullet"

    let id: UUID
    var groupId: ListGroup.ID?
    var title = ""
    var colorHex: String = ReminderList.defaultColorHex
    var symbolName: String = ReminderList.defaultSymbolName
    var position = 0
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var deletedAt: Date?
}

extension ReminderList.Draft: Identifiable {}
