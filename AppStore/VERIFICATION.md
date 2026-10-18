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

## Build 2 — Shortcuts automation

2026-10-15, same physical iPhone. Result `/private/tmp/LookFar-Automation-02.xcresult`: six tests passed, zero failures, zero skipped. Five hosted tests execute the real App Intent perform methods: saved interval/start and duplicate preservation; explicit restart with one pending request; cancellation and persistence; refusal during a guided rest; repair of a missing pending notification. One UI test opens the automation guide and verifies its limitations. The first run's five action tests passed; its UI test failed because the navigation row was queried as a Button. The second run uses a type-independent row query and bounded scrolling and passed. Captures were visually checked locally in `/private/tmp/LookFarAutomationProof` and are not committed.

The app includes extracted App Intents metadata and Korean/English shortcut strings. App Intents use the same main-actor timer owner as the UI and LiveActivityIntent to allow optional activity creation without opening LookFar. These tests call perform directly; they do not establish an end-to-end user-created App Open automation. The user must select their apps and create that personal automation in Shortcuts. Verify an actual selected-app launch and background activity presentation on the user's device after setup. No automatic screen wake/lock reset or usage/gaze measurement is claimed.

Build 2 Release archive: `build/LookFar-1.0-build2.xcarchive`. Archive succeeded, deep/strict signature verification passed, and the app was installed on the physical iPhone at 18:23 KST. The prior build 1 archive remains untouched. No distribution upload or submission occurred.

## Build 3 — Main-screen window landscape

The timer card now uses the bundled 1536 × 1024 WindowLandscape image with its full 3:2 frame visible and Korean/English accessibility labels. The LF app icon and timer logic are unchanged. Release archive succeeded and deep/strict signature verification passed; archive: `build/LookFar-1.0-build3.xcarchive`. Added `test09WindowLandscape` for image visibility and timer button reachability/start/stop. The paired iPhone was unavailable during this change, so this new UI test and physical layout inspection have NOT run, and build 3 has NOT been installed. Refresh main-screen App Store screenshots from the updated real-device build before submission; existing screenshots depict the prior main illustration. No device screenshots are committed.
