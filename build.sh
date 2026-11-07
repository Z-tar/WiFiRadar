#!/usr/bin/env bash
# WiFiRadar.app Build & Release Packaging Script
# Native macOS SwiftUI 120Hz Wi-Fi Spectrum Radar

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_TARGET="/Applications/WiFiRadar.app"
DOWNLOADS_DIR="$HOME/Downloads"

echo "=============================================="
echo "📡 正在构建 WiFiRadar.app (Native macOS SwiftUI)..."
echo "=============================================="

cd "$DIR"
swift build -c release

BIN_PATH="$DIR/.build/out/Products/Release/WiFiRadar"
if [ ! -f "$BIN_PATH" ]; then
    BIN_PATH=$(find "$DIR/.build" -name "WiFiRadar" -type f -perm +111 | grep -E "release|Release" | head -n 1)
fi

if [ ! -f "$BIN_PATH" ]; then
    echo "❌ 编译失败：未找到二进制产物"
    exit 1
fi

echo "✓ 二进制编译成功: $BIN_PATH"

echo "📦 正在打包应用程序至 $APP_TARGET..."
rm -rf "$APP_TARGET"
mkdir -p "$APP_TARGET/Contents/MacOS"
mkdir -p "$APP_TARGET/Contents/Resources"

cp "$BIN_PATH" "$APP_TARGET/Contents/MacOS/WiFiRadar"
cp "$DIR/Resources/Info.plist" "$APP_TARGET/Contents/Info.plist"
cp "$DIR/Resources/AppIcon.icns" "$APP_TARGET/Contents/Resources/AppIcon.icns"
echo "APPL????" > "$APP_TARGET/Contents/PkgInfo"

chmod +x "$APP_TARGET/Contents/MacOS/WiFiRadar"

# Codesign bundle so macOS TCC remembers location and system permissions permanently
echo "🔏 正在对 WiFiRadar.app 进行深度代码签名并固化 Bundle ID..."
codesign --force --deep --sign - -i "com.ztar.wifiradar" "$APP_TARGET"

/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP_TARGET" 2>/dev/null || true

echo "✓ /Applications/WiFiRadar.app 安装就绪"

echo "💿 正在生成分发包至 $DOWNLOADS_DIR..."
mkdir -p "$DOWNLOADS_DIR"

# Create ZIP
rm -f "$DOWNLOADS_DIR/WiFiRadar.zip"
cd /Applications
zip -r -y -q "$DOWNLOADS_DIR/WiFiRadar.zip" "WiFiRadar.app"
echo "✓ ZIP 压缩包生成完成: $DOWNLOADS_DIR/WiFiRadar.zip"

# Create DMG
rm -f "$DOWNLOADS_DIR/WiFiRadar.dmg"
hdiutil create -volname "WiFiRadar" -srcfolder "$APP_TARGET" -ov -format UDZO "$DOWNLOADS_DIR/WiFiRadar.dmg"
echo "✓ DMG 镜像生成完成: $DOWNLOADS_DIR/WiFiRadar.dmg"

echo "=============================================="
echo "🎉 全部构建完成！"
echo "• 应用程序：/Applications/WiFiRadar.app"
echo "• DMG 分发包：$DOWNLOADS_DIR/WiFiRadar.dmg"
echo "• ZIP 压缩包：$DOWNLOADS_DIR/WiFiRadar.zip"
echo "=============================================="
