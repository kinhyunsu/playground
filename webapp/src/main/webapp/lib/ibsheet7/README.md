# IBSheet7 라이브러리 넣는 곳

IBSheet는 (주)아이비리더스의 **상용 제품**이라 이 저장소에는 포함하지 않습니다 (`.gitignore` 처리됨).

## 넣는 방법
회사 프로젝트에서 IBSheet7 폴더를 찾아 **폴더 안 파일 전체**를 여기에 복사하세요.
보통 `/js/ibsheet/`, `/resources/ibsheet7/`, `/sheet/` 같은 경로에 있습니다.

```
lib/ibsheet7/
├── ibleaders.js      ← 라이선스 (도메인/IP 기반)
├── ibsheetinfo.js    ← 공통 설정, IBS_InitSheet 등
├── ibsheet.js        ← 본체
└── Main/ ...         ← 스타일/이미지 (버전마다 다름)
```

- 회사 화면에서 `<script src=...>` 하는 파일 목록/순서를 그대로 `ibsheet7/emp.jsp` 상단에 맞춰주세요.
- **라이선스(ibleaders.js)는 보통 회사 도메인/IP에 묶여 있어서 localhost에서는 동작하지 않을 수 있습니다.**
  이 경우 회사 IBSheet 담당자에게 개발용(localhost) 라이선스를 요청하거나, 아이비리더스 고객지원(ibsheet.com)에 평가판을 문의하세요.
- 회사 소스/라이선스를 개인 저장소에 올리지 마세요. 이 폴더는 git에서 제외되어 있습니다.
