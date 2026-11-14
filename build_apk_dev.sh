#!/bin/bash

# อ่าน version จาก pubspec.yaml
VERSION=$(grep 'version:' pubspec.yaml | awk '{print $2}' | cut -d '+' -f 1)

# ตรวจสอบว่าได้ version หรือไม่
if [ -z "$VERSION" ]; then
    echo "get version from pubspec.yaml please check file"
    exit 1
fi

fvm use 3.38.9
fvm flutter build apk --flavor dev

BUILD_STATUS=$?

if [ $BUILD_STATUS -eq 0 ]; then
    mkdir -p build/app/outputs/flutter-apk/dev
    mv build/app/outputs/flutter-apk/app-dev-release.apk build/app/outputs/flutter-apk/dev/levelup_money_life-alpha-${VERSION}.apk
    echo "<| Build Success => build/app/outputs/flutter-apk/dev/levelup_money_life-alpha-${VERSION}.apk |>"
else
    echo "<| build APK failed |>"
    exit 1
fi