# SGP API Documentation

Documentação da API do SGP (Sistema de Gestão de Provedores).

## Autenticações

### Básica
Usuário e Senha do SGP.

### Token
Token gerado no SGP.

### CPF/CNPJ e Senha (Central)
CPF/CNPJ e Senha do Cliente para acesso à Central do Assinante.

> Para mais detalhes: https://bookstack.sgp.net.br/books/api/page/autenticacoes-via-api

---

## Central Assinante

### Contrato - Listar
```
POST {{url}}/api/central/contratos
```

**Parâmetros:**
| Campo | Descrição |
|-------|-----------|
| `token` | [Obrigatório] Token de autenticação |
| `app` | [Obrigatório] Appname de autenticação |
| `cpfcnpj` | CPF/CNPJ do cliente |
| `senha` | Senha de acesso à central |

---

### Ordens de Serviço - Listar
```
POST {{url}}/api/central/ordemservico/
```

**Parâmetros:**
| Campo | Descrição |
|-------|-----------|
| `contrato` | ID do contrato |
| `cliente` | ID do cliente |
| `os` | ID da ordem de serviço |
| `status` | Status da OS |
| `pop` | ID do POP vinculado |
| `data_cadastro_inicio` | Formato: "AAAA-MM-DD" |
| `data_cadastro_fim` | Formato: "AAAA-MM-DD" |

---

### Tipos de Ocorrência - Listar
```
POST {{url}}/api/central/tipoocorrencia/list/
```

---

### Chamado - Criar
```
POST {{url}}/api/central/chamado/
```

**Parâmetros:**
| Campo | Descrição |
|-------|-----------|
| `contrato` | [Obrigatório] ID do contrato |
| `conteudo` | Conteúdo da ocorrência |
| `ocorrenciatipo` | Código do tipo de ocorrência |
| `os_prioridade` | 1=Baixa, 2=Normal, 3=Alta |
| `data_hora_agendamento` | Formato: "AAAA-MM-DD HH:MM" |

---

### Chamado - Atualizar
```
POST {{url}}/api/central/chamado/update/{os_id}/
```

**Parâmetros:**
| Campo | Descrição |
|-------|-----------|
| `os_status` | 0=Aberta, 1=Encerrada, 2=Em execução, 3=Pendente |
| `os_tecnico_responsavel` | ID ou Usuário do técnico |
| `os_prioridade` | 1=Baixa, 2=Normal, 3=Alta |

---

### Chamado - Adicionar Anexo
```
POST {{url}}/api/central/chamado/{os_id}/anexo/add/
```

---

### Fatura - Listar
```
POST {{url}}/api/central/titulos/
```

**Parâmetros:**
| Campo | Descrição |
|-------|-----------|
| `contrato` | ID do contrato |
| `status` | Status da fatura |
| `offset` | Deslocamento (padrão: 0) |
| `limit` | Limite de resultados (padrão: 250) |

---

### Nota Fiscal - Listar
```
POST {{url}}/api/central/notafiscal/list/
```

---

> **Nota:** Este é um resumo. O arquivo original completo está em `SGP.txt`.
