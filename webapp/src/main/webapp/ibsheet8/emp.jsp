<%@ page contentType="text/html; charset=UTF-8" %>
<% String pageTitle = "IBSheet8 사원관리"; %>
<%@ include file="/common/top.jspf" %>
<%--
  ★ IBSheet8 라이브러리는 상용 제품이라 포함되어 있지 않습니다.
    회사 프로젝트(또는 IBSheet 체험판)의 파일을 webapp/src/main/webapp/lib/ibsheet8/ 에 복사하세요.
    회사 프로젝트의 include 순서/파일명이 다르면 아래 태그를 회사 것과 똑같이 맞추세요.
--%>
<link rel="stylesheet" href="<%= ctx %>/lib/ibsheet8/css/default/main.css">
<script src="<%= ctx %>/lib/ibsheet8/ibsheet.js"></script>
<script src="<%= ctx %>/lib/ibsheet8/locale/ko.js"></script>
<script src="<%= ctx %>/lib/ibsheet8/ibleaders.js"></script>

<div id="libMissing" class="warn" style="display:none">
  IBSheet8 라이브러리를 찾을 수 없습니다. <code>lib/ibsheet8/README.md</code> 를 보고 파일을 복사하세요.<br>
  라이브러리 없이도 <b>[조회]</b> 를 누르면 요청 → 서버 응답(JSON) → 표 순서로 흐름을 볼 수 있습니다. 응답만 보기:
  <a href="<%= ctx %>/api/emp_search.jsp?ver=8" target="_blank">api/emp_search.jsp?ver=8</a>
</div>

<form name="frm" class="search" onsubmit="doAction('search'); return false;">
  <label>이름 <input name="empNm"></label>
  <label>재직 <select name="useYn"><option value="">전체</option><option value="Y" selected>재직</option><option value="N">퇴사</option></select></label>
  <button type="submit">조회</button>
</form>

<div class="btns">
  <button onclick="doAction('insert')">행 추가</button>
  <button onclick="doAction('delete')">행 삭제(토글)</button>
  <button onclick="doAction('save')">저장</button>
</div>

<div id="sheetDiv" style="width:100%; height:450px"></div>
<div id="fallback" style="display:none"></div>
<script src="<%= ctx %>/common/sheet-fallback.js"></script>

<script>
var CTX = '<%= ctx %>';

// IBSheet 없이 볼 때 쓰는 컬럼 목록 (아래 options.Cols 의 Header / Name 과 같음)
var FALLBACK_COLS = [
  { Header: '사번', key: 'EMP_NO' }, { Header: '이름', key: 'EMP_NM' }, { Header: '부서', key: 'DEPT_CD' },
  { Header: '직급', key: 'POS_CD' }, { Header: '입사일', key: 'HIRE_DT' }, { Header: '급여', key: 'SAL' },
  { Header: '이메일', key: 'EMAIL' }, { Header: '재직', key: 'USE_YN' }
];

var sheet;   // IBSheet.create 가 반환하는 시트 객체

/* ---------------------------------------------------------------
 * 1. 시트 생성 - IBSheet7 과 달리 설정을 객체 하나로 넘깁니다.
 *    Name 이 서버 JSON 의 키(= DB 컬럼명)와 같아야 데이터가 매핑됩니다.
 *    IBSheet8 콤보(Enum): 첫 글자가 구분자 → "|사원|대리", 코드 "|10|20"
 * --------------------------------------------------------------- */
