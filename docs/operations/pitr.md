# Recuperação do Postgres até um ponto no tempo (PITR)

Ativado em 2026-11-11 (achado E6 do plano de rearquitetura). O banco é o cache
do SGP (`sgp_cache`); a fonte de verdade dos provedores segue no Firestore.

## Como funciona

- O Postgres arquiva cada segmento de WAL no volume `painel_provedores_pgwal`
  (`/wal-archive` no container), com `archive_timeout=300`: no máximo 5 min de
  atraso **no disco deste servidor**.
- O backup diário (`scripts/ops/backup-scheduled.sh`, timer `painel-backup`)
  grava em cada execução:
  - `postgres-base.tar.gz`: base física (`pg_basebackup -X fetch`);
  - `postgres-wal.tar.gz`: o WAL arquivado desde a base anterior;
  - `postgres.sql.gz`: dump lógico (como antes).
  Depois de copiar, descarta o WAL que a base nova já cobre.
- `verify-backup.sh` restaura a base física num Postgres sem rede e confere
  `sgp_clients`; tudo vai para o bucket com o manifesto.

Janela de recuperação: qualquer ponto entre duas bases consecutivas usa a base
**anterior** + o WAL da execução **seguinte**. Depois da última base, use o WAL
ainda no volume. Fora do servidor, a perda máxima é de um dia (o envio é diário).

## Restaurar (ensaio ou incidente)

Nunca restaure por cima do volume de produção sem antes parar os serviços e
guardar uma cópia do volume atual. Para ensaio, use um container isolado:

```bash
RUN=/home/app/.backups/painel_provedores/runs/<execução-com-a-base>
WAL=/home/app/.backups/painel_provedores/runs/<execução-seguinte>/postgres-wal.tar.gz
ALVO='2026-11-11 19:13:32+00'   # UTC
docker run --rm --network none -e ALVO="$ALVO" \
  -v "$RUN/postgres-base.tar.gz:/b/base.tar.gz:ro" -v "$WAL:/b/wal.tar.gz:ro" \
  postgres:15-alpine sh -ec '
    mkdir -p /tmp/r /tmp/wal
    tar -xzf /b/base.tar.gz -C /tmp/r; tar -xzf /b/wal.tar.gz -C /tmp/wal
    chown -R postgres:postgres /tmp/r /tmp/wal; chmod 700 /tmp/r
    printf "restore_command = '\''cp /tmp/wal/%%f %%p'\''\nrecovery_target_time = '\''%s'\''\nrecovery_target_action = '\''promote'\''\narchive_mode = off\n" "$ALVO" >> /tmp/r/postgresql.auto.conf
    touch /tmp/r/recovery.signal
    su-exec postgres pg_ctl -D /tmp/r -o "-c listen_addresses=" -l /tmp/pg.log -w start
    sleep 5; grep -E "recovery stopping|archive recovery complete" /tmp/pg.log
    su-exec postgres psql -U sgp_user -d sgp_cache -c "select count(*) from sgp_clients"'
```

O alvo precisa estar antes do último commit presente no WAL disponível; se
não estiver, o Postgres para com `recovery ended before configured recovery
target was reached` (não restaura nada parcial).

## Ensaio de 2026-11-11

Base física tirada, linha `antes` gravada, alvo marcado, linha `depois`
gravada. A restauração isolada até o alvo parou em `recovery stopping before
commit of transaction 1340` e trouxe só `antes`; a produção tinha as duas. A
tabela de teste foi removida em seguida. O backup agendado completo rodou com
os arquivos novos, a base física foi restaurada na verificação (492 linhas) e
os 11 arquivos subiram para o bucket.
