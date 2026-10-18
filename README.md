# LookFar

Native SwiftUI iPhone app, iOS 17+. Bundle ID: `com.addvalue.lookfar`. Version 1.0 (3). Signing team: `A7QB8PT33N`, inherited from the owner's existing iOS projects. Widget extension: `com.addvalue.lookfar.live`.

Open `LookFar.xcodeproj` and select the LookFar scheme. No third-party packages, API keys, account, backend, or paid service are required.

## Features

- Choose 1–180 minutes; quick presets of 10, 20, 30, 45 minutes.
- Start a one-shot local LOOKFAR notification with optional sound, including while another app is open or the app is terminated normally.
- Optional Live Activity countdown on Lock Screen and Dynamic Island on supported devices; expiry is delivered by the separate local notification.
- Notification actions: open a rest or snooze for 5 minutes.
- Background App Intents for starting, restarting and ending a timer; user-configured Shortcuts App Open automations and bilingual in-app setup instructions.
- User-started 20-second break, gentle blinking prompt, completed-break history and seven-day chart.
- Timer and settings survive app relaunch; cancel removes its scheduled and delivered notification and Live Activity.
- Korean and English UI, VoiceOver labels, native text scaling, Reduce Motion support, local data reset, in-app privacy policy and support.
- Selected icon: LF monogram, concept 04. All four alternatives retained in `Design/IconConcepts`.
- Main timer card: a full-frame photograph of distant mountains and a lake beyond a window; bundled offline with Korean/English accessibility labels. The LF app icon is unchanged.

## Behavior

The countdown measures elapsed time after Start or a Shortcuts action, not smartphone usage. No Screen Time, camera or eye-tracking access is requested. Timers do not automatically repeat; the user or a configured automation starts the next timer. iOS controls banners, sounds, Focus, Scheduled Summary and Dynamic Island presentation. Live Activities can be disabled independently, and iOS can end them. No fake background modes, critical alerts, private APIs or push service are used.

## App Open automation

1. Choose an interval in LookFar and start once to allow notifications.
2. In Apple Shortcuts, create an Automation → App → select apps → Is Opened → Run Immediately (or turn off Ask Before Running on older versions).
3. Add LookFar's **Start eye-break timer** action, not the generic Open App action, and save. LookFar does not come to the foreground.
4. Start keeps an existing active, scheduled timer so app switching cannot postpone reminders. **Restart eye-break timer** instead resets to the full saved duration on every invocation. **End eye-break timer** cancels the scheduled reminder and activity.

The user must create this automation; LookFar cannot create it or inspect selected apps. This is NOT a screen-on/unlock trigger. Timers continue while locked and do not reset when the screen wakes. Unlocking into an already-open app may not trigger an App Open automation. Auto-start refuses to interrupt an active guided break. Notification permission failures are reported to Shortcuts without opening a background permission prompt. Removing/resetting LookFar data does not delete user-created Shortcuts automations; remove those in Shortcuts separately.

The rest countdown is an elapsed-time guide started by the user, not verification of where someone looks. Only completed, user-started breaks enter history (up to 1000 records). An abandoned rest is not counted. Force quit does not cancel an already scheduled local notification; cancel or Reset in the app to remove it. Restarting the phone, system policy and notification settings should be checked on a real device before release.

## Build and test

```sh
python3 scripts/generate_project.py
xcodebuild -project LookFar.xcodeproj -scheme LookFar -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/LookFarDerived build CODE_SIGNING_ALLOWED=NO
xcodebuild -project LookFar.xcodeproj -scheme LookFar -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' -derivedDataPath /tmp/LookFarDerived test CODE_SIGNING_ALLOWED=NO -parallel-testing-enabled NO
```

The generator reproduces the committed Xcode project and shared scheme. UI tests cover persistence, cancellation, background expiry, snooze, rest completion, history, privacy, reset, and language captures. A four-second timer is enabled only by the Debug UI-test launch argument `-UITestShortTimer`; Release contains no test timer override.

Selected LF icon is bundled and copied to `AppStore/Icon/LookFar-1024.png`. Actual iPhone captures (original and store-size copies) are kept locally in `AppStore/Screenshots` and excluded from Git at the owner's request. The current development-signed Release archive is local-only at `build/LookFar-1.0-build3.xcarchive`; previous archives are retained.

See `AppStore/VERIFICATION.md`, `AppStore/METADATA.md` and `AppStore/REVIEW.md` for physical-device evidence, submission materials and outstanding operational requirements. App Store approval is Apple's decision. Creating the project does not upload or submit it.
