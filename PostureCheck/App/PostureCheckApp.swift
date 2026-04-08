import SwiftUI

@main
struct PostureCheckApp: App {
    @StateObject private var appState: AppState

    init() {
        let runningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        let state = AppState(isTesting: runningTests)
        _appState = StateObject(wrappedValue: state)

        if !runningTests {
            Task { @MainActor in
                state.start()
            }
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
