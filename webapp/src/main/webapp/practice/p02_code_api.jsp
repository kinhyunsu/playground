<%@ page contentType="application/json; charset=UTF-8" trimDirectiveWhitespaces="true" %>
<%@ page import="java.sql.*, java.util.*, com.playground.DB, com.playground.Json" %>
<%--
  실습 2. 공통코드 조회 API  (IBSheet 조회용)
  GET p02_code_api.jsp?ver=8&grpCd=POS

  TODO 2-1) TB_COMM_CODE 를 조회하세요. (grpCd 파라미터가 있으면 조건 추가, 없으면 전체)
            컬럼: GRP_CD, CD, CD_NM, SORT_SEQ, USE_YN   정렬: GRP_CD, SORT_SEQ
  TODO 2-2) ver=7 이면 {"Data":[...]} , ver=8 이면 {"data":[...], "IO":{"Result":0,"Message":""}} 로 응답하세요.
  TODO 2-3) 오류가 나면 IO.Result(8) / Result.Code(7) 를 음수로 내려주세요.
  참고: ../api/emp_search.jsp
--%>
<%
    String db  = DB.normalize((String) session.getAttribute("db"));
    String ver = DB.nvl(request.getParameter("ver"), "8");
    Map<String, Object> res = new LinkedHashMap<String, Object>();

    // TODO: 여기에 구현

    out.print(Json.stringify(res));
%>
