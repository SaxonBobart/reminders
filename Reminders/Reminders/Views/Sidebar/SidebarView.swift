import SQLiteData
import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarSelection?
    @FetchAll(SmartList.order(by: \.position)) var smartLists: [SmartList]
    @FetchAll(
        ReminderList.where { $0.deletedAt.is(nil) }.order(by: \.position)
    ) var lists: [ReminderList]
    @State private var showingNewList = false

    var body: some View {
        List(selection: $selection) {
            Section("Smart Lists") {
                ForEach(smartLists) { smart in
                    if let slug = smart.slug,
                       let builtin = SmartList.BuiltinSlug(rawValue: slug) {
                        Label {
                            Text(smart.title)
                        } icon: {
                            Image(systemName: smart.symbolName)
                                .foregroundStyle(Color(hex: smart.colorHex))
                        }
                        .tag(SidebarSelection.builtinSmartList(builtin))
                    }
                }
            }

            Section("My Lists") {
                ForEach(lists) { list in
                    Label {
                        Text(list.title)
                    } icon: {
                        Image(systemName: list.symbolName)
                            .foregroundStyle(Color(hex: list.colorHex))
                    }
                    .tag(SidebarSelection.userList(list.id))
                }
            }
        }
        .navigationTitle("Reminders")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingNewList = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewList) {
            ListEditSheet(existing: nil)
        }
    }
}
