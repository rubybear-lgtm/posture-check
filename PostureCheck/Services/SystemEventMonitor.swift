@preconcurrency import AppKit
import Foundation

final class SystemEventMonitor: @unchecked Sendable {
    private var wakeTokens: [NSObjectProtocol] = []
    private var sleepTokens: [NSObjectProtocol] = []
    private var activationTokens: [NSObjectProtocol] = []
    private var lockTokens: [NSObjectProtocol] = []
    private var isScreenSleeping = false
    private var isScreenLocked = false

    func start(
        onWake: @escaping @Sendable () -> Void,
        onSleep: @escaping @Sendable () -> Void,
        onActivate: @escaping @Sendable () -> Void
    ) {
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        let defaultCenter = NotificationCenter.default
        let distributedCenter = DistributedNotificationCenter.default()

        wakeTokens.append(
            workspaceCenter.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: .main
            ) { _ in
                self.isScreenSleeping = false
                onWake()
            }
        )

        wakeTokens.append(
            workspaceCenter.addObserver(
                forName: NSWorkspace.screensDidWakeNotification,
                object: nil,
                queue: .main
            ) { _ in
                self.isScreenSleeping = false
                onWake()
            }
        )

        sleepTokens.append(
            workspaceCenter.addObserver(
                forName: NSWorkspace.willSleepNotification,
                object: nil,
                queue: .main
            ) { _ in
                self.isScreenSleeping = true
                onSleep()
            }
        )

        sleepTokens.append(
            workspaceCenter.addObserver(
                forName: NSWorkspace.screensDidSleepNotification,
                object: nil,
                queue: .main
            ) { _ in
                self.isScreenSleeping = true
                onSleep()
            }
        )

        activationTokens.append(
            defaultCenter.addObserver(
                forName: NSApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { _ in
                onActivate()
            }
        )

        lockTokens.append(
            distributedCenter.addObserver(
                forName: Notification.Name("com.apple.screenIsLocked"),
                object: nil,
                queue: .main
            ) { _ in
                self.isScreenLocked = true
                onSleep()
            }
        )

        lockTokens.append(
            distributedCenter.addObserver(
                forName: Notification.Name("com.apple.screenIsUnlocked"),
                object: nil,
                queue: .main
            ) { _ in
                self.isScreenLocked = false
                onWake()
            }
        )
    }

    func isUserPresent() -> Bool {
        !isScreenSleeping && !isScreenLocked
    }

    deinit {
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        let defaultCenter = NotificationCenter.default
        let distributedCenter = DistributedNotificationCenter.default()

        for token in wakeTokens {
            workspaceCenter.removeObserver(token)
        }
        for token in sleepTokens {
            workspaceCenter.removeObserver(token)
        }
        for token in activationTokens {
            defaultCenter.removeObserver(token)
        }
        for token in lockTokens {
            distributedCenter.removeObserver(token)
        }
    }
}
