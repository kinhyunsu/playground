-- =============================================================
-- MSSQL: 테이블 / 프로시저
--   레거시에서 흔한 형태: TB_ 접두어, 대문자 컬럼, 등록자/수정자 컬럼
-- =============================================================
USE PLAYDB;
GO

IF OBJECT_ID(N'dbo.TB_EMP', N'U')       IS NOT NULL DROP TABLE dbo.TB_EMP;
IF OBJECT_ID(N'dbo.TB_DEPT', N'U')      IS NOT NULL DROP TABLE dbo.TB_DEPT;
IF OBJECT_ID(N'dbo.TB_COMM_CODE', N'U') IS NOT NULL DROP TABLE dbo.TB_COMM_CODE;
GO

-- 공통코드 (IBSheet 콤보에 자주 쓰임)
CREATE TABLE dbo.TB_COMM_CODE (
    GRP_CD      VARCHAR(20)    NOT NULL,
    CD          VARCHAR(20)    NOT NULL,
    CD_NM       NVARCHAR(100)  NOT NULL,
    SORT_SEQ    INT            NOT NULL DEFAULT 0,
    USE_YN      CHAR(1)        NOT NULL DEFAULT 'Y',
    CONSTRAINT PK_TB_COMM_CODE PRIMARY KEY (GRP_CD, CD)
);

-- 부서 (UP_DEPT_CD로 계층 구조 → 재귀 CTE 연습용)
CREATE TABLE dbo.TB_DEPT (
    DEPT_CD     VARCHAR(10)    NOT NULL,
    DEPT_NM     NVARCHAR(100)  NOT NULL,
    UP_DEPT_CD  VARCHAR(10)    NULL,
    USE_YN      CHAR(1)        NOT NULL DEFAULT 'Y',
    CONSTRAINT PK_TB_DEPT PRIMARY KEY (DEPT_CD)
);

-- 사원
CREATE TABLE dbo.TB_EMP (
    EMP_NO      VARCHAR(10)    NOT NULL,
    EMP_NM      NVARCHAR(50)   NOT NULL,
    DEPT_CD     VARCHAR(10)    NULL,
    POS_CD      VARCHAR(10)    NULL,          -- 공통코드 POS
    HIRE_DT     CHAR(8)        NULL,          -- 레거시에서 흔한 'YYYYMMDD' 문자열 날짜
    SAL         DECIMAL(12,0)  NULL,
    EMAIL       VARCHAR(100)   NULL,
    USE_YN      CHAR(1)        NOT NULL DEFAULT 'Y',
    REG_ID      VARCHAR(20)    NULL,
    REG_DTM     DATETIME       NOT NULL DEFAULT GETDATE(),
    UPD_ID      VARCHAR(20)    NULL,
    UPD_DTM     DATETIME       NULL,
    CONSTRAINT PK_TB_EMP PRIMARY KEY (EMP_NO)
);
GO

-- 사번 채번 프로시저 (레거시에서 자주 보는 MAX+1 방식)
CREATE OR ALTER PROCEDURE dbo.USP_GET_NEXT_EMP_NO
    @NEXT_EMP_NO VARCHAR(10) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT @NEXT_EMP_NO = 'E' + RIGHT('0000' + CAST(ISNULL(MAX(CAST(SUBSTRING(EMP_NO, 2, 9) AS INT)), 0) + 1 AS VARCHAR), 4)
      FROM dbo.TB_EMP WITH (UPDLOCK, HOLDLOCK);
END
GO

-- 부서별 급여 집계 프로시저 (결과셋 반환형)
CREATE OR ALTER PROCEDURE dbo.USP_DEPT_SAL_SUMMARY
    @USE_YN CHAR(1) = 'Y'
AS
BEGIN
    SET NOCOUNT ON;
    SELECT D.DEPT_CD, D.DEPT_NM,
           COUNT(E.EMP_NO)        AS EMP_CNT,
           ISNULL(SUM(E.SAL), 0)  AS SAL_SUM,
           ISNULL(AVG(E.SAL), 0)  AS SAL_AVG
      FROM dbo.TB_DEPT D
      LEFT JOIN dbo.TB_EMP E ON E.DEPT_CD = D.DEPT_CD AND E.USE_YN = @USE_YN
     GROUP BY D.DEPT_CD, D.DEPT_NM
     ORDER BY D.DEPT_CD;
END
GO
