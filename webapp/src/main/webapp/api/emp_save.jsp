<%@ page contentType="application/json; charset=UTF-8" trimDirectiveWhitespaces="true" %>
<%@ page import="java.sql.*, java.util.*, com.playground.DB, com.playground.Json, com.google.gson.*" %>
<%--
  IBSheet 저장 처리 (IBSheet7 / 8 공용)

  [요청] 두 가지 방식을 모두 받습니다.
    A) JSON 본문 (Content-Type: application/json)
         {"data":[{"STATUS":"Added","EMP_NM":"홍길동",...}, ...]}      ← IBSheet8 getSaveJson()
         {"data":[{"sStatus":"I","EMP_NM":"홍길동",...}, ...]}         ← IBSheet7 GetSaveJson()
    B) form 파라미터 (IBSheet7 DoSave 기본 방식)
         sStatus=I&EMP_NM=홍길동&...&sStatus=U&EMP_NM=...   → request.getParameterValues("컬럼명")

  [행 상태값]  IBSheet7: I / U / D      IBSheet8: Added / Changed / Deleted
     → 첫 글자로 판단 (I,A = 입력 / U,C = 수정 / D = 삭제)

  [응답]
    IBSheet7 → {"Result":{"Code":0,"Message":"..."}}     (Code < 0 이면 실패)
    IBSheet8 → {"IO":{"Result":0,"Message":"..."}}       (Result < 0 이면 실패)
