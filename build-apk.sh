#!/bin/bash
# APK Build Automation Script
# Location: /home/app/painel-provedores-projeto/build-apk.sh

set -e  # Exit on error

# Configuration
PROVIDER_ID="${1:-default}"
ARCH="${2:-arm64-v8a}"
FLUTTER_PROJECT="/home/app/painel-provedores-projeto/app-flutter/unified"
OUTPUT_DIR="/home/app/painel-provedores-projeto/admin-painel/public"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BUILD_NUMBER=$(date +%s)  # Unix timestamp as build number

echo "🚀 Iniciando build do APK"
echo "   Provedor: $PROVIDER_ID"
echo "   Arquitetura: $ARCH"
echo "   Data/Hora: $TIMESTAMP"
echo "   Build Number: $BUILD_NUMBER"
echo ""

# Navigate to Flutter project
cd "$FLUTTER_PROJECT"

echo "📦 Limpando builds anteriores..."
flutter clean

echo "📥 Baixando dependências..."
flutter pub get

echo "🔨 Compilando APK..."
case "$ARCH" in
    "arm64-v8a")
        flutter build apk --release \
            --target-platform android-arm64 \
            --build-number=$BUILD_NUMBER
        SOURCE_APK="build/app/outputs/flutter-apk/app-release.apk"
        OUTPUT_NAME="app-arm64-v8a.apk"
        ;;
    "armeabi-v7a")
        flutter build apk --release \
            --target-platform android-arm \
            --build-number=$BUILD_NUMBER
        SOURCE_APK="build/app/outputs/flutter-apk/app-release.apk"
        OUTPUT_NAME="app-armeabi-v7a.apk"
        ;;
    "all"|"universal")
        flutter build apk --release \
            --build-number=$BUILD_NUMBER
        SOURCE_APK="build/app/outputs/flutter-apk/app-release.apk"
        OUTPUT_NAME="app-release.apk"
        ;;
    *)
        echo "❌ Arquitetura inválida: $ARCH"
        echo "   Opções: arm64-v8a, armeabi-v7a, all"
        exit 1
        ;;
esac

echo "📋 Copiando APK gerado..."
cp "$SOURCE_APK" "$OUTPUT_DIR/$OUTPUT_NAME"

# Criar arquivo de metadados
echo "{
  \"timestamp\": \"$TIMESTAMP\",
  \"buildNumber\": $BUILD_NUMBER,
  \"architecture\": \"$ARCH\",
  \"providerId\": \"$PROVIDER_ID\",
  \"fileSize\": $(stat -f%z "$OUTPUT_DIR/$OUTPUT_NAME" 2>/dev/null || stat -c%s "$OUTPUT_DIR/$OUTPUT_NAME")
}" > "$OUTPUT_DIR/${OUTPUT_NAME}.json"

echo ""
echo "✅ Build concluído com sucesso!"
echo "   APK: $OUTPUT_DIR/$OUTPUT_NAME"
echo "   Tamanho: $(du -h "$OUTPUT_DIR/$OUTPUT_NAME" | cut -f1)"
echo ""
