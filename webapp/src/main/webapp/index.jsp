<%@ page contentType="text/html; charset=UTF-8" %>
<% String pageTitle = "시작하기"; %>
<%@ include file="/common/top.jspf" %>

<h2>DB 연결 상태</h2>
<table class="grid" style="width:auto">
  <tr><th>DB</th><th>상태</th><th>버전</th></tr>
<%
    String[][] checks = {
        { DB.MSSQL,  "SELECT @@VERSION" },
        { DB.ORACLE, "SELECT BANNER FROM V$VERSION WHERE ROWNUM = 1" }
    };
    for (String[] c : checks) {
        Connection conn = null; Statement st = null; ResultSet rs = null;
        String status, ver = "";
        try {
            conn = DB.getConnection(c[0]);
            st = conn.createStatement();
            rs = st.executeQuery(c[1]);
            if (rs.next()) ver = rs.getString(1).split("\n")[0];
            status = "<span class='ok'>OK</span>";
        } catch (Exception e) {
            status = "<span class='err'>실패</span> " + e.getMessage();
        } finally {
            DB.close(rs, st, conn);
        }
%>
  <tr><td><%= c[0].toUpperCase() %></td><td><%= status %></td><td><%= ver %></td></tr>
<%  } %>
</table>
<p>Oracle은 첫 기동 때 1~2분 정도 걸립니다. 실패로 나오면 잠시 뒤 새로고침하세요.</p>

<h2>학습 순서</h2>
<ol>
  <li><a href="jsp-basic/01_emp_list.jsp">JSP 기본 ① 목록/검색/페이징</a> — 스크립틀릿, PreparedStatement, MSSQL vs Oracle 페이징</li>
  <li><a href="jsp-basic/02_emp_form.jsp">JSP 기본 ② 등록/수정/삭제</a> — form POST, 트랜잭션, 프로시저 OUT 파라미터</li>
  <li><a href="jsp-basic/03_procedure.jsp">JSP 기본 ③ 프로시저 결과셋</a> — MSSQL 결과셋 vs Oracle SYS_REFCURSOR</li>
  <li><a href="ibsheet7/emp.jsp">IBSheet7 사원관리</a> — createIBSheet2, InitColumns, DoSearch, GetSaveJson</li>
  <li><a href="ibsheet8/emp.jsp">IBSheet8 사원관리</a> — IBSheet.create, doSearch, doSave</li>
  <li><a href="practice/">실습 과제</a> — 직접 만들어보기</li>
</ol>

<p>상단의 <b>MSSQL / Oracle</b> 버튼으로 모든 화면의 DB를 전환할 수 있습니다.
같은 화면이 두 DB에서 어떤 SQL 차이로 동작하는지 비교해 보세요.</p>

<%@ include file="/common/bottom.jspf" %>
