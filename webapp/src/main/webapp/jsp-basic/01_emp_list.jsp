<%@ page contentType="text/html; charset=UTF-8" %>
<% String pageTitle = "JSP 기본 ① 사원 목록 / 검색 / 페이징"; %>
<%@ include file="/common/top.jspf" %>
<%
    // ------------------------------------------------------------------
    // 1. 파라미터 받기 (request.getParameter 는 항상 String 또는 null)
    // ------------------------------------------------------------------
    String empNm  = DB.nvl(request.getParameter("empNm"), "");
    String deptCd = DB.nvl(request.getParameter("deptCd"), "");
    String useYn  = DB.nvl(request.getParameter("useYn"), "Y");
    int pageNo    = Integer.parseInt(DB.nvl(request.getParameter("pageNo"), "1"));
    int pageSize  = 5;
    boolean isOracle = DB.ORACLE.equals(db);

    // ------------------------------------------------------------------
    // 2. 동적 WHERE 절 + 바인드 변수 목록
    //    절대 "... LIKE '%" + empNm + "%'" 처럼 문자열을 이어붙이지 마세요 (SQL Injection)
    // ------------------------------------------------------------------
    StringBuilder where = new StringBuilder(" WHERE E.USE_YN = ? ");
    List<Object> params = new ArrayList<Object>();
    params.add(useYn);
    if (!empNm.isEmpty()) {
        // 문자열 연결 연산자: MSSQL은 +, Oracle은 ||
        where.append(isOracle ? " AND E.EMP_NM LIKE '%' || ? || '%' "
                              : " AND E.EMP_NM LIKE '%' + ? + '%' ");
        params.add(empNm);
    }
    if (!deptCd.isEmpty()) {
        where.append(" AND E.DEPT_CD = ? ");
        params.add(deptCd);
    }

    // ------------------------------------------------------------------
    // 3. 목록 SQL - DB별 차이를 눈여겨 보세요
    // ------------------------------------------------------------------
    String select;
    if (isOracle) {
        select =
            "SELECT E.EMP_NO, E.EMP_NM, D.DEPT_NM, C.CD_NM AS POS_NM,\n" +
            "       SUBSTR(E.HIRE_DT,1,4)||'-'||SUBSTR(E.HIRE_DT,5,2)||'-'||SUBSTR(E.HIRE_DT,7,2) AS HIRE_DT,\n" +
            "       NVL(E.SAL, 0) AS SAL,\n" +
            "       NVL(E.EMAIL, '-') AS EMAIL,\n" +
            "       TO_CHAR(E.REG_DTM, 'YYYY-MM-DD HH24:MI:SS') AS REG_DTM\n" +
            "  FROM TB_EMP E\n" +
            "  LEFT JOIN TB_DEPT D      ON D.DEPT_CD = E.DEPT_CD\n" +
            "  LEFT JOIN TB_COMM_CODE C ON C.GRP_CD = 'POS' AND C.CD = E.POS_CD\n" + where;
    } else {
        select =
            "SELECT E.EMP_NO, E.EMP_NM, D.DEPT_NM, C.CD_NM AS POS_NM,\n" +
            "       CONVERT(VARCHAR(10), CONVERT(DATE, E.HIRE_DT), 23) AS HIRE_DT,\n" +
            "       ISNULL(E.SAL, 0) AS SAL,\n" +
            "       ISNULL(E.EMAIL, '-') AS EMAIL,\n" +
            "       CONVERT(VARCHAR(19), E.REG_DTM, 120) AS REG_DTM\n" +
            "  FROM TB_EMP E WITH (NOLOCK)\n" +                       // 레거시 MSSQL 단골 힌트
            "  LEFT JOIN TB_DEPT D      ON D.DEPT_CD = E.DEPT_CD\n" +
            "  LEFT JOIN TB_COMM_CODE C ON C.GRP_CD = 'POS' AND C.CD = E.POS_CD\n" + where;
    }

    int startRow = (pageNo - 1) * pageSize + 1;
    int endRow   = pageNo * pageSize;
    String pagingSql;
    if (isOracle) {
        // Oracle 전통 방식: ROWNUM 3중 쿼리 (12c+ 는 OFFSET n ROWS FETCH NEXT m ROWS ONLY 도 가능)
        pagingSql =
            "SELECT * FROM (\n" +
            "  SELECT ROWNUM AS RNUM, A.* FROM (\n" + select + "  ORDER BY E.EMP_NO\n" +
            "  ) A WHERE ROWNUM <= ?\n" +
            ") WHERE RNUM >= ?";
    } else {
        // MSSQL 2005+ 방식: ROW_NUMBER() (2012+ 는 OFFSET n ROWS FETCH NEXT m ROWS ONLY 도 가능)
        pagingSql =
            "SELECT * FROM (\n" +
            "  SELECT ROW_NUMBER() OVER (ORDER BY E.EMP_NO) AS RNUM,\n" +
            select.substring("SELECT ".length()) +
            ") A WHERE RNUM BETWEEN ? AND ?";
    }
    String countSql = "SELECT COUNT(*) FROM TB_EMP E" + where;

    // ------------------------------------------------------------------
    // 4. 실행: Connection → PreparedStatement → ResultSet → close
    // ------------------------------------------------------------------
    List<Map<String, Object>> list = new ArrayList<Map<String, Object>>();
    List<Map<String, Object>> depts = new ArrayList<Map<String, Object>>();
    int total = 0;
    String error = null;

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    try {
        conn = DB.getConnection(db);

        // 4-1. 전체 건수
        ps = conn.prepareStatement(countSql);
        for (int i = 0; i < params.size(); i++) ps.setObject(i + 1, params.get(i));
        rs = ps.executeQuery();
        if (rs.next()) total = rs.getInt(1);
        DB.close(rs, ps);

        // 4-2. 페이지 목록
        ps = conn.prepareStatement(pagingSql);
        int idx = 1;
        for (Object p : params) ps.setObject(idx++, p);
        if (isOracle) { ps.setInt(idx++, endRow); ps.setInt(idx++, startRow); }
        else          { ps.setInt(idx++, startRow); ps.setInt(idx++, endRow); }
        rs = ps.executeQuery();
        list = DB.toList(rs);
        DB.close(rs, ps);

        // 4-3. 부서 콤보
        ps = conn.prepareStatement("SELECT DEPT_CD, DEPT_NM FROM TB_DEPT WHERE USE_YN = 'Y' ORDER BY DEPT_CD");
        rs = ps.executeQuery();
        depts = DB.toList(rs);
    } catch (Exception e) {
        error = e.toString();
    } finally {
        DB.close(rs, ps, conn);
    }
    int lastPage = Math.max(1, (total + pageSize - 1) / pageSize);
