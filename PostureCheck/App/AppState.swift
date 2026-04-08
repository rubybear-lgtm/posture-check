import AppKit
import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var settings: ReminderSettings
    @Published private(set) var permissionState: PermissionState = .notDetermined
    @Published private(set) var nextReminderDate: Date?
    @Published private(set) var loginItemEnabled: Bool = false
    @Published private(set) var userIsPresent = true
    @Published var statusMessage: String?
    @Published var customIntervalMinutes: Double

    private let settingsStore: SettingsStore
    private let notificationManager: NotificationManager
    private let loginItemManager: LoginItemManager
    private let systemEventMonitor: SystemEventMonitor
    private let reminderLimit = 64
    private let isTesting: Bool
    private var hasStarted = false
    private var hasPromptedForNotificationPermission = false
    private var settingsWindowController: NSWindowController?

    init(
        isTesting: Bool = false,
        settingsStore: SettingsStore = SettingsStore(),
        notificationManager: NotificationManager = NotificationManager(),
        loginItemManager: LoginItemManager = LoginItemManager(),
        systemEventMonitor: SystemEventMonitor = SystemEventMonitor()
    ) {
        let initialSettings = settingsStore.load()
        self.settingsStore = settingsStore
        self.notificationManager = notificationManager
        self.loginItemManager = loginItemManager
        self.systemEventMonitor = systemEventMonitor
        self.settings = initialSettings
        self.customIntervalMinutes = Double(initialSettings.intervalMinutes)
        self.isTesting = isTesting
    }

    var canRunReminders: Bool {
        settings.isEnabled && settings.hasValidTimeWindow && permissionState.isAuthorized && userIsPresent
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        guard !isTesting else { return }

        systemEventMonitor.start { [weak self] in
            Task { @MainActor in
                self?.userIsPresent = true
                await self?.refreshSchedule()
            }
        } onSleep: { [weak self] in
            Task { @MainActor in
                self?.userIsPresent = false
                await self?.pauseRemindersWhileAway()
            }
        } onActivate: { [weak self] in
            Task { @MainActor in
                self?.userIsPresent = true
                if self?.settings.showMenuBarIcon == false {
                    self?.openSettingsWindow()
                }
                await self?.refreshPermissionAndSchedule()
            }
        }

        Task {
            userIsPresent = true
            updateActivationPolicy()
            await refreshPermissionAndSchedule()
            loginItemEnabled = loginItemManager.isEnabled()

            if permissionState == .notDetermined {
                openSettingsWindow()
                await requestNotificationPermissionIfNeeded()
            } else if !settings.isEnabled {
                openSettingsWindow()
            }
        }
    }

    func openSettingsWindow() {
        let windowController: NSWindowController

        if let existing = settingsWindowController {
            windowController = existing
        } else {
            let hostingController = NSHostingController(rootView: SettingsView(appState: self))
            let window = NSWindow(contentViewController: hostingController)
            window.title = "Posture Check"
            window.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
            window.setContentSize(NSSize(width: 620, height: 680))
            window.center()
            window.isReleasedWhenClosed = false
            let controller = NSWindowController(window: window)
            settingsWindowController = controller
            windowController = controller
        }

        NSApp.activate(ignoringOtherApps: true)
        windowController.showWindow(nil)
        windowController.window?.makeKeyAndOrderFront(nil)
    }

    func openNotificationSettings() {
        let candidates = [
            URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension"),
            URL(string: "x-apple.systempreferences:com.apple.preference.notifications"),
            URL(string: "x-apple.systempreferences:")
        ]

        for url in candidates.compactMap({ $0 }) where NSWorkspace.shared.open(url) {
            return
        }
    }

    func toggleReminders(_ enabled: Bool) {
        updateSettings {
            $0.isEnabled = enabled
        }
    }

    func setMenuBarIconVisibility(_ visible: Bool) {
        updateSettings {
            $0.showMenuBarIcon = visible
        }

        updateActivationPolicy()

        if !visible {
            openSettingsWindow()
        }
    }

    func setInterval(_ interval: Int) {
        updateSettings {
            $0.intervalMinutes = interval
        }
    }

    func updateCustomInterval(from value: Double) {
        updateSettings {
            $0.intervalMinutes = Int(value.rounded())
        }
    }

    func setWorkingHoursEnabled(_ enabled: Bool) {
        updateSettings {
            $0.workingHoursEnabled = enabled
        }
    }

    func setWeekdaysOnly(_ enabled: Bool) {
        updateSettings {
            $0.weekdaysOnly = enabled
        }
    }

    func updateTimeWindow(startHour: Int, startMinute: Int, endHour: Int, endMinute: Int) {
        updateSettings {
            $0.startMinutes = (startHour * 60) + startMinute
            $0.endMinutes = (endHour * 60) + endMinute
        }
    }

    func setLaunchAtLogin(_ enabled: Bool) async {
        do {
            try loginItemManager.setEnabled(enabled)
            updateSettings(saveAndRefresh: false) {
                $0.launchAtLogin = enabled
            }
            loginItemEnabled = loginItemManager.isEnabled()
            try persistSettings()
            statusMessage = nil
        } catch {
            loginItemEnabled = loginItemManager.isEnabled()
            statusMessage = "Launch at login could not be changed."
        }
    }

    func requestNotificationPermission() async -> Bool {
        NSApp.activate(ignoringOtherApps: true)
        try? await Task.sleep(nanoseconds: 250_000_000)

        let granted = await notificationManager.requestAuthorization()
        hasPromptedForNotificationPermission = true
        permissionState = await notificationManager.authorizationStatus()

        if granted {
            statusMessage = "Notifications enabled."
            await refreshSchedule()
        } else if permissionState == .denied {
            statusMessage = "Notifications are disabled in System Settings."
        } else if permissionState == .notDetermined {
            statusMessage = "The macOS notification prompt did not appear. Keep the app in front and try again."
        }

        return granted
    }

    func refreshNotificationPermission() async {
        permissionState = await notificationManager.authorizationStatus()

        if permissionState.isAuthorized {
            statusMessage = "Notifications enabled."
        } else if permissionState == .denied {
            statusMessage = "Notifications are disabled in System Settings."
        } else if permissionState == .notDetermined {
            statusMessage = "Notifications have not been enabled yet."
        } else {
            statusMessage = nil
        }

        await refreshSchedule()
    }

    func sendTestReminder() async {
        if permissionState == .notDetermined {
            _ = await requestNotificationPermission()
        }

        guard permissionState.isAuthorized else {
            statusMessage = "Enable notifications in System Settings before sending a reminder."
            return
        }

        guard userIsPresent else {
            statusMessage = "Reminders resume when you return to your Mac."
            return
        }

        do {
            try await notificationManager.scheduleImmediateReminder()
            statusMessage = "Reminder sent."
        } catch {
            statusMessage = "Could not send the reminder."
        }
    }

    func refreshPermissionAndSchedule() async {
        permissionState = await notificationManager.authorizationStatus()
        await refreshSchedule()
    }

    func refreshSchedule() async {
        permissionState = await notificationManager.authorizationStatus()

        do {
            try settings.validate()
        } catch {
            nextReminderDate = nil
            statusMessage = error.localizedDescription
            await notificationManager.removeAllPendingRequests()
            return
        }

        guard settings.isEnabled else {
            nextReminderDate = nil
            statusMessage = nil
            await notificationManager.removeAllPendingRequests()
            return
        }

        guard userIsPresent else {
            nextReminderDate = nil
            statusMessage = "Reminders pause while your Mac is asleep or locked."
            await notificationManager.removeAllPendingRequests()
            return
        }

        guard permissionState.isAuthorized else {
            nextReminderDate = nil
            statusMessage = permissionState == .denied
                ? "Notifications are disabled in System Settings."
                : "Enable notifications to start reminders."
            await notificationManager.removeAllPendingRequests()
            return
        }

        let reminders = ReminderEngine.upcomingReminders(
            from: Date(),
            settings: settings,
            calendar: .autoupdatingCurrent,
            horizonDays: 7,
            maxCount: reminderLimit
        )

        nextReminderDate = reminders.first

        do {
            try await notificationManager.replaceScheduledReminders(with: reminders)
            statusMessage = reminders.isEmpty ? "No reminders fall inside the current schedule." : nil
        } catch {
            statusMessage = "Failed to schedule reminders."
        }
    }

    private func updateSettings(saveAndRefresh: Bool = true, _ mutate: (inout ReminderSettings) -> Void) {
        var updated = settings
        mutate(&updated)
        settings = updated.normalized
        customIntervalMinutes = Double(settings.intervalMinutes)

        guard saveAndRefresh else { return }

        do {
            try persistSettings()
            Task {
                if settings.isEnabled && permissionState == .notDetermined {
                    await requestNotificationPermissionIfNeeded()
                } else {
                    await refreshSchedule()
                }
            }
        } catch {
            statusMessage = "Could not save settings."
        }
    }

    private func requestNotificationPermissionIfNeeded() async {
        guard settings.isEnabled else { return }
        guard permissionState == .notDetermined else { return }
        guard !hasPromptedForNotificationPermission else { return }

        hasPromptedForNotificationPermission = true
        _ = await requestNotificationPermission()
    }

    private func persistSettings() throws {
        try settingsStore.save(settings)
    }

    private func pauseRemindersWhileAway() async {
        nextReminderDate = nil
        await notificationManager.removeAllPendingRequests()
        if settings.isEnabled {
            statusMessage = "Reminders pause while your Mac is asleep or locked."
        }
    }

    private func updateActivationPolicy() {
        let policy: NSApplication.ActivationPolicy = settings.showMenuBarIcon ? .accessory : .regular
        NSApp.setActivationPolicy(policy)
    }
}
