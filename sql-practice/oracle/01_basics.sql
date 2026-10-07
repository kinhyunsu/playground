/* =====================================================================
   Oracle 레거시 단골 문법 모음 - 한 문장씩 실행해 보세요.
   접속: localhost:1521 / 서비스명 FREEPDB1 / play / play1234
   ※ MSSQL 01_basics.sql 과 번호를 맞춰 두었으니 나란히 비교하세요.
   ===================================================================== */

-- 1. NULL 처리 : NVL / NVL2 / COALESCE      ※ Oracle은 '' (빈 문자열) = NULL !
SELECT EMP_NO, EMP_NM, NVL(EMAIL, '(없음)') AS EMAIL, NVL2(SAL, 'Y', 'N') AS HAS_SAL FROM TB_EMP;
SELECT COUNT(*) FROM DUAL WHERE '' IS NULL;     -- 1 이 나옴 (MSSQL은 0)

-- 2. 문자열 : || 연결, LENGTH, SUBSTR, INSTR, LPAD
SELECT EMP_NM || '(' || EMP_NO || ')'          AS NM_NO,
       LENGTH(EMP_NM)                          AS NM_LEN,
       SUBSTR(HIRE_DT, 1, 4)                   AS HIRE_YEAR,
       SUBSTR(EMAIL, 1, INSTR(EMAIL, '@') - 1) AS MAIL_ID,
       LPAD(SAL, 12, '0')                      AS PADDED
  FROM TB_EMP WHERE EMAIL IS NOT NULL;

-- 3. 날짜 : SYSDATE, TO_CHAR / TO_DATE, ADD_MONTHS, MONTHS_BETWEEN, 날짜 ± 숫자(일)
SELECT SYSDATE                                     AS NOW_DT,
       TO_CHAR(SYSDATE, 'YYYYMMDD')                AS YYYYMMDD,
       TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS')   AS YMDHMS,
       ADD_MONTHS(SYSDATE, -1)                     AS ONE_MONTH_AGO,
       SYSDATE - 7                                 AS ONE_WEEK_AGO,
       TRUNC(SYSDATE)                              AS TODAY_0H
  FROM DUAL;                                      -- FROM 없는 SELECT 는 DUAL 사용 (23ai 부터는 생략 가능)

SELECT EMP_NM, HIRE_DT,
       TRUNC(MONTHS_BETWEEN(SYSDATE, TO_DATE(HIRE_DT, 'YYYYMMDD')) / 12) AS YEARS
  FROM TB_EMP;

-- 4. 조건 : CASE / DECODE (레거시에 DECODE 매우 많음)
SELECT EMP_NM, SAL,
       CASE WHEN SAL >= 90000000 THEN 'A' WHEN SAL >= 60000000 THEN 'B' ELSE 'C' END AS GRADE,
       DECODE(USE_YN, 'Y', '재직', 'N', '퇴사', '?') AS STATUS
  FROM TB_EMP;

-- 5. 상위 N건 / 페이징
SELECT * FROM (SELECT * FROM TB_EMP ORDER BY SAL DESC) WHERE ROWNUM <= 5;    -- ORDER BY 후 ROWNUM (주의!)
SELECT * FROM TB_EMP ORDER BY EMP_NO OFFSET 5 ROWS FETCH NEXT 5 ROWS ONLY;   -- 12c+
SELECT * FROM (
  SELECT ROWNUM AS RN, A.* FROM (SELECT * FROM TB_EMP ORDER BY EMP_NO) A WHERE ROWNUM <= 10
) WHERE RN >= 6;                                                              -- 전통 3중 쿼리

-- 6. 분석 함수 (MSSQL과 동일)
SELECT DEPT_CD, EMP_NM, SAL,
       RANK()   OVER (PARTITION BY DEPT_CD ORDER BY SAL DESC) AS RNK,
       SUM(SAL) OVER (PARTITION BY DEPT_CD)                   AS DEPT_SUM
  FROM TB_EMP;

-- 7. 계층 조회 : CONNECT BY
SELECT LEVEL AS LVL, LPAD(' ', (LEVEL - 1) * 2) || DEPT_NM AS TREE, DEPT_CD, UP_DEPT_CD,
       SYS_CONNECT_BY_PATH(DEPT_NM, '>') AS PATH
  FROM TB_DEPT
 START WITH UP_DEPT_CD IS NULL
CONNECT BY PRIOR DEPT_CD = UP_DEPT_CD
 ORDER SIBLINGS BY DEPT_CD;

-- 8. 문자열 집계 : LISTAGG
SELECT DEPT_CD, LISTAGG(EMP_NM, ', ') WITHIN GROUP (ORDER BY EMP_NM) AS NAMES FROM TB_EMP GROUP BY DEPT_CD;

-- 9. 레거시 조인 문법 : (+) 외부조인  ← 오래된 소스에서 자주 봄
SELECT D.DEPT_NM, E.EMP_NM
  FROM TB_DEPT D, TB_EMP E
 WHERE D.DEPT_CD = E.DEPT_CD(+)          -- = LEFT JOIN TB_EMP E ON ...
 ORDER BY D.DEPT_CD;

-- 10. MERGE (USING DUAL 패턴)
MERGE INTO TB_COMM_CODE T
USING (SELECT 'POS' AS GRP_CD, '60' AS CD, '임원' AS CD_NM, 6 AS SORT_SEQ FROM DUAL) S
   ON (T.GRP_CD = S.GRP_CD AND T.CD = S.CD)
 WHEN MATCHED THEN UPDATE SET T.CD_NM = S.CD_NM, T.SORT_SEQ = S.SORT_SEQ
 WHEN NOT MATCHED THEN INSERT (GRP_CD, CD, CD_NM, SORT_SEQ) VALUES (S.GRP_CD, S.CD, S.CD_NM, S.SORT_SEQ);
SELECT * FROM TB_COMM_CODE WHERE GRP_CD = 'POS';
ROLLBACK;     -- ★ Oracle 은 DML 후 COMMIT 전까지 다른 세션에 안 보임 (DBeaver 자동커밋 설정 확인!)

-- 11. 시퀀스 / PL/SQL 익명 블록 / 프로시저
SELECT SEQ_EMP_NO.NEXTVAL FROM DUAL;
SELECT SEQ_EMP_NO.CURRVAL FROM DUAL;

DECLARE
    V_NO VARCHAR2(10);
BEGIN
    USP_GET_NEXT_EMP_NO(V_NO);
    DBMS_OUTPUT.PUT_LINE('다음 사번: ' || V_NO);   -- DBeaver: 출력 탭(Show server output) 켜기
END;
/

-- 12. 메타 정보 조회
SELECT * FROM USER_TABLES;
SELECT * FROM USER_TAB_COLUMNS WHERE TABLE_NAME = 'TB_EMP';
SELECT TEXT FROM USER_SOURCE WHERE NAME = 'USP_DEPT_SAL_SUMMARY' ORDER BY LINE;   -- 프로시저 소스