%>

<form class="search" method="get">
  <label>이름 <input name="empNm" value="<%= Html.esc(empNm) %>"></label>
  <label>부서
    <select name="deptCd">
      <option value="">전체</option>
<%  for (Map<String, Object> d : depts) { %>
      <option value="<%= d.get("DEPT_CD") %>" <%= d.get("DEPT_CD").equals(deptCd) ? "selected" : "" %>><%= Html.esc(d.get("DEPT_NM")) %></option>
<%  } %>
    </select>
  </label>
  <label>재직
    <select name="useYn">
      <option value="Y" <%= "Y".equals(useYn) ? "selected" : "" %>>재직</option>
      <option value="N" <%= "N".equals(useYn) ? "selected" : "" %>>퇴사</option>
    </select>
  </label>
  <button type="submit">조회</button>
  <a href="02_emp_form.jsp">+ 신규 등록</a>
</form>

<% if (error != null) { %><div class="warn err"><%= Html.esc(error) %></div><% } %>

<p>총 <b><%= total %></b>건 (<%= pageNo %> / <%= lastPage %> 페이지)</p>
<table class="grid">
  <tr><th>No</th><th>사번</th><th>이름</th><th>부서</th><th>직급</th><th>입사일</th><th>급여</th><th>이메일</th><th>등록일시</th></tr>
<%  for (Map<String, Object> row : list) { %>
  <tr>
    <td class="c"><%= row.get("RNUM") %></td>
    <td class="c"><a href="02_emp_form.jsp?empNo=<%= row.get("EMP_NO") %>"><%= row.get("EMP_NO") %></a></td>
    <td><%= Html.esc(row.get("EMP_NM")) %></td>
    <td><%= Html.esc(row.get("DEPT_NM")) %></td>
    <td class="c"><%= Html.esc(row.get("POS_NM")) %></td>
    <td class="c"><%= row.get("HIRE_DT") %></td>
    <td class="num"><%= String.format("%,d", Long.parseLong(String.valueOf(row.get("SAL")))) %></td>
    <td><%= Html.esc(row.get("EMAIL")) %></td>
    <td class="c"><%= row.get("REG_DTM") %></td>
  </tr>
<%  } %>
<%  if (list.isEmpty()) { %><tr><td colspan="9" class="c">조회된 데이터가 없습니다.</td></tr><% } %>
</table>

<div class="paging">
<%  String q = "empNm=" + java.net.URLEncoder.encode(empNm, "UTF-8") + "&deptCd=" + deptCd + "&useYn=" + useYn;
    for (int p = 1; p <= lastPage; p++) {
        if (p == pageNo) { %><b><%= p %></b><% } else { %><a href="?<%= q %>&pageNo=<%= p %>"><%= p %></a><% }
    } %>
</div>

<h3>실행된 SQL (<%= db.toUpperCase() %>)</h3>
<div class="sql"><%= Html.esc(pagingSql) %>

-- 바인드 값: <%= Html.esc(params) %> + 페이지 범위 <%= startRow %> ~ <%= endRow %></div>
<p>상단에서 DB를 바꿔 SQL이 어떻게 달라지는지 비교해 보세요.</p>

<%@ include file="/common/bottom.jspf" %>
