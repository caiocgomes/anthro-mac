#!/usr/bin/env bash
# Monta build/AnthroPlus.app (design D8): build release, bundle, Info.plist, ícone, assinatura ad-hoc e autoteste.
# Uso: scripts/build-app.sh [--install]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

INSTALL=0
if [[ "${1:-}" == "--install" ]]; then
    INSTALL=1
elif [[ $# -gt 0 ]]; then
    echo "uso: scripts/build-app.sh [--install]" >&2
    exit 64
fi

if [[ ! -f VERSION ]]; then
    echo "erro: arquivo VERSION não encontrado na raiz do projeto ($ROOT/VERSION)" >&2
    exit 2
fi
VERSION="$(tr -d '[:space:]' < VERSION)"

swift build -c release --product AnthroPlusApp
BIN="$(swift build -c release --show-bin-path)"

APP="build/AnthroPlus.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN/AnthroPlusApp" "$APP/Contents/MacOS/AnthroPlusApp"

# Bundles de recursos do SwiftPM vão para Contents/Resources (AnthroCoreResources.bundle procura ali).
shopt -s nullglob
bundles=("$BIN"/*.bundle)
if [[ ${#bundles[@]} -eq 0 ]]; then
    echo "erro: nenhum bundle de recursos em $BIN" >&2
    exit 1
fi
for bundle in "${bundles[@]}"; do
    cp -R "$bundle" "$APP/Contents/Resources/"
done

iconutil -c icns assets/AppIcon.iconset -o "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>pt-BR</string>
    <key>CFBundleDisplayName</key>
    <string>AnthroPlus</string>
    <key>CFBundleExecutable</key>
    <string>AnthroPlusApp</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>local.suzan.anthroplus</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>AnthroPlus</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.medical</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Baseado no WHO AnthroPlus 1.0.4 da Organização Mundial da Saúde.</string>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP"
codesign --verify --strict "$APP"

# Autoteste positivo: o app encontra os recursos dentro do próprio bundle.
"$APP/Contents/MacOS/AnthroPlusApp" --self-test

# Autoteste negativo: sem o bundle de recursos, o autoteste tem que falhar (prova que não há fallback para .build).
PROBE="$(mktemp -d)/AnthroPlus.app"
cp -R "$APP" "$PROBE"
rm -rf "$PROBE/Contents/Resources/"*.bundle
if "$PROBE/Contents/MacOS/AnthroPlusApp" --self-test >/dev/null 2>&1; then
    echo "erro: autoteste passou sem o bundle de recursos; o app está lendo recursos fora do .app" >&2
    rm -rf "$(dirname "$PROBE")"
    exit 1
fi
rm -rf "$(dirname "$PROBE")"

echo "ok: $APP (versão $VERSION)"

if [[ $INSTALL -eq 1 ]]; then
    TARGET="/Applications"
    if [[ ! -w "$TARGET" ]]; then
        TARGET="$HOME/Applications"
        mkdir -p "$TARGET"
    fi
    rm -rf "$TARGET/AnthroPlus.app"
    cp -R "$APP" "$TARGET/AnthroPlus.app"
    echo "instalado em $TARGET/AnthroPlus.app"
fi
