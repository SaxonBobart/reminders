import Foundation

enum SidebarSelection: Hashable, Sendable {
    case builtinSmartList(SmartList.BuiltinSlug)
    case userList(UUID)
}
