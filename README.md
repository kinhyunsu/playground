# Legacy Playground — MSSQL · Oracle · JSP · IBSheet 7/8 학습 환경

회사 레거시 스택(**MSSQL**(주력) + **Oracle**(일부) + **JSP** + **IBSheet 7/8**)을
내 PC에서 직접 코드를 치며 연습하기 위한 환경입니다. Docker 하나로 전부 뜹니다.

```
 브라우저 ──► Tomcat 9 (JSP, :8080) ──JDBC──► MSSQL 2022 (:1433)
                    │                    └──► Oracle 23ai Free (:1521)
                    └─ IBSheet 7/8 (js, 직접 복사 필요)
```

## 1. 준비물

- **Docker Desktop** (Windows는 WSL2 백엔드) — 메모리 6GB 이상 할당 권장
- DB 클라이언트: **DBeaver** (MSSQL/Oracle 둘 다 됨, 무료) — 회사에서 SSMS / Orange / Toad 를 쓰면 그것도 OK
- 코드 편집기: IntelliJ / VS Code / Eclipse 아무거나
- JDK·Maven·Tomcat 설치는 **필요 없습니다** (컨테이너 안에서 빌드/실행)

> **Apple Silicon(M1~M4) Mac**: MSSQL 이미지가 x86 전용이라 Docker Desktop → Settings → General →
> *"Use Rosetta for x86_64/amd64 emulation"* 을 켜주세요.

## 2. 실행

```bash
git clone <이 저장소>
cd playground
docker compose up -d --build      # 처음엔 이미지 다운로드로 5~10분
docker compose ps                 # app 이 running 이면 OK
```

브라우저: **http://localhost:8080** → 첫 화면에서 두 DB 연결 상태(OK)를 확인하세요.

| 명령 | 설명 |
|---|---|
| `docker compose stop` / `start` | 중지 / 재시작 (데이터 유지) |
| `docker compose logs -f app` | Tomcat 로그 (JSP 컴파일 에러는 여기서 확인) |
| `./scripts/mssql.sh` | MSSQL 콘솔(sqlcmd) |
| `./scripts/oracle.sh` | Oracle 콘솔(SQL*Plus) |
| `./scripts/reset-db.sh` | DB를 샘플 데이터 상태로 초기화 |

## 3. 접속 정보

| | MSSQL | Oracle |
|---|---|---|
| Host / Port | localhost / 1433 | localhost / 1521 |
| DB / Service | `PLAYDB` | 서비스명 `FREEPDB1` |
| 학습 계정 | `play` / `Play!2345` | `play` / `play1234` |
| 관리자 | `sa` / `Playground!234` | `system` / `Playground1234` |
| JDBC URL | `jdbc:sqlserver://localhost:1433;databaseName=PLAYDB;encrypt=false` | `jdbc:oracle:thin:@//localhost:1521/FREEPDB1` |

DBeaver에서 MSSQL 접속 시 *Driver properties* 의 `trustServerCertificate=true` 를 켜면 SSL 경고가 사라집니다.

## 4. 폴더 구조

```
playground/
├── docker-compose.yml
├── db/
│   ├── mssql/   01_database.sql 02_schema.sql 03_data.sql   ← 최초 기동 시 자동 실행
│   └── oracle/  01_user.sql     02_schema.sql 03_data.sql
├── sql-practice/
│   ├── mssql/01_basics.sql      ← T-SQL 단골 문법 (DBeaver 에서 열어 실행)
│   ├── oracle/01_basics.sql     ← 같은 번호로 Oracle 문법 비교
│   └── exercises.md             ← 연습문제 10개 + 정답
├── scripts/                     ← 콘솔 접속 / DB 초기화
└── webapp/
    ├── Dockerfile, pom.xml
    ├── src/main/java/com/playground/   DB.java(커넥션), Json.java, Html.java  ← 최소한의 헬퍼
    └── src/main/webapp/                ← ★ 여기가 학습 공간 (수정 즉시 반영)
        ├── index.jsp
        ├── common/top.jspf, bottom.jspf     공통 include (DB 전환 포함)
        ├── jsp-basic/01~03                  JSP + JDBC 기본 (목록/페이징, CRUD, 프로시저)
        ├── api/                             IBSheet 용 조회/저장 JSON (7·8 공용)
        ├── ibsheet7/emp.jsp                 IBSheet7 사원관리 예제
        ├── ibsheet8/emp.jsp                 IBSheet8 사원관리 예제
        ├── practice/                        실습 과제 뼈대 (TODO 채우기)
        └── lib/ibsheet7, lib/ibsheet8       ★ IBSheet 파일을 직접 복사해 넣는 곳
```

