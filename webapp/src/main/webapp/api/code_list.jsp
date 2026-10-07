<%@ page contentType="application/json; charset=UTF-8" trimDirectiveWhitespaces="true" %>
<%@ page import="java.sql.*, java.util.*, com.playground.DB, com.playground.Json" %>
<%--
  공통코드/부서 콤보 데이터
  GET /api/code_list.jsp?grpCd=POS      → [{"CD":"10","CD_NM":"사원"}, ...]
  GET /api/code_list.jsp?grpCd=DEPT     → 부서 테이블
--%>
<%
    String db = DB.normalize((String) session.getAttribute("db"));
    String grpCd = DB.nvl(request.getParameter("grpCd"), "POS");
    Connection conn = null; PreparedStatement ps = null; ResultSet rs = null;
    try {
        conn = DB.getConnection(db);
        if ("DEPT".equals(grpCd)) {
            ps = conn.prepareStatement("SELECT DEPT_CD AS CD, DEPT_NM AS CD_NM FROM TB_DEPT WHERE USE_YN = 'Y' ORDER BY DEPT_CD");
        } else {
            ps = conn.prepareStatement("SELECT CD, CD_NM FROM TB_COMM_CODE WHERE GRP_CD = ? AND USE_YN = 'Y' ORDER BY SORT_SEQ");
            ps.setString(1, grpCd);
        }
        rs = ps.executeQuery();
        out.print(Json.stringify(DB.toList(rs)));
    } catch (Exception e) {
        response.setStatus(500);
        out.print(Json.stringify(Collections.singletonMap("error", e.toString())));
    } finally {
        DB.close(rs, ps, conn);
    }
%>
