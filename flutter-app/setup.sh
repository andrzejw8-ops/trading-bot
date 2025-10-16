#!/usr/bin/env bash
set -euo pipefail

echo "==> flutter pub get (pre-warm)"
flutter pub get || true

echo "==> flutter create . (generating android/ios/macos)"
flutter create .

IOS_PODFILE="ios/Podfile"
if [ -f "$IOS_PODFILE" ]; then
  if ! grep -q "platform :ios, '12.0'" "$IOS_PODFILE"; then
    echo "==> setting iOS platform 12.0 in Podfile"
    if grep -q "^platform :ios" "$IOS_PODFILE"; then
      sed -i '' "s/^platform :ios.*/platform :ios, '12.0'/" "$IOS_PODFILE"
    else
      sed -i '' "1s;^;platform :ios, '12.0'\n;" "$IOS_PODFILE"
    fi
  fi
fi

echo "==> cocoapods install (may take a while)"
( cd ios && pod install --repo-update || true )

echo '==> flutter pub get'
flutter pub get

echo '==> flutter gen-l10n'
flutter gen-l10n || true

echo '==> DONE. Run on device with: flutter run -d <device_id>'
