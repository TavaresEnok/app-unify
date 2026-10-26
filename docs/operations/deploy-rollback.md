# Deploy e rollback

## Pre-deploy

1. Use uma tag imutavel no formato `vMAJOR.MINOR.PATCH` criada a partir de `main`.
2. Confirme `npm run validate`, `docker compose config --quiet` e o workflow Release.
3. Salve backup do Firestore e do volume `pgdata` antes de mudancas de schema.
4. Registre o SHA implantado e os checksums publicados em `SHA256SUMS`.

## Deploy dos containers

```bash
git fetch --tags origin
git switch --detach vMAJOR.MINOR.PATCH
npm run services -- rebuild
npm run services -- health
```

Valide `/`, `/api/health`, `/apk-builder/health`, login, salvamento de aparencia
e uma consulta SGP sem executar uma geracao APK de producao.

## Rollback

1. Identifique a ultima tag aprovada e preserve os logs da falha.
2. Volte o codigo para a tag anterior com `git switch --detach TAG`.
3. Execute `npm run services -- rebuild` e `npm run services -- health`.
4. Restaure banco apenas se a versao introduziu uma migracao incompatível; rollback
   de aplicacao nao implica rollback de dados automaticamente.
5. Registre causa, impacto, horario e SHA no incidente.

Functions devem ser reimplantadas a partir da tag anterior pelo workflow manual,
depois dos testes. Nunca edite `functions/lib` diretamente.
