# LookFar

## 1. 개요·기술 스택
- 화면을 오래 볼 때 다이내믹 아일랜드의 노란 점으로 눈 휴식 신호를 주는 iPhone 앱.
- SwiftUI, ActivityKit(Live Activity 푸시), iOS 17+. 상태는 `ObservableObject` + `@AppStorage`. 로컬 DB 없음.
- 신호 서버: Cloudflare Workers + Durable Objects(`server/`), APNs로 점을 켜고 끈다.
- Xcode 프로젝트는 `scripts/generate_project.py`로 생성한다. `pbxproj`를 직접 고치지 않는다.

## 2. 폴더 구조
```
LookFar/            앱 (RootView.swift: UI + BlinkController, Shared/: 앱·위젯 공용)
LookFarLive/        Live Activity 위젯 확장
server/             Cloudflare Worker 코드 (src/index.js), 설정은 루트 wrangler.toml
AppStore/ Website/  스토어 메타데이터, 심사 메모, 처리방침·지원 페이지
scripts/            프로젝트 생성 스크립트
```

## 3. 규칙
- 백그라운드 모드(무음 오디오 등)를 쓰지 않는다. 신호는 서버 푸시로만 보낸다.
- 화면은 단일 페이지, 다크 배경 + 파스텔 포인트(`Pastel`). 아일랜드 점은 노란색.
- 문자열은 `L("한국어", "English")`로 두 언어를 함께 쓴다.
- 의료적 효능을 주장하는 문구를 쓰지 않는다.
- 소스 파일을 추가·삭제하면 `generate_project.py`의 `appfiles`를 고치고 다시 생성한다.

## 4. 명령어·현재 상태
- 스킴 `LookFar`, 타깃 `LookFar`, `LookFarLive`. 테스트 타깃 없음.
- 기기 빌드: `xcodebuild -project LookFar.xcodeproj -scheme LookFar -destination 'id=00008140-0006089C30E3C01C' -derivedDataPath "$TMPDIR/dd" -allowProvisioningUpdates -quiet build`
- 설치: `xcrun devicectl device install app --device 03CDFC48-DEE7-52F3-B285-2EC105C649A4 <LookFar.app>`
- Worker: `https://lookfar.outinletter.workers.dev`, 배포는 `npx wrangler deploy`(루트) 또는 main 푸시 시 Cloudflare 빌드. Secret `APNS_KEY`, `APNS_KEY_ID` 등록됨.
- 현재: 푸시 방식 전환·배포 완료. 기기에서 실제 점등은 아직 확인 전.
- 다음: 기기에서 5분 간격 신호 확인 → TestFlight로 운영 푸시 확인 → 스크린샷 재촬영 → 처리방침·지원 페이지 공개.
