# LookFar

Native SwiftUI iPhone app, iOS 17+. Bundle ID `com.addvalue.lookfar`, widget extension `com.addvalue.lookfar.live`, signing team `A7QB8PT33N`.

A single screen starts a Live Activity whose yellow dot in the Dynamic Island is switched on and off by ActivityKit pushes from a Cloudflare Worker (`server/`). The app uses no background modes.

- App: `LookFar/` (UI and session control in `RootView.swift`)
- Live Activity: `LookFarLive/`
- Signal server: `server/` (deployment in `server/README.md`)
- Store material: `AppStore/`, `Website/`

Regenerate the Xcode project with `python3 scripts/generate_project.py`.
