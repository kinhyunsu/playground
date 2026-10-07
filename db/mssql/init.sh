#!/bin/bash
# mssql-init 컨테이너에서 실행: *.sql 파일을 이름 순서대로 실행합니다.
set -e
SQLCMD=/opt/mssql-tools18/bin/sqlcmd
for f in /scripts/*.sql; do
  echo ">>> $f"
  $SQLCMD -S mssql -U sa -P "$MSSQL_SA_PASSWORD" -C -b -f 65001 -i "$f"
done
echo ">>> MSSQL 초기화 완료"
