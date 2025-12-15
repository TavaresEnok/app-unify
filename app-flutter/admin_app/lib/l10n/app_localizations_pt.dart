// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Admin Blue';

  @override
  String get loginTitle => 'Bem-vindo de volta';

  @override
  String get loginSubtitle => 'Faça login para continuar';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get passwordLabel => 'Senha';

  @override
  String get loginButton => 'Entrar';

  @override
  String get homeTitle => 'Painel';

  @override
  String get navProviders => 'Provedores';

  @override
  String get navUsers => 'Usuários';

  @override
  String get navTickets => 'Tickets';

  @override
  String get logoutTitle => 'Sair';

  @override
  String get logoutMessage => 'Deseja realmente sair?';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get logoutButton => 'Sair';
}
