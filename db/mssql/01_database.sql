-- =============================================================
-- MSSQL: 데이터베이스 / 로그인 / 사용자 생성
--   (재실행해도 안전하도록 IF NOT EXISTS 처리)
-- =============================================================
IF DB_ID(N'PLAYDB') IS NULL
    CREATE DATABASE PLAYDB COLLATE Korean_Wansung_CI_AS;
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'play')
    CREATE LOGIN play WITH PASSWORD = N'Play!2345', DEFAULT_DATABASE = PLAYDB, CHECK_POLICY = OFF;
GO

USE PLAYDB;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'play')
BEGIN
    CREATE USER play FOR LOGIN play;
    ALTER ROLE db_owner ADD MEMBER play;
END
GO
