#!/bin/sh

# 파일 경로 설정
PLIST_PATH="${PROJECT_DIR}/GoogleService-Info.plist"

# 파일이 존재하는지 확인
if [ ! -f "$PLIST_PATH" ]; then
  echo "Creating GoogleService-Info.plist from environment variable"
  echo "$GOOGLE_SERVICE_INFO" > "$PLIST_PATH"
else
  echo "GoogleService-Info.plist already exists"
fi
