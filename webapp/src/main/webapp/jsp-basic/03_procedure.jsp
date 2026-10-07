<%@ page contentType="text/html; charset=UTF-8" %>
<% String pageTitle = "JSP 기본 ③ 프로시저 결과셋 받기"; %>
<%@ include file="/common/top.jspf" %>
<%
    boolean isOracle = DB.ORACLE.equals(db);
    String useYn = DB.nvl(request.getParameter("useYn"), "Y");
    List<Map<String, Object>> list = new ArrayList<Map<String, Object>>();
    String error = null;
    String callSql;

    Connection conn = null;
    CallableStatement cs = null;
    ResultSet rs = null;
    try {
        conn = DB.getConnection(db);
        if (isOracle) {
            // Oracle: 결과셋을 OUT SYS_REFCURSOR 로 받는다
            callSql = "{call USP_DEPT_SAL_SUMMARY(?, ?)}";
            cs = conn.prepareCall(callSql);
            cs.setString(1, useYn);
            cs.registerOutParameter(2, Types.REF_CURSOR);   // ojdbc: OracleTypes.CURSOR 도 동일
            cs.execute();
            rs = (ResultSet) cs.getObject(2);
        } else {
            // MSSQL: 프로시저 안의 SELECT 결과가 그대로 ResultSet 으로 온다
            callSql = "{call USP_DEPT_SAL_SUMMARY(?)}";
            cs = conn.prepareCall(callSql);
            cs.setString(1, useYn);
            rs = cs.executeQuery();
        }
        list = DB.toList(rs);
    } catch (Exception e) {
        callSql = "";
        error = e.toString();
    } finally {
        DB.close(rs, cs, conn);
    }
%>
<form class="search">
  <label>재직구분
    <select name="useYn" onchange="this.form.submit()">
      <option value="Y" <%= "Y".equals(useYn) ? "selected" : "" %>>재직</option>
      <option value="N" <%= "N".equals(useYn) ? "selected" : "" %>>퇴사</option>
    </select></label>
</form>
<% if (error != null) { %><div class="warn err"><%= Html.esc(error) %></div><% } %>

<table class="grid" style="width:auto">
  <tr><th>부서코드</th><th>부서명</th><th>인원</th><th>급여합계</th><th>평균급여</th></tr>
<%  for (Map<String, Object> r : list) { %>
  <tr><td class="c"><%= r.get("DEPT_CD") %></td><td><%= Html.esc(r.get("DEPT_NM")) %></td>
      <td class="num"><%= r.get("EMP_CNT") %></td><td class="num"><%= r.get("SAL_SUM") %></td><td class="num"><%= r.get("SAL_AVG") %></td></tr>
<%  } %>
</table>

<h3>호출 방식 비교</h3>
<div class="sql">-- MSSQL
EXEC dbo.USP_DEPT_SAL_SUMMARY @USE_YN = 'Y';         -- SSMS/DBeaver 에서
{call USP_DEPT_SAL_SUMMARY(?)}                       -- JDBC: executeQuery() 로 결과셋

-- Oracle
VARIABLE rc REFCURSOR;                               -- SQL*Plus 에서
EXEC USP_DEPT_SAL_SUMMARY('Y', :rc);
PRINT rc;
{call USP_DEPT_SAL_SUMMARY(?, ?)}                    -- JDBC: OUT 파라미터를 REF_CURSOR 로 등록</div>

<%@ include file="/common/bottom.jspf" %>
