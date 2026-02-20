import SwiftUI

@main
struct ClaudeSessionsApp: App {
    @StateObject private var store = SessionStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 900, minHeight: 500)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1200, height: 700)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Refresh") {
                    store.scan()
                }
                .keyboardShortcut("r")

                Button("Quick Open") {
                    NotificationCenter.default.post(name: .quickOpen, object: nil)
                }
                .keyboardShortcut("p")
            }
        }
    }
}
