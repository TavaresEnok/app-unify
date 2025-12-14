# 📚 Guia Git - Projeto App Unify

## 🔑 Autenticação SSH

O repositório usa **chave SSH** para autenticação (sem senha).

**Localização da chave:**
```
~/.ssh/github_unify
```

---

## 📁 Diretório do Projeto

Sempre execute os comandos Git dentro deste diretório:
```bash
cd /home/app/painel-provedores-projeto/app-flutter/unified
```

---

## 🚀 Comandos Básicos

### Ver status
```bash
git status
```

### Adicionar arquivos
```bash
git add -A                    # Adiciona tudo
git add nome_do_arquivo.dart  # Adiciona arquivo específico
```

### Criar commit
```bash
git commit -m "tipo: descrição da alteração"
```

**Tipos de commit:**
- `feat:` → Nova funcionalidade
- `fix:` → Correção de bug
- `docs:` → Documentação
- `chore:` → Manutenção/limpeza

### Push para GitHub
```bash
GIT_SSH_COMMAND="ssh -i ~/.ssh/github_unify -o StrictHostKeyChecking=no" git push origin main
```

---

## ⚡ Comando Completo (Copie e Cole)

```bash
cd /home/app/painel-provedores-projeto/app-flutter/unified && \
git add -A && \
git commit -m "feat: Sua mensagem aqui" && \
GIT_SSH_COMMAND="ssh -i ~/.ssh/github_unify -o StrictHostKeyChecking=no" git push origin main
```

---

## ⚠️ Importante

| Item | Valor |
|------|-------|
| Branch | `main` (não master) |
| Autenticação | SSH via `~/.ssh/github_unify` |
| Repositório | `github.com:TavaresEnok/app-unify.git` |

---

## 🔍 Verificar Histórico

```bash
git log --oneline -5    # Últimos 5 commits
git branch -vv          # Ver branch atual
```
