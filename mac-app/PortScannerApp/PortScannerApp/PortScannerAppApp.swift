import SwiftUI

@main
struct PortScannerAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 980, height: 680)
        .commands {
            CommandGroup(replacing: .newItem) { }   // hide New Window menu item
        }
    }
}
