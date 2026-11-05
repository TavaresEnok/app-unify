## Distribuição dinâmica de agentes

- O agente principal será GPT-6.1 Sol Medium.
- Utilizar até 2 instâncias do perfil `gerente_dinamico`, ambas Sol Medium.
- Utilizar até 8 instâncias do perfil `executor_terra`, todas Terra Medium.
- O gerente principal é responsável por criar os agentes e controlar a distribuição.
- Nenhum gerente terá responsabilidade fixa por backend, frontend ou qualquer tecnologia.
- Distribuir trabalho conforme prioridade, complexidade, disponibilidade e dependências.
- Os dois gerentes podem coordenar simultaneamente frentes diferentes da mesma área.
- Os oito executores podem trabalhar em qualquer área do projeto.
- Não reservar uma quantidade fixa de executores para cada gerente.
- Reatribuir trabalho quando uma frente terminar ou ficar bloqueada.
- Não criar agentes apenas para ocupar vagas disponíveis.
- Evitar conflitos de arquivos e integrar alterações somente após validação.
- Todos devem permanecer no nível Medium.
- Priorizar a menor duração total da tarefa, respeitando a qualidade e a segurança.