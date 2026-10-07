<%@ page contentType="text/html; charset=UTF-8" %>
<% String pageTitle = "실습 과제"; %>
<%@ include file="/common/top.jspf" %>

<p>각 과제의 뼈대 파일이 <code>webapp/src/main/webapp/practice/</code> 에 있습니다.
파일을 열어 <code>TODO</code> 부분을 채우고, 저장 후 브라우저에서 새로고침하세요. (재빌드 불필요)</p>
<p>막히면 <code>jsp-basic/</code>, <code>api/</code>, <code>ibsheet7|8/</code> 의 예제 코드를 참고하세요.
MSSQL / Oracle 둘 다에서 동작하게 만드는 것이 목표입니다.</p>

<table class="grid">
  <tr><th>#</th><th>과제</th><th>학습 포인트</th></tr>
  <tr><td class="c">1</td><td><a href="p01_dept_tree.jsp">부서 트리 조회</a></td>
      <td>MSSQL 재귀 CTE(WITH ... UNION ALL) vs Oracle CONNECT BY / LEVEL</td></tr>
  <tr><td class="c">2</td><td><a href="p02_code_api.jsp?ver=8">공통코드 조회 API</a></td>
      <td>IBSheet 조회 JSON 직접 만들기 (7: Data / 8: data + IO)</td></tr>
  <tr><td class="c">3</td><td><a href="p03_code_sheet8.jsp">공통코드 관리 IBSheet8 화면</a></td>
      <td>IBSheet.create, Enum, Required, getSaveJson</td></tr>
  <tr><td class="c">4</td><td>공통코드 저장 API (직접 파일 생성)</td>
      <td>MERGE 문: MSSQL <code>MERGE ... USING (SELECT ?) </code> vs Oracle <code>MERGE ... USING DUAL</code>, 트랜잭션</td></tr>
  <tr><td class="c">5</td><td>3번 화면을 IBSheet7로 다시 만들기</td>
      <td>createIBSheet2 / InitColumns / 이벤트 함수 이름 규칙(시트ID_OnXxx)</td></tr>
</table>

<%@ include file="/common/bottom.jspf" %>
