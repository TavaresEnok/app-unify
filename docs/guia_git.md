# Guia Git

O sistema possui o repositorio principal e o submodulo do app unificado em
`app-flutter/unified`.

## Repositorio principal

Execute na raiz do projeto:

```bash
git status
git add -A
git commit -m "tipo: descricao da alteracao"
git push
```

## App unificado

As alteracoes do submodulo devem ser publicadas antes da atualizacao do
repositorio principal:

```bash
git -C app-flutter/unified status
git -C app-flutter/unified add -A
git -C app-flutter/unified commit -m "tipo: descricao da alteracao"
git -C app-flutter/unified push

git add app-flutter/unified
git commit -m "chore: atualizar app unificado"
git push
```

## Convencao de commits

- `feat:` nova funcionalidade.
- `fix:` correcao de comportamento.
- `refactor:` alteracao estrutural sem nova funcionalidade.
- `docs:` documentacao.
- `chore:` manutencao, dependencias ou infraestrutura.

Use `git branch -vv` antes do push para confirmar a branch e o remoto atuais.
