import SwiftUI
import FirebaseCore

@main
struct TodoListApp: App {
    @StateObject private var taskStore = TaskStore()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(taskStore)
//                .environment(\.colorScheme, .dark) /* remove line from comment to activate dark mode*/
        }
    }
}
