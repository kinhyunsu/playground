#!/bin/bash
# MSSQL 콘솔 접속 (sqlcmd).  파일 실행: ./scripts/mssql.sh -i /practice/mssql/01_basics.sql
docker exec -it pg-mssql /opt/mssql-tools18/bin/sqlcmd -S localhost -U play -P 'Play!2345' -C -d PLAYDB -f 65001 "$@"
