#!/bin/sh

# 파일 경로 설정
PLIST_PATH="${CI_PRIMARY_REPOSITORY_PATH}/${TodoMate}/GoogleService-Info.plist"

# 파일이 존재하는지 확인
if [ ! -f "$PLIST_PATH" ]; then
  echo "Creating GoogleService-Info.plist from environment variable"
  echo "$GOOGLE_SERVICE_INFO" > "$PLIST_PATH"
  echo $PLIST_PATH
  head -3 $PLIST_PATH
else
  echo "GoogleService-Info.plist already exists"
fi
