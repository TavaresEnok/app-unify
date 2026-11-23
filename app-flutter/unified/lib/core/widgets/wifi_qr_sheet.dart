import 'package:flutter/material.dart';
import 'package:qr/qr.dart';
import '../vibe/vibe_page_parts.dart';
import '../vibe/vibe_text.dart';
import '../vibe/vibe_tokens.dart';

String buildWifiQrPayload(String ssid, String password) {
  String esc(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll(';', r'\;').replaceAll(',', r'\,').replaceAll(':', r'\:');
  if (password.isEmpty) return 'WIFI:T:nopass;S:${esc(ssid)};;';
  return 'WIFI:T:WPA;S:${esc(ssid)};P:${esc(password)};;';
}

Future<void> showWifiQrSheet(
  BuildContext context, {
  required String ssid,
  String initialPassword = '',
}) async {
  final passCtrl = TextEditingController(text: initialPassword);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheet) => StatefulBuilder(
      builder: (ctx, setModalState) {
        final t = VibeTokens.of(ctx);
        final payload = buildWifiQrPayload(ssid, passCtrl.text);
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: Container(
            decoration: BoxDecoration(
              color: t.card,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: t.ink.withValues(alpha: .18),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Compartilhar Wi-Fi por QR Code',
                        style: vibeText(t, 18, 800)),
                    const SizedBox(height: 4),
                    Text(
                        'Rede: $ssid · Aponte a câmera de outro celular para conectar automaticamente.',
                        style: vibeText(t, 12.5, 500, color: t.mut)),
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: t.line),
                        ),
                        child: CustomPaint(
                          size: const Size.square(188),
                          painter: _QrPainter(payload),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    VibeField(
                      label: 'Senha para embutir no QR Code',
                      icon: 'lock',
                      hint: 'Digite a senha do Wi-Fi',
                      controller: passCtrl,
                      obscure: true,
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 14),
                    VibePageButton(
                      label: 'Fechar',
                      onPressed: () => Navigator.of(sheet).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
  passCtrl.dispose();
}

class _QrPainter extends CustomPainter {
  final String data;
  _QrPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final qr = QrCode.fromData(
      data: data,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final image = QrImage(qr);
    final moduleCount = image.moduleCount;
    final moduleSize = size.width / moduleCount;
    final paint = Paint()
      ..color = const Color(0xFF0E1320)
      ..style = PaintingStyle.fill;

    for (var row = 0; row < moduleCount; row++) {
      for (var col = 0; col < moduleCount; col++) {
        if (image.isDark(row, col)) {
          canvas.drawRect(
            Rect.fromLTWH(
              col * moduleSize,
              row * moduleSize,
              moduleSize + 0.3,
              moduleSize + 0.3,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) =>
      oldDelegate.data != data;
}
