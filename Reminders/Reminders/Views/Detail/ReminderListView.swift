import SQLiteData
import SwiftUI

struct ReminderListView: View {
    let selection: SidebarSelection
    let title: String

    @FetchAll var reminders: [Reminder]
    @Dependency(\.defaultDatabase) private var database
    @State private var newTitle = ""
    @State private var editingReminder: Reminder?

    init(selection: SidebarSelection, title: String) {
        self.selection = selection
        self.title = title
        let query = Self.query(for: selection)
        _reminders = FetchAll(query.order(by: \.position))
    }

    var body: some View {
        List {
            ForEach(reminders) { reminder in
                ReminderRowView(reminder: reminder) {
                    Task { await toggle(reminder) }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        Task { await delete(reminder) }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    Button {
                        Task { await toggleFlag(reminder) }
                    } label: {
                        Label("Flag", systemImage: reminder.isFlagged ? "flag.slash" : "flag")
                    }
                    .tint(.orange)
                }
                .contentShape(Rectangle())
                .onTapGesture { editingReminder = reminder }
            }
        }
        .navigationTitle(title)
        .overlay(alignment: .center) {
            if reminders.isEmpty {
                ContentUnavailableView(
                    "No Reminders",
                    systemImage: "checklist",
                    description: Text("Tap the field below to add one.")
                )
            }
        }
        .safeAreaInset(edge: .bottom) { quickAdd }
        .sheet(item: $editingReminder) { reminder in
            ReminderEditSheet(reminder: reminder)
        }
    }

    @ViewBuilder
    private var quickAdd: some View {
        if case .userList(let listId) = selection {
            HStack {
                TextField("New Reminder", text: $newTitle)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.done)
                    .onSubmit { Task { await addReminder(listId: listId) } }
                Button("Add") {
                    Task { await addReminder(listId: listId) }
                }
                .disabled(trimmed.isEmpty)
            }
            .padding()
            .background(.bar)
        }
    }

    private var trimmed: String {
        newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Query dispatch

    private static func query(for selection: SidebarSelection) -> Where<Reminder> {
        switch selection {
        case .builtinSmartList(let slug):
            return SmartListQueryCompiler.builtinWhere(slug)
        case .userList(let id):
            return Reminder.where { r in r.listId.eq(id) && r.deletedAt.is(nil) }
        }
    }

    // MARK: - Actions

    private var repo: ReminderRepository {
        ReminderRepository(database: database)
    }

    private func addReminder(listId: UUID) async {
        let t = trimmed
        guard !t.isEmpty else { return }
        _ = try? await repo.create(listId: listId, title: t)
        newTitle = ""
    }

    private func toggle(_ r: Reminder) async {
        try? await repo.toggleCompletion(id: r.id)
    }

    private func toggleFlag(_ r: Reminder) async {
        try? await repo.setFlag(id: r.id, flagged: !r.isFlagged)
    }

    private func delete(_ r: Reminder) async {
        try? await repo.softDelete(id: r.id)
    }
}
