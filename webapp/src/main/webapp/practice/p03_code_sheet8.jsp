<%@ page contentType="text/html; charset=UTF-8" %>
<% String pageTitle = "실습 3. 공통코드 관리 (IBSheet8)"; %>
<%@ include file="/common/top.jspf" %>
<link rel="stylesheet" href="<%= ctx %>/lib/ibsheet8/css/default/main.css">
<script src="<%= ctx %>/lib/ibsheet8/ibsheet.js"></script>
<script src="<%= ctx %>/lib/ibsheet8/locale/ko.js"></script>
<script src="<%= ctx %>/lib/ibsheet8/ibleaders.js"></script>

<div class="btns">
  <button onclick="doAction('search')">조회</button>
  <button onclick="doAction('insert')">추가</button>
  <button onclick="doAction('save')">저장</button>
</div>
<div id="sheetDiv" style="width:100%; height:450px"></div>

<script>
var CTX = '<%= ctx %>';
var sheet;

function initSheet() {
  if (typeof IBSheet === 'undefined') { alert('IBSheet8 라이브러리가 없습니다. lib/ibsheet8/README.md 참고'); return; }

  // TODO 3-1) 컬럼 정의: 그룹코드(GRP_CD), 코드(CD), 코드명(CD_NM), 정렬순서(SORT_SEQ, Int), 사용여부(USE_YN, Bool Y/N)
  //           GRP_CD, CD, CD_NM 은 Required: 1
  //           GRP_CD, CD 는 PK 이므로 "신규 행에서만" 편집 가능하게 해보세요. (IBSheet8 매뉴얼에서 방법 찾아보기)
  sheet = IBSheet.create({
    id: 'sheet',
    el: 'sheetDiv',
    options: {
      Cols: [
        { Header: '그룹코드', Name: 'GRP_CD', Type: 'Text', Width: 100 }
      ]
    }
  });
  doAction('search');
}

function doAction(action) {
  switch (action) {
    case 'search':
      // TODO 3-2) 실습 2 에서 만든 p02_code_api.jsp 로 조회
      break;
    case 'insert':
      // TODO 3-3) 행 추가 (USE_YN 기본값 'Y')
      break;
    case 'save':
      // TODO 3-4) getSaveJson() → 실습 4 에서 만들 저장 API 로 POST → 성공 시 재조회
      //           참고: ../ibsheet8/emp.jsp, ../api/emp_save.jsp
      break;
  }
}
window.addEventListener('load', initSheet);
</script>

<%@ include file="/common/bottom.jspf" %>
