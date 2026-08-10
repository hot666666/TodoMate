#!/bin/bash

set -euo pipefail

echo "--- Core ---"
xcodebuild -version
swift --version

echo -e "\n--- Tools ---"
just --version
xcbeautify --version

echo -e "\n--- Quality ---"
swiftformat --version
swiftlint version

echo -e "\n--- Backend & Script ---"
python3 --version