--%>
<%
    String db  = DB.normalize((String) session.getAttribute("db"));
    String ver = DB.nvl(request.getParameter("ver"), "8");
    boolean isOracle = DB.ORACLE.equals(db);
    String now = isOracle ? "SYSDATE" : "GETDATE()";
    String userId = "TESTER";

    // ---------------------------------------------------------------
    // 1. 요청 → List<Map> 로 통일
    // ---------------------------------------------------------------
    List<Map<String, String>> rows = new ArrayList<Map<String, String>>();
    String contentType = String.valueOf(request.getContentType());
    if (contentType.startsWith("application/json")) {
        JsonObject body = Json.readBody(request);
        JsonArray arr = body.has("data") ? body.getAsJsonArray("data")
                      : body.has("Data") ? body.getAsJsonArray("Data") : new JsonArray();
        for (JsonElement el : arr) {
            JsonObject o = el.getAsJsonObject();
            Map<String, String> row = new HashMap<String, String>();
            for (Map.Entry<String, JsonElement> en : o.entrySet()) {
                row.put(en.getKey(), en.getValue().isJsonNull() ? null : en.getValue().getAsString());
            }
            rows.add(row);
        }
    } else {
        String[] status = request.getParameterValues("sStatus");
        String[] cols = { "EMP_NO", "EMP_NM", "DEPT_CD", "POS_CD", "HIRE_DT", "SAL", "EMAIL", "USE_YN" };
        if (status != null) {
            for (int i = 0; i < status.length; i++) {
                Map<String, String> row = new HashMap<String, String>();
                row.put("sStatus", status[i]);
                for (String c : cols) {
                    String[] v = request.getParameterValues(c);
                    row.put(c, (v != null && v.length > i) ? v[i] : null);
                }
                rows.add(row);
            }
        }
    }

    // ---------------------------------------------------------------
    // 2. 한 트랜잭션으로 저장 (한 행이라도 실패하면 전체 롤백)
    // ---------------------------------------------------------------
    int code = 0;
    String message;
    int ins = 0, upd = 0, del = 0;
    Connection conn = null;
    PreparedStatement psIns = null, psUpd = null, psDel = null;
    CallableStatement csNo = null;
    try {
        conn = DB.getConnection(db);
        conn.setAutoCommit(false);
        psIns = conn.prepareStatement(
            "INSERT INTO TB_EMP (EMP_NO, EMP_NM, DEPT_CD, POS_CD, HIRE_DT, SAL, EMAIL, USE_YN, REG_ID, REG_DTM) " +
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, " + now + ")");
        psUpd = conn.prepareStatement(
            "UPDATE TB_EMP SET EMP_NM = ?, DEPT_CD = ?, POS_CD = ?, HIRE_DT = ?, SAL = ?, EMAIL = ?, USE_YN = ?, " +
            "UPD_ID = ?, UPD_DTM = " + now + " WHERE EMP_NO = ?");
        psDel = conn.prepareStatement("DELETE FROM TB_EMP WHERE EMP_NO = ?");
        csNo  = conn.prepareCall("{call USP_GET_NEXT_EMP_NO(?)}");
        csNo.registerOutParameter(1, Types.VARCHAR);

        for (Map<String, String> r : rows) {
            String st = r.containsKey("STATUS") ? r.get("STATUS") : r.get("sStatus");
            char s = (st == null || st.isEmpty()) ? ' ' : Character.toUpperCase(st.charAt(0));

            if (s == 'I' || s == 'A') {
                if (isBlank(r.get("EMP_NM"))) throw new IllegalArgumentException("이름은 필수입니다.");
                csNo.execute();
                String newNo = csNo.getString(1);
                psIns.setString(1, newNo);
                psIns.setString(2, r.get("EMP_NM"));
                psIns.setString(3, blankToNull(r.get("DEPT_CD")));
                psIns.setString(4, blankToNull(r.get("POS_CD")));
                psIns.setString(5, dateOnly(r.get("HIRE_DT")));
                setNum(psIns, 6, r.get("SAL"));
                psIns.setString(7, blankToNull(r.get("EMAIL")));
                psIns.setString(8, isBlank(r.get("USE_YN")) ? "Y" : r.get("USE_YN"));
                psIns.setString(9, userId);
                psIns.executeUpdate();
                ins++;
            } else if (s == 'U' || s == 'C') {
                psUpd.setString(1, r.get("EMP_NM"));
                psUpd.setString(2, blankToNull(r.get("DEPT_CD")));
                psUpd.setString(3, blankToNull(r.get("POS_CD")));
                psUpd.setString(4, dateOnly(r.get("HIRE_DT")));
                setNum(psUpd, 5, r.get("SAL"));
                psUpd.setString(6, blankToNull(r.get("EMAIL")));
                psUpd.setString(7, isBlank(r.get("USE_YN")) ? "Y" : r.get("USE_YN"));
                psUpd.setString(8, userId);
                psUpd.setString(9, r.get("EMP_NO"));
                upd += psUpd.executeUpdate();
            } else if (s == 'D') {
                psDel.setString(1, r.get("EMP_NO"));
                del += psDel.executeUpdate();
            }
            // 그 외(R: 조회 상태 등)는 무시
        }
        conn.commit();
        message = "저장되었습니다. (입력 " + ins + " / 수정 " + upd + " / 삭제 " + del + ")";
    } catch (Exception e) {
        if (conn != null) try { conn.rollback(); } catch (SQLException ignore) { }
        code = -1;
        message = "저장 실패: " + e.getMessage();
    } finally {
        DB.close(csNo, psIns, psUpd, psDel, conn);
    }

    Map<String, Object> inner = new LinkedHashMap<String, Object>();
    Map<String, Object> res = new LinkedHashMap<String, Object>();
    if ("7".equals(ver)) {
        inner.put("Code", code);
        inner.put("Message", message);
        res.put("Result", inner);
    } else {
        inner.put("Result", code);
        inner.put("Message", message);
        res.put("IO", inner);
    }
    out.print(Json.stringify(res));
%>
<%!
    static boolean isBlank(String s) { return s == null || s.trim().isEmpty(); }
    static String blankToNull(String s) { return isBlank(s) ? null : s.trim(); }
    /** "2024-01-02", "20240102" 어느 쪽이 와도 yyyyMMdd 로 */
    static String dateOnly(String s) {
        if (isBlank(s)) return null;
        String d = s.replaceAll("[^0-9]", "");
        return d.length() >= 8 ? d.substring(0, 8) : null;
    }
    static void setNum(PreparedStatement ps, int idx, String v) throws SQLException {
        if (isBlank(v)) ps.setNull(idx, Types.NUMERIC);
        else ps.setLong(idx, Long.parseLong(v.replace(",", "").trim()));
    }
%>
