import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumInvoiceCard extends StatelessWidget {
  final double amount;
  final DateTime dueDate;
  final VoidCallback onPay;
  final Color? customColor; // Recebe a cor customizada

  const PremiumInvoiceCard({
    super.key,
    required this.amount,
    required this.dueDate,
    required this.onPay,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final isPaid = amount == 0;

    // Lógica da Cor:
    // 1. Se tiver cor customizada (invoiceColor), usa ELA.
    // 2. Se não, usa a cor Padrão (Verde se pago, Azul se aberto).

    final List<Color> gradientColors;

    if (customColor != null) {
      // Se o usuário escolheu uma cor no painel, usamos ela sempre.
      // (Adicionamos um gradiente sutil baseado nela)
      gradientColors = [customColor!, customColor!.withOpacity(0.8)];
    } else {
      // Comportamento padrão antigo
      gradientColors = isPaid
          ? [const Color(0xFF10B981), const Color(0xFF059669)]
          : [const Color(0xFF2563EB), const Color(0xFF1E3A8A)];
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20, top: -20,
            child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.07))),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.receipt_outlined, color: Colors.white, size: 18)),
                      const SizedBox(width: 10),
                      Text('Fatura Atual', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w500)),
                    ]),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)), child: Text(isPaid ? 'PAGA' : 'ABERTA', style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                  ],
                ),
                const SizedBox(height: 20),
                if (isPaid) const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text('Tudo em dia!', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)))
                else Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [Text('R\$ ', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7), fontSize: 18, fontWeight: FontWeight.w500)), Text(NumberFormat.currency(locale: 'pt_BR', symbol: '').format(amount).trim(), style: GoogleFonts.inter(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold, letterSpacing: -1.0))]),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(isPaid ? 'Pago em' : 'Vence em', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.6), fontSize: 11)), const SizedBox(height: 2), Text(DateFormat("dd 'de' MMM", 'pt_BR').format(dueDate), style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))]), ElevatedButton(onPressed: onPay, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: gradientColors.last, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(isPaid ? 'Histórico' : 'Pagar Agora', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)))])
              ],
            ),
          ),
        ],
      ),
    );
  }
}
