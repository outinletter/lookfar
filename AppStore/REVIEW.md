# Review preparation

Prepared 2026-11-16. Implementation guidance, not an approval or submission receipt.

## Review notes (English)

LookFar shows a small yellow dot in the Dynamic Island to remind the user to rest their eyes during long viewing sessions. No login or special access is required.

1. Use an iPhone with a Dynamic Island, Live Activities enabled, and an internet connection.
2. Choose the 5 min interval, turn on Look far and Blink, then tap Start signals.
3. Press Home or open another app. A Live Activity starts; the dot stays dark until the interval passes.
4. After 5 minutes the dot glows long twice (Look far). 2 min 30 sec later it flashes three times, twice (Blink). The pair repeats every 5 minutes.
5. Open LookFar and tap Stop signals to end the Live Activity and delete the session from the server.

How it works: the app starts a Live Activity with a push token and sends that token, the chosen signals and the interval to our server (Cloudflare Workers). The server sends ActivityKit push updates through APNs that turn the dot on and off. The app does not run in the background and uses no background modes.

On devices without a Dynamic Island (and iPad compatibility mode) the same dot and a short text appear in the Lock Screen Live Activity; the app explains this on screen.

The app measures elapsed time from Start and does not monitor Screen Time or eye movements. It makes no diagnosis, treatment or eyesight-improvement claims. No tracking, advertising, payment or third-party SDK.

## Guideline alignment

- 2.1: 시작·종료, 실시간 현황 꺼짐, 서버 연결 실패를 모두 화면에서 안내한다. 제출 전 서버가 배포되어 있어야 한다.
- 2.5.4: 백그라운드 모드를 쓰지 않는다. 신호는 ActivityKit 푸시로만 전달한다.
- 4.5.4: 푸시는 사용자가 시작한 Live Activity 갱신에만 쓰고 광고·홍보에 쓰지 않는다.
- 1.4.1: 의료적 효능을 주장하지 않는다.
- 5.1.1 / 5.1.2: 처리방침에 푸시 토큰 전송과 삭제 시점을 적었다. 추적 없음.

## Release requirements

- App ID `com.addvalue.lookfar`에 Push Notifications 기능이 켜져 있어야 한다(자동 서명이 처리). 확장 ID: `com.addvalue.lookfar.live`.
- `server/README.md`대로 Worker를 배포하고 `LookFar/RootView.swift`의 `Server.baseURL`을 실제 주소로 바꾼다.
- Release 아카이브는 운영 APNs를 쓴다. TestFlight 빌드로 실제 신호가 오는지 확인한 뒤 제출한다.
- 처리방침과 지원 페이지를 공개 HTTPS 주소에 올리고 App Store Connect에 입력한다.
- 스크린샷을 새 화면으로 다시 찍는다. `AppStore/Screenshots`와 `scripts/export_screenshots.py`는 예전 화면 기준이다.
- 연령 등급, 앱 개인정보, 카테고리, 가격 양식을 작성한다.
