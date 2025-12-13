# Análise de Código - Layouts Flutter

## Resumo da Duplicação

Análise de linhas de código por arquivo em cada layout:

| Arquivo | Layout 02 | Layout 03 | Layout 05 | Layout 06 | Layout 07 |
|---------|-----------|-----------|-----------|-----------|-----------|
| **dashboard_page** | 487 | 366 | 304 | 502 | 410 |
| **login_page** | 323 | 320 | 256 | 264 | 233 |
| **financeiro_page** | 549 | **549** | 386 | **549** | **549** |
| **suporte_page** | 230 | **230** | 94 | **230** | **230** |
| **diagnostico_page** | 1224 | **1224** | 310 | **1224** | **1224** |
| **consumo_page** | 392 | **392** | 128 | **392** | **392** |
| **meu_ip_page** | 161 | **161** | 82 | **161** | **161** |

> **Negrito** = Arquivos idênticos entre layouts

## Análise

### Arquivos 100% Idênticos
- `financeiro_page.dart` - Layouts 02, 03, 06, 07 são iguais (549 linhas cada)
- `suporte_page.dart` - Layouts 02, 03, 06, 07 são iguais (230 linhas cada)
- `diagnostico_page.dart` - Layouts 02, 03, 06, 07 são iguais (1224 linhas cada)
- `consumo_page.dart` - Layouts 02, 03, 06, 07 são iguais (392 linhas cada)
- `meu_ip_page.dart` - Layouts 02, 03, 06, 07 são iguais (161 linhas cada)

### Layout 05 - Diferente
O Layout 05 tem implementações significativamente menores/diferentes, possivelmente mais refatoradas.

## Recomendações

### Curto Prazo
- [ ] Consolidar arquivos idênticos em `/core/pages/` compartilhado
- [ ] Layouts importam do core e aplicam tema

### Médio Prazo
- [ ] Manter apenas diferenças visuais (dashboard, login) por layout
- [ ] Mover lógica comum para services/providers

### Economia Potencial
- **~2,556 linhas** podem ser removidas consolidando arquivos duplicados
- **~50%** de redução de código nos layouts
