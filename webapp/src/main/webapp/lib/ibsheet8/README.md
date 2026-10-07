# IBSheet8 라이브러리 넣는 곳

IBSheet는 (주)아이비리더스의 **상용 제품**이라 이 저장소에는 포함하지 않습니다 (`.gitignore` 처리됨).

## 넣는 방법
회사 프로젝트(또는 ibsheet.com 에서 받은 평가판)의 IBSheet8 폴더 내용을 여기에 복사하세요.

```
lib/ibsheet8/
├── ibsheet.js         ← 본체
├── ibleaders.js       ← 라이선스
├── locale/ko.js       ← 한국어 메시지
├── css/default/main.css
└── plugins/ ...       ← (선택) 엑셀, 공통 플러그인 등
```

- 회사 화면의 include 목록/순서를 그대로 `ibsheet8/emp.jsp` 상단에 맞춰주세요.
- 라이선스가 도메인/IP에 묶여 있으면 localhost에서 동작하지 않을 수 있습니다 →
  담당자에게 개발용 라이선스를 요청하거나 아이비리더스 평가판을 이용하세요.
- 회사 소스/라이선스를 개인 저장소에 올리지 마세요. 이 폴더는 git에서 제외되어 있습니다.
