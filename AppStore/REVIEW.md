# Review preparation

Prepared 2026-10-15. This is implementation guidance, not an approval or submission receipt.

## Review notes (English)

LookFar is a native, offline eye-break reminder app. No login or special access is required.

1. On Timer, choose Custom and set 1 minute, then tap Start my reminder.
2. Allow notifications. Press Home and wait one minute. A local notification titled LOOKFAR appears, subject to device notification settings.
3. Long press the notification for Take a break / Remind in 5 min actions, or tap it to open the rest screen.
4. Tap Start a 20-second break. At completion, Done returns to the app; Your breaks shows the completed record.
5. Start my next reminder explicitly starts another one-shot timer.
6. On a physical device supporting Dynamic Island, with Live Activities enabled, starting a timer also starts a real countdown. Expiry uses the local notification. The app does not force Dynamic Island expansion or rely on background execution for alerts.
7. Settings contains the complete privacy policy, developer contact and Reset all data. Reset cancels pending notifications, ends the activity, and deletes local history and preferences.
8. Settings → Start when apps open explains user-created Shortcuts App Open automations. In Shortcuts search LookFar to find Start eye-break timer, Restart eye-break timer and End eye-break timer. These run without bringing LookFar to the foreground. Start preserves an active scheduled timer; Restart uses the full saved duration. All starts require notification permission and do not interrupt an active guided break.

No automatic screen-on/lock detection is claimed. Timers continue while locked. The user creates and removes personal automations in Shortcuts; Reset all data does not remove them. No Screen Time entitlement is used.

The app measures elapsed time from Start and does not monitor Screen Time or eye movements. It makes no diagnosis, treatment or eyesight-improvement claims. There is no network service, tracking, advertising, payment, or third-party SDK. All four icon concepts were generated specifically for this app; the owner selected the LF monogram.

## Guideline alignment

- 2.1: native working timer, persisted state, visible permission failure, notification cancellation and meaningful UI checks.
- 2.3: screenshots captured from the running app; no simulated functionality in App Store images. Dynamic Island is described as device-dependent.
- 2.5: UserNotifications / ActivityKit / WidgetKit public APIs. No audio background loop, background timer abuse, critical alert entitlement or private API.
- 4.2: configurable local notification, Live Activity extension, guided break, local history, accessibility and settings. Apple determines sufficient utility.
- 5.1.1: bundled policy and CA92.1 manifest, minimal notification permission, no tracking. Public privacy and support URLs must be hosted before submission.

## Release requirements

- Register/confirm explicit app ID `com.addvalue.lookfar` and extension ID `com.addvalue.lookfar.live` in the existing development team. No push entitlement is required.
- Use automatic distribution signing in Xcode, archive Release for a real iOS device, validate and upload through Organizer when authorized. An unsigned archive is not uploadable.
- Publish the supplied privacy and support pages to an owner-controlled public HTTPS site and verify logged-out access. Enter these URLs in App Store Connect.
- Reuse existing review contact name, phone and account legal information in App Store Connect.
- Test banner delivery while using another app, permission denial, Banner off, Silent / Focus / Summary behavior, screen lock, cancellation, snooze and Dynamic Island on a physical device. Simulator screenshots do not prove physical-device notification timing or Island behavior.
- Complete current age-rating, App Privacy, category and pricing forms. No automatic upload/submission is performed.

## Sources checked

- https://developer.apple.com/app-store/review/guidelines/
- https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app
- https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities
- https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications
