#!/bin/sh

# 변수 설정
APP_NAME="${CI_PRODUCT_NAME}"
VERSION="${CI_BUILD_SHORT_VERSION_STRING}"
SIGNED_APP_PATH="${CI_AD_HOC_SIGNED_APP_PATH}"
ZIP_NAME="${APP_NAME} ${VERSION}.zip"

# 환경변수에서 업로드 URL 가져오기
UPLOAD_URL="${UPLOAD_SERVER_URL}"

# 서명된 .app 파일 확인
if [ ! -d "${SIGNED_APP_PATH}" ]; then
    echo "Error: Signed .app directory not found at ${SIGNED_APP_PATH}"
    exit 1
fi

echo "Found signed .app at: ${SIGNED_APP_PATH}"

# 현재 디렉토리로 이동 (작업 디렉토리 확보)
cd "${CI_WORKSPACE}"

# 압축 파일 생성
zip -r "${ZIP_NAME}" "${SIGNED_APP_PATH}"

if [ $? -ne 0 ]; then
    echo "Error: Failed to create zip file"
    exit 1
fi

echo "Created zip file: ${ZIP_NAME}"

# 서버에 업로드
if [ -n "${UPLOAD_URL}" ]; then
    curl -X POST -F "file=@${ZIP_NAME}" "${UPLOAD_URL}"

    if [ $? -ne 0 ]; then
        echo "Error: Failed to upload file to server"
        exit 1
    fi

    echo "Successfully uploaded ${ZIP_NAME} to server"
else
    echo "UPLOAD_URL is not set. Skipping upload."
fi
