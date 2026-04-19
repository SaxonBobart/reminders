import SQLiteData
import SwiftUI

@main
struct RemindersApp: App {
    init() {
        prepareDependencies {
            $0.defaultDatabase = try! appDatabase()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
