# Rotacao de credenciais

Credenciais que apareceram em arquivos versionados devem ser consideradas
comprometidas mesmo depois da remocao, pois permanecem no historico Git.

## Ordem de rotacao

1. Revogue e recrie chaves OpenRouter e tokens SGP expostos.
2. Revogue contas de servico JSON antigas e gere credenciais com menor privilegio.
3. Troque `PROXY_SECRET` simultaneamente no host e no Firebase Secret Manager.
4. Troque a senha PostgreSQL em janela controlada e atualize `DATABASE_URL`.
5. Reinicie os servicos, valide `/ready` e monitore erros de autenticacao.

Nunca publique valores em issue, commit, log ou comando armazenado no shell.
Uma limpeza do historico com `git filter-repo` exige coordenacao porque reescreve
SHAs e obriga todos os clones a serem refeitos; revogar as credenciais vem antes.
