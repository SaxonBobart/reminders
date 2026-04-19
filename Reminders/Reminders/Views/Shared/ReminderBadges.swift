import SwiftUI

struct DueDateBadge: View {
    let date: Date
    let hasTime: Bool

    var body: some View {
        let formatter = Self.relativeFormatter
        let isOverdue = date < Date() && !Calendar.current.isDateInToday(date)
        let isToday = Calendar.current.isDateInToday(date)
        let label: String = {
            if isToday { return hasTime ? "Today, " + Self.timeOnly(date) : "Today" }
            return hasTime
                ? formatter.string(from: date) + ", " + Self.timeOnly(date)
                : formatter.string(from: date)
        }()
        Text(label)
            .font(.caption)
            .foregroundStyle(isOverdue ? Color.red : .secondary)
    }

    private static let relativeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.doesRelativeDateFormatting = true
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    private static func timeOnly(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f.string(from: date)
    }
}

struct PriorityBadge: View {
    let priority: Reminder.Priority
    var body: some View {
        if let text = priority.indicator {
            Text(text)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.orange)
        }
    }
}

extension Reminder.Priority {
    var indicator: String? {
        switch self {
        case .none: return nil
        case .low: return "!"
        case .medium: return "!!"
        case .high: return "!!!"
        }
    }

    var displayName: String {
        switch self {
        case .none: return "None"
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
}

struct TagChip: View {
    let name: String
    var body: some View {
        Text("#" + name)
            .font(.caption)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.blue.opacity(0.15), in: Capsule())
            .foregroundStyle(Color.blue)
    }
}
