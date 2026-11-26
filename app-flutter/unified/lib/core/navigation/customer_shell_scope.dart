import 'package:flutter/material.dart';

/// Moldura do app do assinante disponível para as páginas que abrem por
/// cima das abas: barra de navegação do layout, marca fixa da tela Dock e
/// o tema do provedor.
class CustomerShellScope extends InheritedWidget {
  const CustomerShellScope({
    super.key,
    required this.frame,
    this.navigate,
    required super.child,
  });

  /// Abre um destino do app (aba ou página), como o toque numa notificação.
  final ValueChanged<String>? navigate;

  /// Envolve [page] com a moldura do app, marcando a aba de [route].
  final Widget Function(String route, Widget page) frame;

  static CustomerShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CustomerShellScope>();

  @override
  bool updateShouldNotify(CustomerShellScope oldWidget) =>
      oldWidget.frame != frame || oldWidget.navigate != navigate;
}

/// Abre [page] como página do app, com a moldura do shell quando existe.
Future<T?> pushCustomerPage<T>(BuildContext context,
    {required String route, required Widget page}) {
  final shell = CustomerShellScope.maybeOf(context);
  return Navigator.of(context).push<T>(MaterialPageRoute<T>(
      builder: (_) => shell == null ? page : shell.frame(route, page)));
}
