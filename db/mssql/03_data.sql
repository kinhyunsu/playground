-- =============================================================
-- MSSQL: 샘플 데이터 (한글 문자열은 N'' 접두어 필수!)
-- =============================================================
USE PLAYDB;
GO

INSERT INTO dbo.TB_COMM_CODE (GRP_CD, CD, CD_NM, SORT_SEQ) VALUES
 ('POS', '10', N'사원', 1), ('POS', '20', N'대리', 2), ('POS', '30', N'과장', 3),
 ('POS', '40', N'차장', 4), ('POS', '50', N'부장', 5),
 ('USE_YN', 'Y', N'사용', 1), ('USE_YN', 'N', N'미사용', 2);

INSERT INTO dbo.TB_DEPT (DEPT_CD, DEPT_NM, UP_DEPT_CD) VALUES
 ('D000', N'본사',        NULL),
 ('D100', N'경영지원본부', 'D000'),
 ('D110', N'인사팀',      'D100'),
 ('D120', N'재무팀',      'D100'),
 ('D200', N'개발본부',    'D000'),
 ('D210', N'플랫폼팀',    'D200'),
 ('D220', N'SI개발팀',    'D200'),
 ('D300', N'영업본부',    'D000'),
 ('D310', N'국내영업팀',  'D300');

INSERT INTO dbo.TB_EMP (EMP_NO, EMP_NM, DEPT_CD, POS_CD, HIRE_DT, SAL, EMAIL, REG_ID) VALUES
 ('E0001', N'김철수', 'D000', '50', '20050301', 98000000, 'cskim@play.local',   'SYSTEM'),
 ('E0002', N'이영희', 'D100', '50', '20070115', 91000000, 'yhlee@play.local',   'SYSTEM'),
 ('E0003', N'박민수', 'D110', '30', '20120702', 62000000, 'mspark@play.local',  'SYSTEM'),
 ('E0004', N'최지은', 'D110', '10', '20220103', 38000000, 'jechoi@play.local',  'SYSTEM'),
 ('E0005', N'정우성', 'D120', '40', '20100510', 74000000, 'wsjung@play.local',  'SYSTEM'),
 ('E0006', N'강하늘', 'D120', '20', '20180820', 49000000, 'hnkang@play.local',  'SYSTEM'),
 ('E0007', N'조현우', 'D200', '50', '20060411', 99000000, 'hwcho@play.local',   'SYSTEM'),
 ('E0008', N'윤서연', 'D210', '30', '20140303', 66000000, 'syyoon@play.local',  'SYSTEM'),
 ('E0009', N'임재현', 'D210', '20', '20190916', 52000000, 'jhlim@play.local',   'SYSTEM'),
 ('E0010', N'한소희', 'D210', '10', '20230102', 41000000, 'shhan@play.local',   'SYSTEM'),
 ('E0011', N'오세훈', 'D220', '40', '20110228', 77000000, 'shoh@play.local',    'SYSTEM'),
 ('E0012', N'서지훈', 'D220', '20', '20170612', 51000000, 'jhseo@play.local',   'SYSTEM'),
 ('E0013', N'신동엽', 'D220', '10', '20240401', 37000000, 'dyshin@play.local',  'SYSTEM'),
 ('E0014', N'권나라', 'D300', '50', '20080707', 93000000, 'nrkwon@play.local',  'SYSTEM'),
 ('E0015', N'황민호', 'D310', '30', '20130909', 64000000, 'mhhwang@play.local', 'SYSTEM'),
 ('E0016', N'송가인', 'D310', '20', '20200210', 48000000, NULL,                 'SYSTEM'),
 ('E0017', N'문채원', 'D310', '10', '20250105', 36000000, NULL,                 'SYSTEM'),
 ('E0018', N'배수지', 'D210', '10', '20250301', NULL,     'sjbae@play.local',   'SYSTEM');

UPDATE dbo.TB_EMP SET USE_YN = 'N' WHERE EMP_NO = 'E0016';   -- 퇴사자 1명
GO
