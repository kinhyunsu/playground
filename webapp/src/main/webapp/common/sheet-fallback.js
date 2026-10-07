/*
 * IBSheet 라이브러리가 없을 때 [조회] 흐름을 눈으로 보여주는 학습용 도우미
 *   ② 서버에 보낸 요청 주소  →  ④ 서버가 돌려준 JSON  →  ⑤ (IBSheet 대신) 간단한 표
 * ※ 진짜 IBSheet 가 아닙니다. 편집/저장 기능은 없습니다.
 */
function fallbackSearch(url, cols, dataKey) {
  var box = document.getElementById('fallback');
  box.style.display = 'block';
  box.innerHTML = '<p>조회 중...</p>';

  fetch(url)
    .then(function (r) { return r.text(); })
    .then(function (text) {
      var json = JSON.parse(text);
      var rows = json[dataKey] || [];

      var html = '';
      html += '<h3>② IBSheet 가 서버에 보내는 요청</h3>';
      html += '<div class="sql">GET ' + esc(decodeURIComponent(url)) + '</div>';

      html += '<h3>④ 서버(JSP)가 돌려준 데이터 (JSON)</h3>';
      html += '<div class="sql" style="max-height:200px; overflow:auto">' + esc(text) + '</div>';

      html += '<h3>⑤ IBSheet 가 그릴 표 (대신 보여주는 간단한 표, ' + rows.length + '행)</h3>';
      html += '<p style="color:#777">각 칸은 JSON 의 키와 컬럼 정의의 이름(' +
              (dataKey === 'Data' ? 'SaveName' : 'Name') + ')이 같을 때만 채워집니다.</p>';
      html += '<div style="overflow-x:auto"><table class="grid"><tr>';
      cols.forEach(function (c) { html += '<th>' + esc(c.Header) + '<br><small>' + c.key + '</small></th>'; });
      html += '</tr>';
      rows.forEach(function (row) {
        html += '<tr>';
        cols.forEach(function (c) { html += '<td>' + esc(row[c.key] == null ? '' : row[c.key]) + '</td>'; });
        html += '</tr>';
      });
      html += '</table></div>';
      box.innerHTML = html;
    })
    .catch(function (e) { box.innerHTML = '<div class="warn err">조회 실패: ' + esc(e) + '</div>'; });
}

function esc(s) {
  return String(s).replace(/[&<>"']/g, function (c) {
    return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
  });
}
