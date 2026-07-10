# App Unify

Aplicativo Flutter de autoatendimento white-label para assinantes dos
provedores cadastrados no painel.

## Validacao

Na raiz do monorepo:

```bash
npm run validate:flutter
```

Somente este app:

```bash
cd app-flutter/unified
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
```

## Build Android

O build de producao e executado pelo servico `apk-builder`. Builds manuais
devem receber configuracao de ambiente por `--dart-define` e usar um keystore
fora do repositorio.

Arquivos locais como `android/local.properties`, `android/key.properties` e
keystores nunca devem ser versionados.
