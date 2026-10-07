<%@ page contentType="text/html; charset=UTF-8" %>
<% String pageTitle = "IBSheet7 사원관리"; %>
<%@ include file="/common/top.jspf" %>
<%--
  ★ IBSheet7 라이브러리는 상용 제품이라 포함되어 있지 않습니다.
    회사 프로젝트의 IBSheet7 폴더(ibleaders.js, ibsheetinfo.js, ibsheet.js 등)를
    webapp/src/main/webapp/lib/ibsheet7/ 에 복사하세요. (lib/ibsheet7/README.md 참고)
    회사 프로젝트의 include 순서/파일명이 다르면 아래 script 태그를 회사 것과 똑같이 맞추세요.
--%>
<script src="<%= ctx %>/lib/ibsheet7/ibleaders.js"></script>
<script src="<%= ctx %>/lib/ibsheet7/ibsheetinfo.js"></script>
<script src="<%= ctx %>/lib/ibsheet7/ibsheet.js"></script>

<div id="libMissing" class="warn" style="display:none">
  IBSheet7 라이브러리를 찾을 수 없습니다. <code>lib/ibsheet7/README.md</code> 를 보고 파일을 복사하세요.<br>
  라이브러리 없이도 서버 응답은 확인할 수 있습니다:
  <a href="<%= ctx %>/api/emp_search.jsp?ver=7" target="_blank">api/emp_search.jsp?ver=7</a>
</div>

<form name="frm" class="search" onsubmit="doAction('search'); return false;">
  <label>이름 <input name="empNm"></label>
  <label>재직 <select name="useYn"><option value="">전체</option><option value="Y" selected>재직</option><option value="N">퇴사</option></select></label>
  <button type="submit">조회</button>
</form>

<div class="btns">
  <button onclick="doAction('insert')">행 추가</button>
  <button onclick="doAction('saveJson')">저장 (GetSaveJson + ajax)</button>
  <button onclick="doAction('doSave')">저장 (DoSave)</button>
  <button onclick="doAction('excel')">엑셀 다운로드</button>
</div>

<div id="sheetDiv"></div>

<script>
var CTX = '<%= ctx %>';

/* ---------------------------------------------------------------
 * 1. 시트 생성 + 컬럼 정의
 *    SaveName 이 서버 JSON 의 키(= DB 컬럼명)와 같아야 데이터가 매핑됩니다.
 * --------------------------------------------------------------- */
async function initSheet() {
  if (typeof createIBSheet2 !== 'function') {
    document.getElementById('libMissing').style.display = 'block';
    return;
  }

  // 콤보 데이터 미리 로드 (IBSheet7 콤보: "텍스트1|텍스트2", "코드1|코드2")
  var pos  = await (await fetch(CTX + '/api/code_list.jsp?grpCd=POS')).json();
  var dept = await (await fetch(CTX + '/api/code_list.jsp?grpCd=DEPT')).json();

  // createIBSheet2(부모 엘리먼트, 시트ID, 너비, 높이) → window.mySheet 생성
  createIBSheet2(document.getElementById('sheetDiv'), 'mySheet', '100%', '450px');

  var initData = {};
  initData.Cfg = { SearchMode: 0 /* smGeneral: 한 번에 전체 조회 */, Page: 50 };
  initData.HeaderMode = { Sort: 1, ColMove: 1, ColResize: 1, HeaderCheck: 1 };
  initData.Cols = [
    { Header: '상태', Type: 'Status',   SaveName: 'sStatus', Width: 50,  Align: 'Center' },
    { Header: '삭제', Type: 'DelCheck', SaveName: 'sDelete', Width: 50,  Align: 'Center' },
    { Header: '사번', Type: 'Text',     SaveName: 'EMP_NO',  Width: 80,  Align: 'Center', Edit: 0 },
    { Header: '이름', Type: 'Text',     SaveName: 'EMP_NM',  Width: 100, Align: 'Left',   KeyField: 1 },
    { Header: '부서', Type: 'Combo',    SaveName: 'DEPT_CD', Width: 120, Align: 'Left',
      ComboText: dept.map(function (c) { return c.CD_NM; }).join('|'),
      ComboCode: dept.map(function (c) { return c.CD; }).join('|') },
    { Header: '직급', Type: 'Combo',    SaveName: 'POS_CD',  Width: 80,  Align: 'Center',
      ComboText: pos.map(function (c) { return c.CD_NM; }).join('|'),
      ComboCode: pos.map(function (c) { return c.CD; }).join('|') },
    { Header: '입사일', Type: 'Date',   SaveName: 'HIRE_DT', Width: 100, Align: 'Center', Format: 'Ymd' },
    { Header: '급여', Type: 'Int',      SaveName: 'SAL',     Width: 110, Align: 'Right',  Format: 'Integer' },
    { Header: '이메일', Type: 'Text',   SaveName: 'EMAIL',   Width: 180, Align: 'Left' },
    { Header: '재직', Type: 'CheckBox', SaveName: 'USE_YN',  Width: 50,  Align: 'Center', TrueValue: 'Y', FalseValue: 'N' }
  ];
  IBS_InitSheet(mySheet, initData);
  mySheet.SetEditable(1);

  doAction('search');
}

