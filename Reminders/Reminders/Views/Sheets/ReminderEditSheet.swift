import SQLiteData
import SwiftUI

struct ReminderEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Dependency(\.defaultDatabase) private var database
    @State private var draft: Reminder
    @State private var hasDueDate: Bool

    init(reminder: Reminder) {
        _draft = State(initialValue: reminder)
        _hasDueDate = State(initialValue: reminder.dueDate != nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $draft.title)
                    TextField("Notes", text: $draft.notes, axis: .vertical)
                        .lineLimit(2...5)
                }

                Section("Due Date") {
                    Toggle("Has due date", isOn: $hasDueDate)
                        .onChange(of: hasDueDate) { _, now in
                            if now && draft.dueDate == nil {
                                draft.dueDate = Date()
                            } else if !now {
                                draft.dueDate = nil
                            }
                        }
                    if hasDueDate, draft.dueDate != nil {
                        DatePicker(
                            "Date",
                            selection: Binding(
                                get: { draft.dueDate ?? Date() },
                                set: { draft.dueDate = $0 }
                            ),
                            displayedComponents: draft.hasTimeComponent
                                ? [.date, .hourAndMinute]
                                : [.date]
                        )
                        Toggle("Include time", isOn: $draft.hasTimeComponent)
                    }
                }

                Section("Flags") {
                    Toggle("Flagged", isOn: $draft.isFlagged)
                    Picker("Priority", selection: $draft.priority) {
                        ForEach(Reminder.Priority.allCases, id: \.self) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                }
            }
            .navigationTitle("Edit Reminder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            let repo = ReminderRepository(database: database)
                            try? await repo.update(draft)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
