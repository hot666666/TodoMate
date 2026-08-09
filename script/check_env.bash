#!/bin/bash

echo "--- Core ---"
xcodebuild -version
swift --version

echo -e "\n--- Tools ---"
just --version
pre-commit --version
xcbeautify --version

echo -e "\n--- Hooks ---"
swiftformat --version
swiftlint version

echo -e "\n--- Backend & Script ---"
node -v
java -version
python3 --version
