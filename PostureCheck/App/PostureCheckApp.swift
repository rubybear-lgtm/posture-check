import SwiftUI

@main
struct PostureCheckApp: App {
    @StateObject private var appState: AppState

    init() {
        let state = AppState()
        _appState = StateObject(wrappedValue: state)

        Task { @MainActor in
            state.start()
        }
    }

    var body: some Scene {
        MenuBarExtra(isInserted: Binding(
            get: { appState.settings.showMenuBarIcon },
            set: { _ in }
        )) {
            MenuBarContentView(appState: appState)
        } label: {
            Image("MenuBarIcon")
                .renderingMode(.original)
                .accessibilityLabel("Posture Check")
        }
        .menuBarExtraStyle(.window)
    }
}
