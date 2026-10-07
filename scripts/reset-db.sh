#!/bin/bash
# DB를 초기 상태(샘플 데이터)로 되돌립니다. 직접 만든 테이블/데이터는 모두 사라집니다.
set -e
cd "$(dirname "$0")/.."
docker compose down -v        # -v : DB 볼륨까지 삭제
docker compose up -d --build
echo "초기화 중... Oracle 은 1~2분 뒤 사용 가능합니다."
