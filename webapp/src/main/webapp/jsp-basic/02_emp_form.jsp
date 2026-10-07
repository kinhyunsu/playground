<%@ page contentType="text/html; charset=UTF-8" %>
<% String pageTitle = "JSP 기본 ② 사원 등록 / 수정 / 퇴사처리"; %>
<%@ include file="/common/top.jspf" %>
<%
    boolean isOracle = DB.ORACLE.equals(db);
    String now = isOracle ? "SYSDATE" : "GETDATE()";     // 현재시각 함수 차이
    String userId = "TESTER";                             // 실무에선 세션의 로그인 사용자

    String empNo = DB.nvl(request.getParameter("empNo"), "");
    String msg = null, error = null;

    // ==================================================================
    // POST: 저장 / 퇴사처리
    // ==================================================================
    if ("POST".equals(request.getMethod())) {
        String action = request.getParameter("action");
        String empNm  = DB.nvl(request.getParameter("empNm"), null);
        String deptCd = DB.nvl(request.getParameter("deptCd"), null);
        String posCd  = DB.nvl(request.getParameter("posCd"), null);
        String hireDt = DB.nvl(request.getParameter("hireDt"), "").replace("-", "");   // yyyy-MM-dd → yyyyMMdd
        String salStr = DB.nvl(request.getParameter("sal"), null);
        String email  = DB.nvl(request.getParameter("email"), null);

        Connection conn = null;
        PreparedStatement ps = null;
        CallableStatement cs = null;
        try {
            conn = DB.getConnection(db);
            conn.setAutoCommit(false);                    // ★ 트랜잭션 시작

            if ("delete".equals(action)) {
                ps = conn.prepareStatement(
                    "UPDATE TB_EMP SET USE_YN = 'N', UPD_ID = ?, UPD_DTM = " + now + " WHERE EMP_NO = ?");
                ps.setString(1, userId);
                ps.setString(2, empNo);
                ps.executeUpdate();
                msg = empNo + " 퇴사 처리되었습니다.";

            } else if (empNo.isEmpty()) {
                // ---- 신규: 프로시저로 사번 채번 (OUT 파라미터) ----
                //   JDBC 표준 escape 구문 {call 프로시저(?)} 은 MSSQL/Oracle 공통
                cs = conn.prepareCall("{call USP_GET_NEXT_EMP_NO(?)}");
                cs.registerOutParameter(1, Types.VARCHAR);
                cs.execute();
                empNo = cs.getString(1);

                ps = conn.prepareStatement(
                    "INSERT INTO TB_EMP (EMP_NO, EMP_NM, DEPT_CD, POS_CD, HIRE_DT, SAL, EMAIL, REG_ID, REG_DTM) " +
                    "VALUES (?, ?, ?, ?, ?, ?, ?, ?, " + now + ")");
                ps.setString(1, empNo);
                ps.setString(2, empNm);
                ps.setString(3, deptCd);
                ps.setString(4, posCd);
                ps.setString(5, hireDt.isEmpty() ? null : hireDt);
                if (salStr == null) ps.setNull(6, Types.NUMERIC); else ps.setLong(6, Long.parseLong(salStr));
                ps.setString(7, email);
                ps.setString(8, userId);
                ps.executeUpdate();
                msg = empNo + " 등록되었습니다.";

            } else {
                // ---- 수정 ----
                ps = conn.prepareStatement(
                    "UPDATE TB_EMP SET EMP_NM = ?, DEPT_CD = ?, POS_CD = ?, HIRE_DT = ?, SAL = ?, EMAIL = ?, " +
                    "       USE_YN = 'Y', UPD_ID = ?, UPD_DTM = " + now + " WHERE EMP_NO = ?");
                ps.setString(1, empNm);
                ps.setString(2, deptCd);
                ps.setString(3, posCd);
                ps.setString(4, hireDt.isEmpty() ? null : hireDt);
                if (salStr == null) ps.setNull(5, Types.NUMERIC); else ps.setLong(5, Long.parseLong(salStr));
                ps.setString(6, email);
                ps.setString(7, userId);
                ps.setString(8, empNo);
                int cnt = ps.executeUpdate();
                msg = cnt + "건 수정되었습니다.";
            }
            conn.commit();                                // ★ 커밋
        } catch (Exception e) {
            if (conn != null) try { conn.rollback(); } catch (SQLException ignore) { }   // ★ 롤백
            error = e.toString();
        } finally {
            DB.close(cs, ps, conn);
        }
    }

    // ==================================================================
    // GET: 상세 조회 + 콤보 데이터
    // ==================================================================
    Map<String, Object> emp = new HashMap<String, Object>();
    List<Map<String, Object>> depts = new ArrayList<Map<String, Object>>();
    List<Map<String, Object>> poses = new ArrayList<Map<String, Object>>();
    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    try {
        conn = DB.getConnection(db);
        if (!empNo.isEmpty()) {
            ps = conn.prepareStatement("SELECT * FROM TB_EMP WHERE EMP_NO = ?");
            ps.setString(1, empNo);
            rs = ps.executeQuery();
            List<Map<String, Object>> l = DB.toList(rs);
            if (!l.isEmpty()) emp = l.get(0);
            DB.close(rs, ps);
        }
        ps = conn.prepareStatement("SELECT DEPT_CD, DEPT_NM FROM TB_DEPT ORDER BY DEPT_CD");
        rs = ps.executeQuery();
        depts = DB.toList(rs);
        DB.close(rs, ps);

        ps = conn.prepareStatement("SELECT CD, CD_NM FROM TB_COMM_CODE WHERE GRP_CD = 'POS' AND USE_YN = 'Y' ORDER BY SORT_SEQ");
        rs = ps.executeQuery();
        poses = DB.toList(rs);
    } catch (Exception e) {
        error = (error == null ? "" : error + " / ") + e;
    } finally {
        DB.close(rs, ps, conn);
    }

    String hire = emp.get("HIRE_DT") == null ? "" : String.valueOf(emp.get("HIRE_DT"));
    if (hire.length() == 8) hire = hire.substring(0, 4) + "-" + hire.substring(4, 6) + "-" + hire.substring(6);
