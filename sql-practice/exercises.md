# SQL 연습 문제

각 문제를 **MSSQL과 Oracle 양쪽에서** 풀어보세요. 정답은 맨 아래에 있습니다 (먼저 풀고 보기!).

| # | 문제 |
|---|------|
| 1 | 재직 중(USE_YN='Y')인 사원의 사번, 이름, 부서명, 직급명을 조회하세요. (부서/직급이 없어도 사원은 나와야 함) |
| 2 | 입사일(HIRE_DT, 'YYYYMMDD' 문자열)을 'YYYY.MM.DD' 형식으로, 근속연수와 함께 조회하세요. |
| 3 | 부서별 인원수와 평균 급여를 구하되, 인원이 2명 이상인 부서만 평균 급여 내림차순으로. |
| 4 | 각 부서에서 급여가 가장 높은 사원 1명씩 조회하세요. (분석함수 사용) |
| 5 | 이메일이 없는 사원은 '사번@play.local' 로 보이게 조회하세요. |
| 6 | 2015년 이전 입사자를 '시니어', 2015~2020 '미들', 이후 '주니어'로 분류해서 분류별 인원을 세세요. |
| 7 | '개발본부'(D200) 하위의 모든 부서(자기 자신 포함)에 속한 사원 목록을 조회하세요. (계층 쿼리) |
| 8 | 직급 공통코드에 '인턴'(코드 05, 정렬 0)을 MERGE로 넣고, 한 번 더 실행하면 이름만 '인턴사원'으로 바뀌게 하세요. |
| 9 | 퇴사자를 제외하고 급여 상위 3~5위를 조회하세요. (페이징 방식) |
| 10 | 부서별 사원 이름을 콤마로 이어 붙여 한 줄로 조회하세요. |

<details>
<summary>정답 보기 (MSSQL / Oracle)</summary>

```sql
-- 1. MSSQL / Oracle 공통 (ANSI JOIN)
SELECT E.EMP_NO, E.EMP_NM, D.DEPT_NM, C.CD_NM AS POS_NM
  FROM TB_EMP E
  LEFT JOIN TB_DEPT D      ON D.DEPT_CD = E.DEPT_CD
  LEFT JOIN TB_COMM_CODE C ON C.GRP_CD = 'POS' AND C.CD = E.POS_CD
 WHERE E.USE_YN = 'Y';
-- 1. Oracle 레거시 표기
SELECT E.EMP_NO, E.EMP_NM, D.DEPT_NM, C.CD_NM
  FROM TB_EMP E, TB_DEPT D, TB_COMM_CODE C
 WHERE E.DEPT_CD = D.DEPT_CD(+) AND C.GRP_CD(+) = 'POS' AND E.POS_CD = C.CD(+) AND E.USE_YN = 'Y';

-- 2. MSSQL
SELECT EMP_NM, FORMAT(CONVERT(DATE, HIRE_DT), 'yyyy.MM.dd') AS HIRE,
       DATEDIFF(YEAR, CONVERT(DATE, HIRE_DT), GETDATE()) AS YEARS FROM TB_EMP;
-- 2. Oracle
SELECT EMP_NM, TO_CHAR(TO_DATE(HIRE_DT, 'YYYYMMDD'), 'YYYY.MM.DD') AS HIRE,
       TRUNC(MONTHS_BETWEEN(SYSDATE, TO_DATE(HIRE_DT, 'YYYYMMDD')) / 12) AS YEARS FROM TB_EMP;

-- 3. 공통
SELECT DEPT_CD, COUNT(*) AS CNT, AVG(SAL) AS AVG_SAL
  FROM TB_EMP GROUP BY DEPT_CD HAVING COUNT(*) >= 2 ORDER BY AVG_SAL DESC;

-- 4. 공통
SELECT * FROM (
  SELECT E.*, ROW_NUMBER() OVER (PARTITION BY DEPT_CD ORDER BY SAL DESC) AS RN FROM TB_EMP E
) A WHERE RN = 1;

-- 5. MSSQL: ISNULL(EMAIL, EMP_NO + '@play.local')   Oracle: NVL(EMAIL, EMP_NO || '@play.local')

-- 6. 공통 (문자열 비교 가능: 'YYYYMMDD' 는 사전순 = 날짜순)
SELECT GRP, COUNT(*) FROM (
  SELECT CASE WHEN HIRE_DT < '20150101' THEN '시니어'
              WHEN HIRE_DT < '20210101' THEN '미들' ELSE '주니어' END AS GRP
    FROM TB_EMP) A
 GROUP BY GRP;

-- 7. MSSQL
WITH T AS (SELECT DEPT_CD FROM TB_DEPT WHERE DEPT_CD = 'D200'
           UNION ALL SELECT D.DEPT_CD FROM TB_DEPT D JOIN T ON D.UP_DEPT_CD = T.DEPT_CD)
SELECT E.* FROM TB_EMP E WHERE E.DEPT_CD IN (SELECT DEPT_CD FROM T);
-- 7. Oracle
SELECT E.* FROM TB_EMP E WHERE E.DEPT_CD IN (
  SELECT DEPT_CD FROM TB_DEPT START WITH DEPT_CD = 'D200' CONNECT BY PRIOR DEPT_CD = UP_DEPT_CD);

-- 8. sql-practice/*/01_basics.sql 의 10번 참고 (USING 절 값만 바꾸기)

-- 9. MSSQL
SELECT * FROM TB_EMP WHERE USE_YN = 'Y' ORDER BY SAL DESC OFFSET 2 ROWS FETCH NEXT 3 ROWS ONLY;
-- 9. Oracle (ROWNUM)
SELECT * FROM (SELECT ROWNUM RN, A.* FROM (SELECT * FROM TB_EMP WHERE USE_YN = 'Y' ORDER BY SAL DESC NULLS LAST) A
                WHERE ROWNUM <= 5) WHERE RN >= 3;
-- ※ 정렬 시 NULL 위치: MSSQL은 NULL이 가장 작은 값, Oracle은 가장 큰 값 (DESC면 맨 위!)

-- 10. MSSQL: STRING_AGG(EMP_NM, ',')        Oracle: LISTAGG(EMP_NM, ',') WITHIN GROUP (ORDER BY EMP_NM)
```
</details>
