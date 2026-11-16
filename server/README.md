# LookFar signal server (Cloudflare Worker)

정해진 간격마다 APNs 푸시로 Live Activity의 노란 점을 켜고 끈다.

## 배포

```bash
cd server
npx wrangler login
npx wrangler secret put APNS_KEY_ID   # Apple Developer > Keys 의 Key ID
npx wrangler secret put APNS_KEY      # .p8 파일 내용 전체 붙여 넣기
npx wrangler deploy
```

배포 후 출력되는 `https://lookfar.<계정>.workers.dev` 주소를
`LookFar/RootView.swift` 의 `Server.baseURL` 에 넣는다.

## API

- `POST /session/<uuid>` `{token, modes, minutes, sandbox}` 세션 시작. `modes` 없이 보내면 토큰만 갱신.
- `DELETE /session/<uuid>` 세션 종료와 저장 값 삭제.

깜빡임 타이밍은 `src/index.js` 의 `PATTERNS` 에서 조정한다. 세션은 8시간 뒤 자동 삭제된다.