async function initSheet() {
  if (typeof IBSheet === 'undefined') {
    document.getElementById('libMissing').style.display = 'block';
    return;
  }
  var pos  = await (await fetch(CTX + '/api/code_list.jsp?grpCd=POS')).json();
  var dept = await (await fetch(CTX + '/api/code_list.jsp?grpCd=DEPT')).json();
  function enumText(list) { return '|' + list.map(function (c) { return c.CD_NM; }).join('|'); }
  function enumKeys(list) { return '|' + list.map(function (c) { return c.CD; }).join('|'); }

  sheet = IBSheet.create({
    id: 'sheet',
    el: 'sheetDiv',
    options: {
      Cfg: { SearchMode: 0 },
      LeftCols: [
        { Type: 'Int', Name: 'SEQ', Width: 50, Align: 'Center' }          // 행 번호
      ],
      Cols: [
        { Header: '사번',   Name: 'EMP_NO',  Type: 'Text', Width: 80,  Align: 'Center', CanEdit: 0 },
        { Header: '이름',   Name: 'EMP_NM',  Type: 'Text', Width: 100, Required: 1 },
        { Header: '부서',   Name: 'DEPT_CD', Type: 'Enum', Width: 120, Enum: enumText(dept), EnumKeys: enumKeys(dept) },
        { Header: '직급',   Name: 'POS_CD',  Type: 'Enum', Width: 80,  Align: 'Center', Enum: enumText(pos), EnumKeys: enumKeys(pos) },
        { Header: '입사일', Name: 'HIRE_DT', Type: 'Date', Width: 110, Align: 'Center', Format: 'yyyy-MM-dd', DataFormat: 'yyyyMMdd' },
        { Header: '급여',   Name: 'SAL',     Type: 'Int',  Width: 110, Format: '#,##0' },
        { Header: '이메일', Name: 'EMAIL',   Type: 'Text', Width: 180, RelWidth: 1 },
        { Header: '재직',   Name: 'USE_YN',  Type: 'Bool', Width: 50,  TrueValue: 'Y', FalseValue: 'N' }
      ],
      Events: {
        onSearchFinish: function (evt) { console.log('조회 완료', evt); },
        onDblClick: function (evt) { console.log('더블클릭', evt.row && evt.row.EMP_NO, evt.col); }
      }
    }
  });
  doAction('search');
}

function doAction(action) {
  if (typeof sheet === 'undefined' || !sheet) {
    // IBSheet 가 없으면: 조회 흐름만 대신 보여주기 (추가/저장 등은 IBSheet 필요)
    if (action === 'search') {
      fallbackSearch(CTX + '/api/emp_search.jsp?ver=8&' + new URLSearchParams(new FormData(document.frm)), FALLBACK_COLS, 'data');
    } else {
      alert('이 기능은 IBSheet 라이브러리가 있어야 동작합니다.');
    }
    return;
  }
  switch (action) {
    case 'search':
      // doSearch(URL, 파라미터) → 응답 {"data":[...], "IO":{"Result":0}}
      sheet.doSearch(CTX + '/api/emp_search.jsp', 'ver=8&' + new URLSearchParams(new FormData(document.frm)));
      break;

    case 'insert':
      sheet.addRow({ init: { USE_YN: 'Y' } });
      break;

    case 'delete':
      var row = sheet.getFocusedRow();
      if (row) sheet.deleteRow(row);             // 저장 전까지는 "삭제 예정" 상태 (다시 누르면 취소)
      break;

    case 'save':
      // 변경 행만 JSON 추출 → {"data":[{"STATUS":"Added|Changed|Deleted", ...}]}
      var json = sheet.getSaveJson();
      if (json.Message) { alert(json.Message); return; }   // 필수값 누락 등
      if (!json.data || json.data.length === 0) { alert('변경된 내용이 없습니다.'); return; }
      fetch(CTX + '/api/emp_save.jsp?ver=8', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(json)
      })
        .then(function (r) { return r.json(); })
        .then(function (res) {
          alert(res.IO.Message);
          if (res.IO.Result >= 0) doAction('search');
        });
      // 참고) 내장 저장 함수: sheet.doSave({ url: CTX + '/api/emp_save.jsp?ver=8' });
      //       서버 응답 {"IO":{"Result":0,"Message":"..."}} 를 시트가 직접 해석합니다.
      break;
  }
}

window.addEventListener('load', initSheet);
</script>

<%@ include file="/common/bottom.jspf" %>
