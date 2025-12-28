#!/bin/bash
# script/copy_firebase_config.sh

# Firebase 설정 파일 경로
FIREBASE_CONFIG_DIR="${PROJECT_DIR}/FirebaseConfig"
TARGET_PLIST="${PROJECT_DIR}/GoogleService-Info.plist"

# CONFIGURATION에 따라 적절한 plist 선택
if [ "${CONFIGURATION}" == "Release" ]; then
    SOURCE_PLIST="${FIREBASE_CONFIG_DIR}/GoogleService-Info-Prod.plist"
    echo "📱 Using Production Firebase config"
else
    SOURCE_PLIST="${FIREBASE_CONFIG_DIR}/GoogleService-Info-Dev.plist"
    echo "🔧 Using Development Firebase config"
fi

# 파일 존재 여부 확인
if [ ! -f "${SOURCE_PLIST}" ]; then
    echo "error: Firebase config not found at ${SOURCE_PLIST}"
    exit 1
fi

# 복사
cp "${SOURCE_PLIST}" "${TARGET_PLIST}"
echo "✅ Copied to ${TARGET_PLIST}"
