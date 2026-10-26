# Guia Git

O sistema e um monorepo. O app movel canonico fica em
`app-flutter/unified` e e versionado junto com os demais servicos.

## Fluxo normal

Execute na raiz do projeto:

```bash
git status
git add -A
git commit -m "tipo: descricao da alteracao"
git push
```

Comandos Flutter podem ser executados pela validacao central:

```bash
npm run validate:flutter
```

## Convencao de commits

- `feat:` nova funcionalidade.
- `fix:` correcao de comportamento.
- `refactor:` alteracao estrutural sem nova funcionalidade.
- `docs:` documentacao.
- `chore:` manutencao, dependencias ou infraestrutura.

Use `git branch -vv` antes do push para confirmar a branch e o remoto atuais.
