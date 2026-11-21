import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/provider_config.dart';

Uri? customerContactUri(SupportContactItem contact, {String? message}) {
  final type = contact.type.trim().toLowerCase();
  final value = contact.value.trim();
  final number = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (type == 'whatsapp' && number.isNotEmpty) {
    return Uri.https('wa.me', '/${number.length <= 11 ? '55$number' : number}',
        {'text': message ?? 'Olá! Preciso de ajuda com meu serviço.'});
  }
  if ((type == 'phone' || type == 'telefone') && number.isNotEmpty) {
    return Uri(scheme: 'tel', path: number);
  }
  if (type == 'email' && value.contains('@')) {
    return Uri(
        scheme: 'mailto',
        path: value,
        query: message == null ? null : 'body=${Uri.encodeComponent(message)}');
  }
  final candidate = Uri.tryParse(value);
  return candidate != null &&
          ['http', 'https'].contains(candidate.scheme) &&
          candidate.host.isNotEmpty
      ? candidate
      : null;
}

Future<void> openCustomerContact(
    BuildContext context, SupportContactItem contact,
    {String? message}) async {
  final uri = customerContactUri(contact, message: message);
  try {
    if (uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return;
    }
  } catch (_) {
    // Show a recoverable message below.
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Não conseguimos abrir este canal de atendimento. Tente outro canal.')));
  }
}
