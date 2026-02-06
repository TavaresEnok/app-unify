import 'package:flutter/foundation.dart';

/// Configuração da tela de login
@immutable
class LoginConfig {
  final String style; // 'classic', 'modern', 'minimal'
  final LoginLogoConfig logo;
  final LoginBackgroundConfig background;
  final LoginQuoteConfig? quote;
  final LoginCarouselConfig? carousel;
  final LoginFormConfig form;

  const LoginConfig({
    required this.style,
    required this.logo,
    required this.background,
    this.quote,
    this.carousel,
    required this.form,
  });

  factory LoginConfig.fromJson(Map<String, dynamic> json) {
    return LoginConfig(
      style: json['style'] as String? ?? 'classic',
      logo:
          LoginLogoConfig.fromJson(json['logo'] as Map<String, dynamic>? ?? {}),
      background: LoginBackgroundConfig.fromJson(
          json['background'] as Map<String, dynamic>? ?? {}),
      quote: json['quote'] != null
          ? LoginQuoteConfig.fromJson(json['quote'] as Map<String, dynamic>)
          : null,
      carousel: json['carousel'] != null
          ? LoginCarouselConfig.fromJson(
              json['carousel'] as Map<String, dynamic>)
          : null,
      form:
          LoginFormConfig.fromJson(json['form'] as Map<String, dynamic>? ?? {}),
    );
  }
}

/// Configuração do logo
@immutable
class LoginLogoConfig {
  final String? url;
  final bool show;
  final String size; // 'small', 'medium', 'large'
  final String position; // 'top', 'center'

  const LoginLogoConfig({
    this.url,
    this.show = true,
    this.size = 'large',
    this.position = 'top',
  });

  factory LoginLogoConfig.fromJson(Map<String, dynamic> json) {
    return LoginLogoConfig(
      url: json['url'] as String?,
      show: json['show'] as bool? ?? true,
      size: json['size'] as String? ?? 'large',
      position: json['position'] as String? ?? 'top',
    );
  }
}

/// Configuração do background
@immutable
class LoginBackgroundConfig {
  final String type; // 'solid', 'gradient', 'image'
  final List<String> colors;
  final String? imageUrl;

  const LoginBackgroundConfig({
    this.type = 'gradient',
    this.colors = const ['#1E293B', '#334155'],
    this.imageUrl,
  });

  factory LoginBackgroundConfig.fromJson(Map<String, dynamic> json) {
    final colorsList = json['colors'] as List<dynamic>?;
    return LoginBackgroundConfig(
      type: json['type'] as String? ?? 'gradient',
      colors: colorsList?.map((e) => e.toString()).toList() ??
          ['#1E293B', '#334155'],
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

/// Configuração da quote/frase
@immutable
class LoginQuoteConfig {
  final bool show;
  final String text;
  final String position; // 'top', 'bottom', 'center'

  const LoginQuoteConfig({
    this.show = true,
    this.text = 'Bem-vindo',
    this.position = 'bottom',
  });

  factory LoginQuoteConfig.fromJson(Map<String, dynamic> json) {
    return LoginQuoteConfig(
      show: json['show'] as bool? ?? true,
      text: json['text'] as String? ?? 'Bem-vindo',
      position: json['position'] as String? ?? 'bottom',
    );
  }
}

/// Configuração do carousel
@immutable
class LoginCarouselConfig {
  final bool show;
  final List<String> images;
  final bool autoPlay;
  final int interval; // milliseconds

  const LoginCarouselConfig({
    this.show = true,
    this.images = const [],
    this.autoPlay = true,
    this.interval = 3000,
  });

  factory LoginCarouselConfig.fromJson(Map<String, dynamic> json) {
    final imagesList = json['images'] as List<dynamic>?;
    return LoginCarouselConfig(
      show: json['show'] as bool? ?? true,
      images: imagesList?.map((e) => e.toString()).toList() ?? [],
      autoPlay: json['autoPlay'] as bool? ?? true,
      interval: json['interval'] as int? ?? 3000,
    );
  }
}

/// Configuração do formulário
@immutable
class LoginFormConfig {
  final bool showWelcomeText;
  final String welcomeText;
  final String placeholderCPF;
  final String placeholderPassword;
  final String buttonText;
  final bool showForgotPassword;
  final bool showRegister;

  const LoginFormConfig({
    this.showWelcomeText = true,
    this.welcomeText = 'Acesse sua conta',
    this.placeholderCPF = 'CPF ou CNPJ',
    this.placeholderPassword = 'Senha',
    this.buttonText = 'Entrar',
    this.showForgotPassword = true,
    this.showRegister = false,
  });

  factory LoginFormConfig.fromJson(Map<String, dynamic> json) {
    return LoginFormConfig(
      showWelcomeText: json['showWelcomeText'] as bool? ?? true,
      welcomeText: json['welcomeText'] as String? ?? 'Acesse sua conta',
      placeholderCPF: json['placeholderCPF'] as String? ?? 'CPF ou CNPJ',
      placeholderPassword: json['placeholderPassword'] as String? ?? 'Senha',
      buttonText: json['buttonText'] as String? ?? 'Entrar',
      showForgotPassword: json['showForgotPassword'] as bool? ?? true,
      showRegister: json['showRegister'] as bool? ?? false,
    );
  }
}
