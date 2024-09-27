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

# Python 가상 환경 생성 및 활성화
python3 -m venv venv
source venv/bin/activate

# pip 업그레이드 및 requests 설치
pip install --upgrade pip
pip install requests

# Python 스크립트 생성
cat << EOF > upload_file.py
import os
import sys
import requests

def upload_file(file_path, upload_url):
    try:
        with open(file_path, 'rb') as file:
            files = {'file': file}
            response = requests.post(upload_url, files=files, verify=True)
        
        response.raise_for_status()
        print(f"Successfully uploaded {file_path} to server")
        return True
    except requests.exceptions.RequestException as e:
        print(f"Error: Failed to upload file to server. {str(e)}")
        return False

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python upload_file.py <file_path> <upload_url>")
        sys.exit(1)

    file_path = sys.argv[1]
    upload_url = sys.argv[2]

    if not os.path.exists(file_path):
        print(f"Error: File {file_path} does not exist")
        sys.exit(1)

    if not upload_file(file_path, upload_url):
        sys.exit(1)
EOF

# 파일 업로드 실행
if [ -n "${UPLOAD_URL}" ] && [ -n "${ZIP_NAME}" ]; then
    python upload_file.py "${ZIP_NAME}" "${UPLOAD_URL}"
    upload_status=$?

    if [ $upload_status -ne 0 ]; then
        echo "Error: Failed to upload file to server"
        exit 1
    fi
else
    echo "Error: UPLOAD_URL or ZIP_NAME is not set. Skipping upload."
    exit 1
fi

# 가상 환경 비활성화
deactivate
