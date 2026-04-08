# App Store Release Checklist

## Before Archive

- Replace `com.ruby.PostureCheck` with your production bundle identifier.
- Set your Apple Developer team in the project signing settings.
- Confirm the app icon and marketing icon are final.
- Verify `LSUIElement` behavior is acceptable for your product review positioning.
- Confirm the app remains sandboxed.
- Verify notifications permission copy and settings behavior on a clean macOS user account.

## Validation

- Build and run on the minimum supported macOS version.
- Test reminder delivery after cold launch.
- Test reminder delivery after login.
- Test wake from sleep and confirm reminders are rebuilt without duplicates.
- Deny notifications, then re-enable them from System Settings.
- Toggle launch at login on and off.
- Run unit tests.

## App Store Connect

- Create the app record with the final bundle identifier.
- Upload screenshots for the settings window and menu bar workflow.
- Use the Health & Fitness category unless your product positioning changes.
- Complete the App Privacy questionnaire. The current implementation stores settings locally and does not send data off-device.
- Fill in age rating and content rights.

## Archive and Submit

- Archive in Xcode using the `Release` configuration.
- Run Xcode organizer validation.
- Submit for review.