**JSP/JS/CSS는 저장 → 브라우저 새로고침만 하면 반영**됩니다 (`webapp/src/main/webapp` 이 Tomcat ROOT로 마운트됨).
`src/main/java` 를 고쳤을 때만 `docker compose up -d --build app` 하세요.

## 5. IBSheet 라이브러리 넣기 (필수, 수동)

IBSheet는 (주)아이비리더스의 **상용 제품**이라 저장소에 들어 있지 않습니다.

1. 회사 프로젝트에서 IBSheet 폴더를 찾아 내용을 복사
   - IBSheet7 → `webapp/src/main/webapp/lib/ibsheet7/`
   - IBSheet8 → `webapp/src/main/webapp/lib/ibsheet8/`
2. `ibsheet7/emp.jsp`, `ibsheet8/emp.jsp` 상단의 `<script>` 목록을 **회사 화면의 include 와 똑같이** 맞추기
3. 라이선스(`ibleaders.js`)가 회사 도메인/IP 전용이면 localhost 에서 막힐 수 있습니다 →
   회사 IBSheet 담당자에게 개발용(localhost) 라이선스를 요청하거나, ibsheet.com 에서 평가판을 문의하세요.

`lib/ibsheet*/` 는 `.gitignore` 처리되어 있으니 **회사 소스/라이선스가 개인 GitHub에 올라가지 않습니다.**
라이브러리가 없어도 화면에 안내 메시지가 뜨고, 서버 쪽(`api/*.jsp`)은 그대로 연습할 수 있습니다.

## 6. 추천 학습 순서

1. **SQL** — `sql-practice/mssql/01_basics.sql` 과 `oracle/01_basics.sql` 을 DBeaver 에서 나란히 열고 한 블록씩 실행
2. **JSP 기본** — `jsp-basic/01_emp_list.jsp` : 상단 DB 버튼으로 MSSQL ↔ Oracle 을 바꿔가며 화면 하단의 실행 SQL 비교
3. **CRUD/트랜잭션** — `02_emp_form.jsp` : `setAutoCommit(false)` → `commit` / `rollback`, 프로시저 OUT 파라미터
4. **프로시저 결과셋** — `03_procedure.jsp` : MSSQL 결과셋 vs Oracle `SYS_REFCURSOR`
5. **IBSheet 서버 규약** — `api/emp_search.jsp`, `api/emp_save.jsp` 를 먼저 읽고 브라우저로 JSON 확인
6. **IBSheet 화면** — `ibsheet7/emp.jsp` → `ibsheet8/emp.jsp` (같은 기능이라 7↔8 차이가 잘 보임)
7. **실습** — http://localhost:8080/practice/ 의 과제 1~5, `sql-practice/exercises.md`

## 7. IBSheet 7 vs 8 핵심 차이 (예제 코드 기준)

