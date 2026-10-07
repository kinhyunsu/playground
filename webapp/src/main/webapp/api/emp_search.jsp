<%@ page contentType="application/json; charset=UTF-8" trimDirectiveWhitespaces="true" %>
<%@ page import="java.sql.*, java.util.*, com.playground.DB, com.playground.Json" %>
<%--
  IBSheet 조회용 JSON  (IBSheet7 / 8 공용, ver 파라미터로 응답 형식 구분)

  IBSheet7 (DoSearch)  → {"Data":[{...},{...}]}
  IBSheet8 (doSearch)  → {"data":[{...},{...}], "IO":{"Result":0,"Message":""}}

  ※ 행 객체의 키(EMP_NO, EMP_NM...)가 시트 컬럼의 SaveName(7) / Name(8)과 같아야 값이 들어갑니다.
--%>
<%
    String db     = DB.normalize((String) session.getAttribute("db"));
    String ver    = DB.nvl(request.getParameter("ver"), "8");
    String empNm  = DB.nvl(request.getParameter("empNm"), "");
    String deptCd = DB.nvl(request.getParameter("deptCd"), "");
    String useYn  = DB.nvl(request.getParameter("useYn"), "");
    boolean isOracle = DB.ORACLE.equals(db);

    StringBuilder sql = new StringBuilder(
        "SELECT EMP_NO, EMP_NM, DEPT_CD, POS_CD, HIRE_DT, SAL, EMAIL, USE_YN FROM TB_EMP WHERE 1 = 1 ");
    List<String> params = new ArrayList<String>();
    if (!empNm.isEmpty())  { sql.append(isOracle ? "AND EMP_NM LIKE '%' || ? || '%' " : "AND EMP_NM LIKE '%' + ? + '%' "); params.add(empNm); }
    if (!deptCd.isEmpty()) { sql.append("AND DEPT_CD = ? "); params.add(deptCd); }
    if (!useYn.isEmpty())  { sql.append("AND USE_YN = ? ");  params.add(useYn); }
    sql.append("ORDER BY EMP_NO");

    Map<String, Object> res = new LinkedHashMap<String, Object>();
    Connection conn = null; PreparedStatement ps = null; ResultSet rs = null;
    try {
        conn = DB.getConnection(db);
        ps = conn.prepareStatement(sql.toString());
        for (int i = 0; i < params.size(); i++) ps.setString(i + 1, params.get(i));
        rs = ps.executeQuery();
        List<Map<String, Object>> rows = DB.toList(rs);

        if ("7".equals(ver)) {
            res.put("Data", rows);
        } else {
            res.put("data", rows);
            res.put("IO", io(0, ""));
        }
    } catch (Exception e) {
        if ("7".equals(ver)) {
            res.put("Result", result7(-1, e.getMessage()));
        } else {
            res.put("IO", io(-1, e.getMessage()));
        }
    } finally {
        DB.close(rs, ps, conn);
    }
    out.print(Json.stringify(res));
%>
<%!
    static Map<String, Object> io(int result, String message) {
        Map<String, Object> m = new LinkedHashMap<String, Object>();
        m.put("Result", result);
        m.put("Message", message);
        return m;
    }
    static Map<String, Object> result7(int code, String message) {
        Map<String, Object> m = new LinkedHashMap<String, Object>();
        m.put("Code", code);
        m.put("Message", message);
        return m;
    }
%>
