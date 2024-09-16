#!/bin/sh

APP_NAME="${CI_PRODUCT_NAME}"
VERSION="${CI_BUILD_SHORT_VERSION_STRING}"
ARTIFACT_PATH="${CI_AD_HOC_SIGNED_APP_PATH}"
ZIP_NAME="${APP_NAME} ${VERSION}.zip"

# 환경변수에서 업로드 URL 가져오기
UPLOAD_URL="${UPLOAD_SERVER_URL}"

# .app 파일 찾기
APP_FILE=$(find "$ARTIFACT_PATH" -name "*.app" -type d)

if [ -z "$APP_FILE" ]; then
    echo "Error: .app file not found in $ARTIFACT_PATH"
    exit 1
fi

# 압축 파일 생성
zip -r "$ZIP_NAME" "$APP_FILE"

if [ $? -ne 0 ]; then
    echo "Error: Failed to create zip file"
    exit 1
fi

# 서버에 업로드
curl -X POST -F "file=@$ZIP_NAME" "$UPLOAD_URL"

if [ $? -ne 0 ]; then
    echo "Error: Failed to upload file to server"
    exit 1
fi

echo "Successfully uploaded $ZIP_NAME to server"
