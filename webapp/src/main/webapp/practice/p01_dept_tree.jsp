<%@ page contentType="text/html; charset=UTF-8" %>
<% String pageTitle = "실습 1. 부서 트리 조회"; %>
<%@ include file="/common/top.jspf" %>
<%
    boolean isOracle = DB.ORACLE.equals(db);
    String sql;

    if (isOracle) {
        // TODO 1-1) Oracle 계층 쿼리를 작성하세요.
        //   - 결과 컬럼: LVL(깊이), DEPT_CD, DEPT_NM, UP_DEPT_CD
        //   - 힌트: START WITH UP_DEPT_CD IS NULL CONNECT BY PRIOR DEPT_CD = UP_DEPT_CD
        //           ORDER SIBLINGS BY DEPT_CD
        sql = "SELECT 1 AS LVL, DEPT_CD, DEPT_NM, UP_DEPT_CD FROM TB_DEPT ORDER BY DEPT_CD";
    } else {
        // TODO 1-2) MSSQL 재귀 CTE로 같은 결과를 만드세요.
        //   - 힌트: WITH T AS (SELECT 1 AS LVL, ..., CAST(DEPT_CD AS VARCHAR(100)) AS SORT_PATH
        //                       FROM TB_DEPT WHERE UP_DEPT_CD IS NULL
        //                     UNION ALL
        //                     SELECT T.LVL + 1, ..., CAST(T.SORT_PATH + '>' + D.DEPT_CD AS VARCHAR(100))
        //                       FROM TB_DEPT D JOIN T ON D.UP_DEPT_CD = T.DEPT_CD)
        //           SELECT ... FROM T ORDER BY SORT_PATH
        sql = "SELECT 1 AS LVL, DEPT_CD, DEPT_NM, UP_DEPT_CD FROM TB_DEPT ORDER BY DEPT_CD";
    }

    List<Map<String, Object>> list = new ArrayList<Map<String, Object>>();
    String error = null;
    Connection conn = null; PreparedStatement ps = null; ResultSet rs = null;
    try {
        conn = DB.getConnection(db);
        ps = conn.prepareStatement(sql);
        rs = ps.executeQuery();
        list = DB.toList(rs);
    } catch (Exception e) {
        error = e.toString();
    } finally {
        DB.close(rs, ps, conn);
    }
%>
<% if (error != null) { %><div class="warn err"><%= Html.esc(error) %></div><% } %>

<table class="grid" style="width:auto">
  <tr><th>LVL</th><th>부서</th><th>코드</th><th>상위</th></tr>
<%  for (Map<String, Object> r : list) {
        int lvl = Integer.parseInt(String.valueOf(r.get("LVL")));
        // TODO 1-3) LVL 만큼 들여쓰기해서 트리처럼 보이게 하세요. (예: "&nbsp;&nbsp;" 반복, └ 기호)
        String indent = "";
%>
  <tr><td class="c"><%= lvl %></td><td><%= indent %><%= Html.esc(r.get("DEPT_NM")) %></td>
      <td class="c"><%= r.get("DEPT_CD") %></td><td class="c"><%= r.get("UP_DEPT_CD") == null ? "" : r.get("UP_DEPT_CD") %></td></tr>
<%  } %>
</table>
<div class="sql"><%= Html.esc(sql) %></div>

<%@ include file="/common/bottom.jspf" %>
