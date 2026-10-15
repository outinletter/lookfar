# Verification record

2026-10-15, real iPhone 16 Pro, iOS 27.2 beta, wired connection, Developer Mode enabled. Xcode 26.3. Simulator screenshots are excluded.

## Passed on the physical iPhone

- Interval selection survives termination/relaunch; custom minute picker opens.
- Local notification permission and timer scheduling; countdown survives relaunch; cancel returns to idle.
- Four-second Debug-only test reminder expires while backgrounded; reopening presents rest; snooze creates a new five-minute timer; cancellation works.
- Complete a full twenty-second user-started rest, save exactly one record, and verify the record remains after relaunch.
- Settings, complete privacy policy, and reset to empty history.
- Korean and English screens.

The first device run passed five of six tests. It exposed that the root screen's foreground polling task did not complete a rest while covered by the full-screen rest view. The fix gives the rest view its own cancellation-aware deadline task. The previously failing rest completion/history test passed on the second device run (47.377 seconds, no failures). A separate foreground-expiry test then exposed an initially captured inactive scenePhase value in the long-lived root task. It now reads the current application state each tick. Both affected scenarios passed together in the fourth device result bundle: rest completion/history 46.785 seconds; foreground reminder presentation/close 30.198 seconds. Two tests, zero failures. Across the runs, all seven distinct scenarios have passing physical-device evidence.

Evidence result bundles on this Mac: `/private/tmp/LookFar-Device-01.xcresult`, `/private/tmp/LookFar-Device-02.xcresult`, and `/private/tmp/LookFar-Device-04.xcresult`. Named screenshots exported into `AppStore/Screenshots`; originals are retained. Completed rest, real history, and reminder presentation screenshots are refreshed from the passing fourth run.

The Release app and WidgetKit extension compiled and archived for arm64. The final archive is `build/LookFar-1.0.xcarchive`, signed with the owner's existing Apple Development identity and team. Deep/strict signature verification passed with system certificate access. The final Release app was installed and launched successfully on the physical iPhone at 17:48 KST. This is a development-signed archive, not an uploaded App Store distribution binary. Re-sign/validate for distribution through Xcode Organizer before upload.

## Remaining operational checks

- Foreground reminder presentation and closing after expiry passed on the fourth physical-device run. Visual inspection of `09-reminder-ko.png` confirms the genuine iOS banner titled LOOKFAR with the selected LF app icon and Korean reminder text. The device must remain unlocked during automated capture.
- Actual Lock Screen / Dynamic Island appearance, sound, Focus and permission-denied combinations still need user-visible checks under the desired phone settings. The extension runs on the iPhone, but that alone does not establish every presentation mode.
- Physical-device verification on this beta OS does not replace testing on the production iOS versions intended for release.
- Host the supplied privacy/support pages, complete App Store Connect metadata, and validate distribution signing. No upload or submission has been performed.
