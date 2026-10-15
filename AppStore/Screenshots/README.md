# Actual iPhone screenshots

Captured directly on the owner's connected iPhone 16 Pro (iOS 27.2 beta) with XCTest. No generated UI or simulator screen is included in these submission folders.

At the owner's request, all actual-device screenshot images and their resized copies are local-only and ignored by Git. This repository includes the capture instructions, not the screenshot images.

- `Originals/ko-KR` and `Originals/en-US`: untouched actual-device captures, 1206 × 2622 pixels.
- `ko-KR/6.9-inch` and `en-US/6.9-inch`: copies resized to Apple's accepted 1320 × 2868 screenshot specification. These are resized real iPhone captures, not native captures from a 6.9-inch device. There is a negligible aspect-ratio adjustment (less than 0.1%).
- The source device status bar is retained. No fake battery, carrier, time, Dynamic Island, or notification is composited.
- Record screenshots contain only a break actually completed during the real-device test.

Screens: timer, custom minutes, active countdown, guided rest, completed rest, break history, settings, privacy, and reminder presentation where available. Korean and English have separate folders; choose the desired images in each App Store Connect locale. At most ten screenshots can be used per device-size/locale slot.

Recreate using `xcrun xcresulttool export attachments --path <result.xcresult> --output-path <export-dir>` followed by `python3 scripts/export_screenshots.py <export-dir>`.

Reference: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications
