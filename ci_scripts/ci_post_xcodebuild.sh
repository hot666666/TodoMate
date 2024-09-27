#!/bin/sh

# 변수 설정
APP_NAME="${CI_PRODUCT}"
DEVELOPER_ID_SIGNED_APP_PATH="${CI_DEVELOPER_ID_SIGNED_APP_PATH}/${APP_NAME}.app"
VERSION=$(defaults read "${DEVELOPER_ID_SIGNED_APP_PATH}/Contents/Info" CFBundleShortVersionString)
ZIP_NAME="${APP_NAME} ${VERSION}.zip"

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
    curl -v -X POST -F "file=@${ZIP_NAME}" "${UPLOAD_URL}" \
         --max-time 600 \
         --connect-timeout 10 \
         --retry 3 \
         --retry-delay 5 \
         --retry-max-time 60 \
         -H "Content-Type: multipart/form-data" \
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
