import SQLiteData
import SwiftUI

struct RootView: View {
    @State private var selection: SidebarSelection? = .builtinSmartList(.today)

    @FetchAll(SmartList.order(by: \.position)) private var smartLists: [SmartList]
    @FetchAll(
        ReminderList.where { $0.deletedAt.is(nil) }.order(by: \.position)
    ) private var lists: [ReminderList]

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
        } detail: {
            detail
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let selection {
            ReminderListView(selection: selection, title: title(for: selection))
                .id(selection)
        } else {
            ContentUnavailableView(
                "Select a list",
                systemImage: "sidebar.left",
                description: Text("Pick a smart list or one of your lists to see its reminders.")
            )
        }
    }

    private func title(for selection: SidebarSelection) -> String {
        switch selection {
        case .builtinSmartList(let slug):
            return smartLists.first(where: { $0.slug == slug.rawValue })?.title
                ?? slug.rawValue.capitalized
        case .userList(let id):
            return lists.first(where: { $0.id == id })?.title ?? "List"
        }
    }
}
