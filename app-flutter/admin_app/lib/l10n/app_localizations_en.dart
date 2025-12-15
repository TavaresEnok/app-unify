// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Admin Blue';

  @override
  String get loginTitle => 'Welcome Back';

  @override
  String get loginSubtitle => 'Sign in to continue';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get loginButton => 'Login';

  @override
  String get homeTitle => 'Dashboard';

  @override
  String get navProviders => 'Providers';

  @override
  String get navUsers => 'Users';

  @override
  String get navTickets => 'Tickets';

  @override
  String get logoutTitle => 'Logout';

  @override
  String get logoutMessage => 'Do you really want to logout?';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get logoutButton => 'Logout';
}
