#!/bin/sh

# 파일 경로 설정
GS_INFO_PATH="${CI_PRIMARY_REPOSITORY_PATH}/TodoMate/GoogleService-Info.plist"
CONFIG_PATH="${CI_PRIMARY_REPOSITORY_PATH}/TodoMate/Config.xcconfig"

# GoogleService-Info.plist 파일이 존재하는지 확인
if [ ! -f "$GS_INFO_PATH" ]; then
  echo "Creating GoogleService-Info.plist from environment variable"
  echo "$GOOGLE_SERVICE_INFO" > "$GS_INFO_PATH"
  echo $GS_INFO_PATH
  head -3 $GS_INFO_PATH
else
  echo "GoogleService-Info.plist already exists"
fi

# Config.xcconfig 파일이 존재하는지 확인
if [ ! -f "$CONFIG_PATH" ]; then
  echo "Creating Config.xcconfig from environment variable"
  echo "$XCCONFIG" > "$CONFIG_PATH"
  echo $CONFIG_PATH
  tail -3 $CONFIG_PATH
else
  echo "Config.xcconfig already exists"
fi
