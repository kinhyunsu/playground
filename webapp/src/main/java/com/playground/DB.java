package com.playground;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * JSP에서 쓰는 최소한의 JDBC 헬퍼.
 *
 * 실무 레거시에서는 보통 JNDI DataSource(context.xml) + 커넥션 풀을 쓰지만,
 * 학습용으로는 DriverManager 직접 연결이 흐름을 이해하기 쉽습니다.
 *
 * 사용 예 (JSP):
 *   Connection conn = DB.getConnection("mssql");   // 또는 "oracle"
 */
public final class DB {

    public static final String MSSQL = "mssql";
    public static final String ORACLE = "oracle";

    private DB() {}

    /** "mssql" / "oracle" 외의 값은 mssql로 처리합니다. */
    public static String normalize(String db) {
        return ORACLE.equalsIgnoreCase(db) ? ORACLE : MSSQL;
    }

    public static Connection getConnection(String db) throws SQLException {
        if (ORACLE.equals(normalize(db))) {
            return DriverManager.getConnection(
                    env("ORACLE_URL", "jdbc:oracle:thin:@//localhost:1521/FREEPDB1"),
                    env("ORACLE_USER", "play"),
                    env("ORACLE_PASSWORD", "play1234"));
        }
        return DriverManager.getConnection(
                env("MSSQL_URL", "jdbc:sqlserver://localhost:1433;databaseName=PLAYDB;encrypt=false"),
                env("MSSQL_USER", "play"),
                env("MSSQL_PASSWORD", "Play!2345"));
    }

    /**
     * ResultSet → List&lt;Map&gt;. 컬럼명은 대문자 그대로 키가 됩니다 (EMP_NO, EMP_NM ...).
     * IBSheet 컬럼의 SaveName/Name 을 DB 컬럼명과 맞추면 그대로 JSON으로 내려줄 수 있습니다.
     */
    public static List<Map<String, Object>> toList(ResultSet rs) throws SQLException {
        List<Map<String, Object>> list = new ArrayList<Map<String, Object>>();
        ResultSetMetaData md = rs.getMetaData();
        int cnt = md.getColumnCount();
        while (rs.next()) {
            Map<String, Object> row = new LinkedHashMap<String, Object>();
            for (int i = 1; i <= cnt; i++) {
                Object v = rs.getObject(i);
                if (v instanceof Timestamp) {
                    v = v.toString().substring(0, 19);       // yyyy-MM-dd HH:mm:ss
                } else if (v instanceof java.math.BigDecimal) {
                    v = ((java.math.BigDecimal) v).stripTrailingZeros().toPlainString();
                } else if (v != null && !(v instanceof String) && !(v instanceof Number)) {
                    v = v.toString();                         // Oracle DATE, TIMESTAMP 등
                }
                row.put(md.getColumnLabel(i).toUpperCase(), v);
            }
            list.add(row);
        }
        return list;
    }

    /** close 순서: ResultSet → Statement → Connection. null 이어도 안전. */
    public static void close(AutoCloseable... resources) {
        for (AutoCloseable r : resources) {
            if (r == null) continue;
            try { r.close(); } catch (Exception ignore) { }
        }
    }

    /** null/공백 → 기본값 (request.getParameter 처리에 사용) */
    public static String nvl(String s, String def) {
        return (s == null || s.trim().isEmpty()) ? def : s.trim();
    }

    private static String env(String key, String def) {
        String v = System.getenv(key);
        return (v == null || v.isEmpty()) ? def : v;
    }
}
