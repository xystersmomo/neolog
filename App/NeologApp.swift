import SwiftUI

@main
struct NeologApp: App {
    @StateObject private var store: Store
    @StateObject private var appState: AppState

    init() {
        let store = Store()
        _store = StateObject(wrappedValue: store)
        _appState = StateObject(wrappedValue: AppState(store: store))
    }

    var body: some Scene {
        WindowGroup {
            LoggingView()
                .environmentObject(appState)
        }
    }
}
