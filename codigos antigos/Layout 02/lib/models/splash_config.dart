class SplashConfig {
  final bool enabled;
  final String logoUrl;
  final String backgroundColor;
  final String animation;
  final int duration;
  final bool showProgressBar;
  final String? progressBarColor;
  final String? loadingText;
  final String? loadingTextColor;
  final bool showAppVersion;
  final int minimumDisplayTime;
  final int fadeOutDuration;

  const SplashConfig({
    required this.enabled,
    required this.logoUrl,
    required this.backgroundColor,
    required this.animation,
    required this.duration,
    required this.showProgressBar,
    this.progressBarColor,
    this.loadingText,
    this.loadingTextColor,
    required this.showAppVersion,
    required this.minimumDisplayTime,
    required this.fadeOutDuration,
  });

  factory SplashConfig.fromJson(Map<String, dynamic> json) {
    return SplashConfig(
      enabled: json['enabled'] ?? true,
      logoUrl: json['logoUrl'] ?? '',
      backgroundColor: json['backgroundColor'] ?? '#1E293B',
      animation: json['animation'] ?? 'fade',
      duration: json['duration'] ?? 2000,
      showProgressBar: json['showProgressBar'] ?? true,
      progressBarColor: json['progressBarColor'],
      loadingText: json['loadingText'],
      loadingTextColor: json['loadingTextColor'],
      showAppVersion: json['showAppVersion'] ?? true,
      minimumDisplayTime: json['minimumDisplayTime'] ?? 1500,
      fadeOutDuration: json['fadeOutDuration'] ?? 500,
    );
  }

  static const SplashConfig defaultConfig = SplashConfig(
    enabled: true,
    logoUrl: '',
    backgroundColor: '#1E293B',
    animation: 'fade',
    duration: 2000,
    showProgressBar: true,
    progressBarColor: '#673AB7',
    loadingText: 'Carregando...',
    loadingTextColor: '#FFFFFF',
    showAppVersion: true,
    minimumDisplayTime: 1500,
    fadeOutDuration: 500,
  );
}
