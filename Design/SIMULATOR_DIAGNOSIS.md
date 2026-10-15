# Simulator diagnosis, 2026-10-15

Observed host: iMac13,2, quad-core Intel Core i5, NVIDIA GeForce GTX 660M, Metal 2, macOS 15.7.7. Xcode 26.3 (17C529), iOS 26.3.1 simulator runtime.

The iOS 26 simulator delayed at `Waiting on System App`; its boot monitor eventually finished, but captures remained black or showed only a partial tab capsule. The app and its Live Activity extension both compiled successfully. Logs also contained missing simulator AppleColorEmoji font and first-frame measurement errors, which are observations rather than proof of the underlying GPU failure.

Apple identifies iMac13,2 as iMac (27-inch, Late 2012). Apple's Sequoia compatibility list does not include this model. A host graphics/runtime compatibility problem on this unsupported configuration is the leading explanation; the precise failing component has not been established. We did not change drivers, OS patches, runtimes, or system settings to try to repair it.

At the owner's request, simulator work was stopped and validation/capture moved to the connected physical iPhone 16 Pro. Actual-device screens rendered normally. This demonstrates that the black simulator captures were not reproduced on the iPhone; it does not prove a particular GPU diagnosis.

References:
- https://support.apple.com/108054
- https://support.apple.com/120282
- https://developer.apple.com/xcode/system-requirements/