| | IBSheet7 | IBSheet8 |
|---|---|---|
| 생성 | `createIBSheet2(el, "mySheet", w, h)` + `IBS_InitSheet(mySheet, initData)` | `sheet = IBSheet.create({id, el, options})` |
| 컬럼 키 | `SaveName` | `Name` |
| 필수값 | `KeyField: 1` | `Required: 1` |
| 편집 불가 | `Edit: 0` | `CanEdit: 0` |
| 콤보 | `Type:"Combo", ComboText:"사원\|대리", ComboCode:"10\|20"` | `Type:"Enum", Enum:"\|사원\|대리", EnumKeys:"\|10\|20"` (첫 글자 = 구분자) |
| 날짜 | `Type:"Date", Format:"Ymd"` | `Type:"Date", Format:"yyyy-MM-dd", DataFormat:"yyyyMMdd"` |
| 조회 | `DoSearch(url, param)` → `{"Data":[...]}` | `doSearch(url, param)` → `{"data":[...], "IO":{"Result":0}}` |
| 저장 데이터 | `GetSaveJson()` / `DoSave()` , 상태 `I/U/D` | `getSaveJson()` / `doSave()` , 상태 `Added/Changed/Deleted` |
| 저장 응답 | `{"Result":{"Code":0,"Message":""}}` | `{"IO":{"Result":0,"Message":""}}` (음수 = 실패) |
| 이벤트 | 전역 함수 `mySheet_OnSearchEnd(...)` | `options.Events: { onSearchFinish(evt) {...} }` |

> IBSheet는 버전·회사 공통 스크립트(래퍼 함수)에 따라 세부 옵션이 다를 수 있습니다.
> 회사 코드와 다르면 **회사 코드가 정답**이니 그 방식에 맞춰 예제를 고쳐보는 것도 좋은 연습입니다.

## 8. MSSQL vs Oracle 자주 헷갈리는 것

| 용도 | MSSQL | Oracle |
|---|---|---|
| NULL 대체 | `ISNULL(a, b)` | `NVL(a, b)` / `NVL2` |
| 문자열 연결 | `a + b` | `a \|\| b` |
| 현재 시각 | `GETDATE()` | `SYSDATE` |
| 날짜→문자 | `CONVERT(VARCHAR(8), d, 112)` | `TO_CHAR(d, 'YYYYMMDD')` |
| 문자→날짜 | `CONVERT(DATE, '20240101')` | `TO_DATE('20240101', 'YYYYMMDD')` |
| 상위 N | `SELECT TOP 10 ...` | `WHERE ROWNUM <= 10` (정렬은 서브쿼리 안에서!) |
| 조건 분기 | `CASE`, `IIF` | `CASE`, `DECODE` |
| 문자열 길이/자르기 | `LEN`, `SUBSTRING`, `CHARINDEX` | `LENGTH`, `SUBSTR`, `INSTR` |
| 계층 쿼리 | 재귀 CTE | `START WITH ... CONNECT BY PRIOR` |
| 문자열 집계 | `STRING_AGG` / `FOR XML PATH` | `LISTAGG ... WITHIN GROUP` |
| 채번 | `IDENTITY`, MAX+1 | `SEQUENCE.NEXTVAL` (롤백돼도 번호는 소모됨) |
| 빈 문자열 | `''` ≠ NULL | `''` = **NULL** |
| 한글 리터럴 | `N'홍길동'` (NVARCHAR) | `'홍길동'` |
| 트랜잭션 | 기본 자동커밋, `BEGIN TRAN` | DML 후 `COMMIT` 해야 반영 |
| 잠금 힌트 | `WITH (NOLOCK)` (레거시 단골) | 없음 (읽기는 기본적으로 안 막힘) |
| 프로시저 결과셋 | `SELECT` 그대로 반환 | `OUT SYS_REFCURSOR` |

## 9. 문제 해결

- **index 화면에서 Oracle 실패** — 첫 기동 시 DB 생성에 1~2분 걸립니다. `docker compose logs oracle` 에 `DATABASE IS READY TO USE!` 가 보이면 새로고침.
- **포트 충돌(1433/1521/8080)** — PC에 이미 설치된 MSSQL/Oracle/Tomcat 을 끄거나, `docker-compose.yml` 의 `ports` 왼쪽 숫자를 바꾸세요 (예: `"11433:1433"`).
- **JSP 수정했는데 500 에러** — `docker compose logs -f app` 에서 컴파일 에러 줄 번호 확인.
- **한글 깨짐** — JSP 맨 위 `<%@ page contentType="text/html; charset=UTF-8" %>` 확인, MSSQL 은 `N'...'` 사용.
- **처음부터 다시** — `./scripts/reset-db.sh`
