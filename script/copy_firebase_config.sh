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

# 프로젝트 루트에 복사
cp "${SOURCE_PLIST}" "${TARGET_PLIST}"
echo "✅ Copied to ${TARGET_PLIST}"

# 앱 번들 리소스 폴더로도 복사 (런타임에 Bundle.main에서 접근 가능하도록)
if [ -n "${BUILT_PRODUCTS_DIR}" ] && [ -n "${UNLOCALIZED_RESOURCES_FOLDER_PATH}" ]; then
    BUNDLE_PLIST="${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/GoogleService-Info.plist"
    cp "${SOURCE_PLIST}" "${BUNDLE_PLIST}"
    echo "✅ Copied to bundle: ${BUNDLE_PLIST}"
fi
