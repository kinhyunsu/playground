<%@ page contentType="text/html; charset=UTF-8" %>
<% String pageTitle = "SQL 콘솔"; %>
<%@ include file="/common/top.jspf" %>
<%--
  브라우저에서 SQL 을 바로 실행하는 학습용 콘솔 (DBeaver 대용)
  - 상단 MSSQL / Oracle 버튼으로 대상 DB 전환
  - 자동커밋(auto-commit) 으로 실행됩니다. 연습 후 원복은 ./scripts/reset-db.sh
  - ★ 학습용입니다. 아무 SQL 이나 실행되므로 외부에 공개(public 포트)하지 마세요.
--%>
<%
    final int MAX_ROWS = 500;
    boolean isOracle = DB.ORACLE.equals(db);
    String sql = request.getParameter("sql");
    if (sql == null) {
        sql = isOracle
            ? "SELECT EMP_NO, EMP_NM, NVL(EMAIL, '-') AS EMAIL, TO_CHAR(SYSDATE, 'YYYY-MM-DD') AS TODAY\n  FROM TB_EMP\n WHERE ROWNUM <= 5"
            : "SELECT TOP 5 EMP_NO, EMP_NM, ISNULL(EMAIL, '-') AS EMAIL, CONVERT(VARCHAR(10), GETDATE(), 23) AS TODAY\n  FROM TB_EMP";
    }

    // 실행 결과: 결과셋(표) 또는 영향받은 행 수 메시지를 순서대로 담는다
    List<Object> results = new ArrayList<Object>();
    String error = null;
    long elapsed = 0;

    if ("POST".equals(request.getMethod()) && !sql.trim().isEmpty()) {
        String toRun = sql.trim();
        // Oracle JDBC 는 끝의 ; 를 허용하지 않음 (단, PL/SQL 블록은 END; 까지 필요)
        String head = toRun.toUpperCase();
        boolean plsql = head.startsWith("BEGIN") || head.startsWith("DECLARE") || head.matches("(?s)^CREATE\\s+(OR\\s+REPLACE\\s+)?(PROCEDURE|FUNCTION|TRIGGER|PACKAGE).*");
        if (toRun.endsWith("/")) toRun = toRun.substring(0, toRun.length() - 1).trim();
        if (isOracle && !plsql && toRun.endsWith(";")) toRun = toRun.substring(0, toRun.length() - 1);

        Connection conn = null; Statement st = null;
        long t0 = System.currentTimeMillis();
        try {
            conn = DB.getConnection(db);
            st = conn.createStatement();
            st.setMaxRows(MAX_ROWS);
            boolean isRs = st.execute(toRun);
            // MSSQL 은 한 번에 여러 문장/여러 결과셋이 올 수 있어서 반복
            for (int guard = 0; guard < 50; guard++) {
                if (isRs) {
                    ResultSet rs = st.getResultSet();
                    ResultSetMetaData md = rs.getMetaData();
                    List<String> cols = new ArrayList<String>();
                    for (int i = 1; i <= md.getColumnCount(); i++) cols.add(md.getColumnLabel(i));
                    List<List<String>> rows = new ArrayList<List<String>>();
                    while (rs.next()) {
                        List<String> r = new ArrayList<String>();
                        for (int i = 1; i <= cols.size(); i++) {
                            Object v = rs.getObject(i);
                            r.add(v == null ? null : v.toString());
                        }
                        rows.add(r);
                    }
                    rs.close();
                    Map<String, Object> table = new HashMap<String, Object>();
                    table.put("cols", cols);
                    table.put("rows", rows);
                    results.add(table);
                } else {
                    int cnt = st.getUpdateCount();
                    if (cnt == -1) break;                       // 더 이상 결과 없음
                    results.add(cnt + "건 처리되었습니다.");
                }
                isRs = st.getMoreResults();
            }
            if (results.isEmpty()) results.add("실행 완료");     // DDL, PL/SQL 블록 등
        } catch (Exception e) {
            error = e.getMessage();
        } finally {
            elapsed = System.currentTimeMillis() - t0;
            DB.close(st, conn);
        }
    }
%>
<form method="post" class="box" id="sqlForm">
  <textarea name="sql" id="sql" spellcheck="false"
            style="width:100%; height:220px; font:13px/1.4 Consolas, monospace"><%= Html.esc(sql) %></textarea>
  <div class="btns">
    <button type="submit">실행 (Ctrl+Enter)</button>
    <span style="color:#777">자동커밋 · 최대 <%= MAX_ROWS %>행 · 한 번에 한 문장 권장 (Oracle 은 한 문장만)</span>
  </div>
</form>

<% if (error != null) { %><div class="warn err"><%= Html.esc(error) %></div><% } %>
<% if ("POST".equals(request.getMethod()) && error == null) { %><p style="color:#777"><%= elapsed %> ms</p><% } %>

<%  for (Object r : results) {
        if (r instanceof String) { %><div class="box ok"><%= r %></div><%
        } else {
            Map<?, ?> t = (Map<?, ?>) r;
            List<?> cols = (List<?>) t.get("cols");
            List<?> rows = (List<?>) t.get("rows"); %>
<p><%= rows.size() %>행<%= rows.size() >= MAX_ROWS ? " (최대치까지만 표시)" : "" %></p>
<div style="overflow-x:auto">
<table class="grid">
  <tr><% for (Object c : cols) { %><th><%= Html.esc(c) %></th><% } %></tr>
<%          for (Object row : rows) { %>
  <tr><% for (Object v : (List<?>) row) { %><td><%= v == null ? "<i style='color:#aaa'>NULL</i>" : Html.esc(v) %></td><% } %></tr>
<%          } %>
</table>
</div>
<%      }
    } %>

<script>
document.getElementById('sql').addEventListener('keydown', function (e) {
  if (e.ctrlKey && e.key === 'Enter') document.getElementById('sqlForm').submit();
  if (e.key === 'Tab') {                         // 탭 키로 들여쓰기
    e.preventDefault();
    var s = this.selectionStart;
    this.value = this.value.slice(0, s) + '    ' + this.value.slice(this.selectionEnd);
    this.selectionStart = this.selectionEnd = s + 4;
  }
});
</script>

<%@ include file="/common/bottom.jspf" %>