/* ---------------------------------------------------------------
 * 2. 버튼 처리 - 레거시 IBSheet 화면의 전형적인 doAction 패턴
 * --------------------------------------------------------------- */
function doAction(action) {
  if (typeof mySheet === 'undefined') return;
  switch (action) {
    case 'search':
      // DoSearch(URL, 파라미터 문자열) → 응답 {"Data":[...]}
      mySheet.DoSearch(CTX + '/api/emp_search.jsp', 'ver=7&' + new URLSearchParams(new FormData(document.frm)));
      break;

    case 'insert':
      var row = mySheet.DataInsert(-1);          // -1: 마지막 행에 추가
      mySheet.SetCellValue(row, 'USE_YN', 'Y');
      break;

    case 'saveJson':
      // 변경된 행만 JSON 으로 추출 → 직접 ajax 전송 (요즘 레거시에서 많이 쓰는 방식)
      var json = mySheet.GetSaveJson();
      if (json.Code) return;                      // KeyField 누락 등 오류 시 IBSheet가 메시지 표시
      if (!json.data || json.data.length === 0) { alert('변경된 내용이 없습니다.'); return; }
      fetch(CTX + '/api/emp_save.jsp?ver=7', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(json)
      })
        .then(function (r) { return r.json(); })
        .then(function (res) {
          alert(res.Result.Message);
          if (res.Result.Code >= 0) doAction('search');
        });
      break;

    case 'doSave':
      // IBSheet 내장 저장: 변경 행을 form 파라미터(sStatus=I&EMP_NM=...)로 전송
      //  → 서버는 request.getParameterValues("EMP_NM") 로 받음 / 응답 {"Result":{"Code":0,...}}
      mySheet.DoSave(CTX + '/api/emp_save.jsp?ver=7');
      break;

    case 'excel':
      mySheet.Down2Excel({ FileName: '사원목록.xls', DownCols: '2|3|4|5|6|7|8|9' });
      break;
  }
}

/* ---------------------------------------------------------------
 * 3. 이벤트 - "시트ID_이벤트명" 함수를 전역에 선언하면 IBSheet7이 호출
 * --------------------------------------------------------------- */
function mySheet_OnSearchEnd(Code, Msg) {
  if (Code < 0) alert('조회 실패: ' + Msg);
}
function mySheet_OnSaveEnd(Code, Msg) {
  if (Msg) alert(Msg);
  if (Code >= 0) doAction('search');
}
function mySheet_OnDblClick(Row, Col, Value) {
  console.log('더블클릭', Row, mySheet.ColSaveName(Col), Value);
}

window.addEventListener('load', initSheet);
</script>

<%@ include file="/common/bottom.jspf" %>
