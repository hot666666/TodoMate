#!/bin/sh

# 파일 경로 설정
GS_INFO_PATH="${CI_PRIMARY_REPOSITORY_PATH}/TodoMate/GoogleService-Info.plist"
CONFIG_PATH="${CI_PRIMARY_REPOSITORY_PATH}/TodoMate/Config.xcconfig"
INFO_PLIST_PATH="${CI_PRIMARY_REPOSITORY_PATH}/TodoMate/Info.plist"

# 빌드 버전 정보
BUILD_NUMBER="${CI_BUILD_NUMBER}"

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

# Info.plist 파일의 CFBundleVersion 업데이트
if [ -f "$INFO_PLIST_PATH" ]; then
  # 키가 없으니 생성 후 추가
  /usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $VERSION" "$INFO_PLIST_PATH"
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$INFO_PLIST_PATH"
  echo "Updated CFBundleVersion to $VERSION in Info.plist"
else
  echo "Info.plist not found at $INFO_PLIST_PATH"
fi