%>

<% if (msg != null)   { %><div class="box ok"><%= Html.esc(msg) %></div><% } %>
<% if (error != null) { %><div class="warn err"><%= Html.esc(error) %></div><% } %>

<form class="box" method="post" onsubmit="return check(this)">
  <input type="hidden" name="action" value="save">
  <table class="grid" style="width:auto">
    <tr><th>사번</th><td><input name="empNo" value="<%= Html.esc(emp.get("EMP_NO")) %>" readonly placeholder="저장 시 자동 채번"></td></tr>
    <tr><th>이름 *</th><td><input name="empNm" value="<%= Html.esc(emp.get("EMP_NM")) %>"></td></tr>
    <tr><th>부서</th><td>
      <select name="deptCd"><option value="">선택</option>
<%      for (Map<String, Object> d : depts) { %>
        <option value="<%= d.get("DEPT_CD") %>" <%= d.get("DEPT_CD").equals(emp.get("DEPT_CD")) ? "selected" : "" %>><%= Html.esc(d.get("DEPT_NM")) %></option>
<%      } %>
      </select></td></tr>
    <tr><th>직급</th><td>
      <select name="posCd"><option value="">선택</option>
<%      for (Map<String, Object> p : poses) { %>
        <option value="<%= p.get("CD") %>" <%= p.get("CD").equals(emp.get("POS_CD")) ? "selected" : "" %>><%= Html.esc(p.get("CD_NM")) %></option>
<%      } %>
      </select></td></tr>
    <tr><th>입사일</th><td><input type="date" name="hireDt" value="<%= hire %>"></td></tr>
    <tr><th>급여</th><td><input type="number" name="sal" value="<%= Html.esc(emp.get("SAL")) %>"></td></tr>
    <tr><th>이메일</th><td><input name="email" value="<%= Html.esc(emp.get("EMAIL")) %>"></td></tr>
    <tr><th>재직</th><td><%= "N".equals(emp.get("USE_YN")) ? "퇴사" : "재직" %></td></tr>
  </table>
  <div class="btns">
    <button type="submit">저장</button>
<%  if (!empNo.isEmpty()) { %>
    <button type="submit" onclick="this.form.action.value='delete'; return confirm('퇴사 처리할까요?')">퇴사처리</button>
<%  } %>
    <a href="01_emp_list.jsp">목록</a>
  </div>
</form>

<script>
function check(f) {
  if (f.action.value === 'save' && !f.empNm.value.trim()) {
    alert('이름은 필수입니다.');
    f.empNm.focus();
    return false;
  }
  return true;
}
</script>

<%@ include file="/common/bottom.jspf" %>
