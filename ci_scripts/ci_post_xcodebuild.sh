#!/bin/sh

# 변수 설정
APP_NAME="${CI_PRODUCT}"
DEVELOPER_ID_SIGNED_APP_PATH="${CI_DEVELOPER_ID_SIGNED_APP_PATH}/${APP_NAME}.app"

# 버전 정보 추출
SHORT_VERSION=$(defaults read "${DEVELOPER_ID_SIGNED_APP_PATH}/Contents/Info" CFBundleShortVersionString)
BUILD_VERSION=$(defaults read "${DEVELOPER_ID_SIGNED_APP_PATH}/Contents/Info" CFBundleVersion)

# 버전형식을 갖춘 파일명 생성
VERSION_STRING="TodoMate ${SHORT_VERSION}(${BUILD_VERSION})"
ZIP_NAME="${VERSION_STRING}.zip"

# 환경변수에서 업로드 URL 가져오기
UPLOAD_URL="${UPLOAD_SERVER_URL}"

# Developer ID로 서명된 .app 파일 확인
if [ ! -d "${DEVELOPER_ID_SIGNED_APP_PATH}" ]; then
    echo "Error: Developer ID signed .app directory not found at ${DEVELOPER_ID_SIGNED_APP_PATH}"
    exit 1
fi

echo "Found signed .app at: ${DEVELOPER_ID_SIGNED_APP_PATH}"

# 현재 디렉토리로 이동 (작업 디렉토리 확보)
cd "${CI_WORKSPACE}"

# 압축 파일 생성
ditto -c -k --sequesterRsrc --keepParent "${DEVELOPER_ID_SIGNED_APP_PATH}" "${ZIP_NAME}"

if [ $? -ne 0 ]; then
    echo "Error: Failed to create zip file"
    exit 1
fi

echo "Created zip file: ${ZIP_NAME}"

# 서버에 업로드
if [ -n "${UPLOAD_URL}" ] && [ -n "${ZIP_NAME}" ]; then
    echo "Attempting to upload file: ${ZIP_NAME} to URL: ${UPLOAD_URL}"
    curl -v -F "file=@${ZIP_NAME}" "${UPLOAD_URL}" \
         --max-time 300 \
         --connect-timeout 30 \
         --retry 5 \
         --retry-delay 10 \
         --retry-max-time 120 \
         -H "User-Agent: XcodeCloudUploader/1.0"
    
    upload_status=$?

    if [ $upload_status -ne 0 ]; then
        echo "Error: Failed to upload file to server. Curl exit code: ${upload_status}"
        exit 1
    fi
else
    echo "Error: UPLOAD_URL or ZIP_NAME is not set. Skipping upload."
    exit 1
fi
