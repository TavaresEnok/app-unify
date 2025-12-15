
# Arquitetura do App Admin (Flutter)

Este documento descreve as decisões arquiteturais, bibliotecas e padrões utilizados no desenvolvimento do aplicativo Administrativo Nativo em Flutter.

## 1. Visão Geral

O **Admin App** é um aplicativo Flutter desenvolvido para oferecer paridade total de funcionalidades com o painel web administrativo. Ele permite que super administradores gerenciem provedores, usuários, tickets e configurações do sistema diretamente de dispositivos móveis (Android/iOS).

## 2. Tecnologias Principais

- **Flutter SDK**: Framework de UI multiplataforma.
- **Firebase**: Backend-as-a-Service.
  - **Auth**: Autenticação de usuários.
  - **Firestore**: Banco de dados NoSQL.
  - **Analytics**: Telemetria e eventos.
- **Riverpod**: Gerenciamento de estado reativo e injeção de dependência.
- **GoRouter** (Implícito/Nativo): Navegação gerenciada via `MaterialApp` e widgets de roteamento.

## 3. Estrutura de Pastas

```
lib/
├── core/
│   ├── services/      # Serviços de infra (Auth, Firestore)
│   ├── models/        # Modelos de dados (Provider, User, Ticket)
│   └── constants/     # Cores, estilos e constantes globais
├── l10n/              # Arquivos de internacionalização (.arb)
├── pages/             # Telas do aplicativo
│   ├── dashboard/     # Tela principal e widgets relacionados
│   ├── login/         # Tela de login
│   ├── providers/     # Listagem e edição de provedores
│   ├── users/         # Gestão de usuários
│   └── tickets/       # Gestão de tickets
├── widgets/           # Widgets reutilizáveis (StatCard, CustomInputs, etc.)
└── main.dart          # Ponto de entrada e configuração do tema
```

## 4. Gerenciamento de Estado (Riverpod)

O projeto migrou do `provider` para o `flutter_riverpod` na versão 4.1 para garantir maior testabilidade e segurança de tipos.

### Principais Providers

- **`authProvider`**: Expõe uma instância de `AuthService`.
  - Responsabilidade: Login, Logout, Verificação de permissões (Super Admin).
  - Consumo: Utilizado pelo `AuthGate` para direcionar o usuário (Login vs Home).

### Padrão de Consumo

Utilizamos `ConsumerWidget` ou `ConsumerStatefulWidget` para escutar mudanças de estado.

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    // ...
  }
}
```

## 5. Testes Automatizados

Os testes estão localizados na pasta `test/` e seguem a pirâmide de testes:

- **Unitários**: Testam lógica de negócio isolada (ex: modelos).
- **Widgets**: Testam componentes visuais e interações (ex: `login_page_test.dart`).
  - Utilizam `FakeAuthService` para simular o backend Firebase, garantindo testes rápidos e determinísticos sem necessidade de emuladores.

## 6. CI/CD

O projeto utiliza **GitHub Actions** para integração contínua:
1. Instalação do Flutter.
2. Análise estática (`flutter analyze`).
3. Execução de testes (`flutter test`).
4. Build de release (`flutter build apk --release`).
