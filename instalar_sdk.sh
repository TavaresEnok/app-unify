#!/bin/bash

# 1. Definir caminhos
SDK_ROOT="$HOME/Android/Sdk"
mkdir -p "$SDK_ROOT/cmdline-tools"

# 2. Baixar Command Line Tools (Versão testada)
echo "--- Baixando ferramentas do Android..."
cd "$SDK_ROOT/cmdline-tools"
wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O tools.zip

# 3. Descompactar e corrigir estrutura de pastas (CRUCIAL para funcionar)
echo "--- Configurando diretórios..."
unzip -q tools.zip
# O zip extrai como 'cmdline-tools', mas o sdkmanager exige 'cmdline-tools/latest'
mv cmdline-tools latest
rm tools.zip

# 4. Configurar variáveis de ambiente temporárias para instalação
export ANDROID_HOME="$SDK_ROOT"
export PATH="$PATH:$SDK_ROOT/cmdline-tools/latest/bin:$SDK_ROOT/platform-tools"

# 5. Aceitar licenças automaticamente
echo "--- Aceitando licenças..."
yes | sdkmanager --licenses > /dev/null

# 6. Instalar componentes essenciais
# platform-tools: adb e ferramentas de conexão
# platforms;android-34: Android 14 (Estável)
# build-tools;34.0.0: Ferramentas de compilação
# emulator: O emulador em si
# system-images: A imagem do Android para o emulador (x86_64 é mais rápido no seu PC)
echo "--- Instalando Android 14 e Emulador (Isso pode demorar um pouco)..."
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" "emulator" "system-images;android-34;google_apis;x86_64"

# 7. Criar o Emulador (AVD)
echo "--- Criando dispositivo virtual 'pixel_dev'..."
echo "no" | avdmanager create avd -n pixel_dev -k "system-images;android-34;google_apis;x86_64" --device "pixel_5" --force

# 8. Vincular ao Flutter
echo "--- Configurando Flutter..."
flutter config --android-sdk "$SDK_ROOT"
flutter config --enable-android

echo "--- CONCLUÍDO! ---"
echo "Reinicie o terminal ou rode 'source ~/.bashrc' se tiver adicionado as variáveis ao path."
