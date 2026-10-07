#!/bin/bash
# Oracle 콘솔 접속 (SQL*Plus)
docker exec -it pg-oracle sqlplus play/play1234@//localhost/FREEPDB1 "$@"
