-- =============================================================
-- Oracle: 학습용 사용자 생성 (컨테이너 최초 기동 시 SYS로 1회 실행)
-- =============================================================
ALTER SESSION SET CONTAINER = FREEPDB1;

CREATE USER play IDENTIFIED BY play1234
  DEFAULT TABLESPACE users QUOTA UNLIMITED ON users;

GRANT CONNECT, RESOURCE, CREATE VIEW, CREATE SYNONYM TO play;
