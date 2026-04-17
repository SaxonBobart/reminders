//
//  ContentView.swift
//  Reminders
//
//  Created by Saxon Bobart on 17/4/2026.
//

import SwiftUI

struct ContentView: View {
    @State private var reminders: [Reminder] = []
    @State private var newTitle: String = ""

    var body: some View {
        NavigationStack {
            Group {
                if reminders.isEmpty {
                    ContentUnavailableView(
                        "No Reminders",
                        systemImage: "checklist",
                        description: Text("Tap the field below to add one.")
                    )
                } else {
                    List {
                        ForEach($reminders) { $reminder in
                            ReminderRow(reminder: $reminder)
                        }
                        .onDelete { indexSet in
                            reminders.remove(atOffsets: indexSet)
                        }
                    }
                }
            }
            .navigationTitle("Reminders")
            .safeAreaInset(edge: .bottom) {
                HStack {
                    TextField("New Reminder", text: $newTitle)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)
                        .onSubmit(addReminder)

                    Button("Add", action: addReminder)
                        .disabled(trimmedTitle.isEmpty)
                }
                .padding()
                .background(.bar)
            }
        }
    }

    private var trimmedTitle: String {
        newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func addReminder() {
        let trimmed = trimmedTitle
        guard !trimmed.isEmpty else { return }
        reminders.append(Reminder(title: trimmed))
        newTitle = ""
    }
}

private struct ReminderRow: View {
    @Binding var reminder: Reminder

    var body: some View {
        HStack {
            Button {
                reminder.isCompleted.toggle()
            } label: {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(reminder.isCompleted ? Color.accentColor : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            Text(reminder.title)
                .strikethrough(reminder.isCompleted)
                .foregroundStyle(reminder.isCompleted ? .secondary : .primary)
        }
    }
}

#Preview {
    ContentView()
}
