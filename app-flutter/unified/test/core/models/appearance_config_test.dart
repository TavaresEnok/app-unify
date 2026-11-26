import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_provedor_unified/core/models/provider_config.dart';
import 'package:app_provedor_unified/core/theme/layout_tokens.dart';

ConfigSection section(Map<String, dynamic> json) =>
    ConfigSection.fromJson(json, '');

void main() {
  welcomeTests();
  test('sem configuração: fonte do layout, texto e ícones padrão', () {
    final c = section({});
    expect(c.appFont, isNull);
    expect(c.textScale, 1.0);
    expect(c.iconWeight, 1.0);
    expect(c.socialLinks, isEmpty);
  });

  test('tipografia antiga (fontFamily) não muda o app', () {
    final c = section({
      'typography': {'fontFamily': 'Inter', 'bodySize': 'medium'}
    });
    expect(c.appFont, isNull);
  });

  test('fonte, tamanho e ícones do painel', () {
    final c = section({
      'typography': {'appFont': 'Sora', 'textScale': 'large'},
      'iconStyle': 'bold',
    });
    expect(c.appFont, 'Sora');
    expect(c.textScale, 1.08);
    expect(c.iconWeight, 1.25);
    final v = LayoutTokens.of('layout_04')
        .withPrimary(const Color(0xFF0891B2))
        .withAppearance(c)
        .vibe;
    expect(v.fontFamily, 'Sora');
    expect(v.iconWeight, 1.25);
  });

  test('fonte desconhecida é ignorada', () {
    expect(
        section({
          'typography': {'appFont': 'Comic Sans'}
        }).appFont,
        isNull);
  });

  test('redes sociais viram links https e inválidos ficam de fora', () {
    final links = section({
      'socialNetworks': {
        'instagram': '@vibetelecom',
        'facebook': 'http://facebook.com/vibe',
        'website': 'www.vibe.com.br',
        'whatsapp': '(88) 99999-0000',
        'tiktok': 'x',
      }
    }).socialLinks;
    expect(links.map((l) => l.kind),
        ['instagram', 'facebook', 'website', 'whatsapp']);
    expect(links[0].url, 'https://instagram.com/vibetelecom');
    expect(links[1].url, 'https://facebook.com/vibe');
    expect(links[2].url, 'https://www.vibe.com.br');
    expect(links[3].url, 'https://wa.me/5588999990000');
    expect(
        section({
          'socialNetworks': {'website': 'javascript:alert(1)', 'whatsapp': '12'}
        }).socialLinks,
        isEmpty);
  });
}

void welcomeTests() {
  test('boas-vindas: texto de exemplo antigo não aparece', () {
    expect(
        section({
          'messages': {'welcome': 'Bem-vindo ao app!'}
        }).welcomeMessage,
        '');
    expect(
        section({
          'messages': {'welcome': '  Olá!  Que bom ter você.  '}
        }).welcomeMessage,
        'Olá! Que bom ter você.');
  });
}
