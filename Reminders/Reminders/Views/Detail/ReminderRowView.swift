import SQLiteData
import SwiftUI

struct ReminderRowView: View {
    let reminder: Reminder
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button(action: onToggle) {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(reminder.isCompleted ? Color.accentColor : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    PriorityBadge(priority: reminder.priority)
                    Text(reminder.title)
                        .strikethrough(reminder.isCompleted)
                        .foregroundStyle(reminder.isCompleted ? .secondary : .primary)
                    if reminder.isFlagged {
                        Image(systemName: "flag.fill")
                            .font(.caption)
                            .foregroundStyle(Color.orange)
                    }
                }
                if !reminder.notes.isEmpty {
                    Text(reminder.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                if let due = reminder.dueDate {
                    DueDateBadge(date: due, hasTime: reminder.hasTimeComponent)
                }
            }
            Spacer()
        }
        .contentShape(Rectangle())
    }
}
