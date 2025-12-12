import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/provider_config.dart'; // Just in case
import 'theme.dart';

// --- LOCALLY DEFINED MODELS (Refactor to separate file later if needed) ---
enum InvoiceStatus {
  paid,
  open,
  overdue,
  paind // Keeping typo from legacy interaction if exists, but simplified here
}

class Invoice {
  final String id;
  final double amount;
  final DateTime dueDate;
  final InvoiceStatus status;
  final String description;

  Invoice({
    required this.id,
    required this.amount,
    required this.dueDate,
    required this.status,
    required this.description,
  });
}
// -----------------------------------------------------------------------

// Mock Data
final List<Invoice> _mockInvoices = [
  Invoice(
    id: '1',
    amount: 99.90,
    dueDate: DateTime.now().add(const Duration(days: 5)),
    status: InvoiceStatus.open,
    description: 'Mensalidade Internet',
  ),
  Invoice(
    id: '2',
    amount: 99.90,
    dueDate: DateTime.now().subtract(const Duration(days: 25)),
    status: InvoiceStatus.paid,
    description: 'Mensalidade Internet',
  ),
  Invoice(
    id: '3',
    amount: 99.90,
    dueDate: DateTime.now().subtract(const Duration(days: 55)),
    status: InvoiceStatus.overdue,
    description: 'Mensalidade Internet',
  ),
];

class FinanceiroPage extends StatelessWidget {
  const FinanceiroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Layout04Theme.background,
      appBar: AppBar(
        title: Text('Faturas', style: Layout04Theme.heading3),
        backgroundColor: Layout04Theme.background,
        elevation: 0,
        centerTitle: false,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: _mockInvoices.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final invoice = _mockInvoices[index];
          return _InvoiceCard(invoice: invoice);
        },
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;

  const _InvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final date = DateFormat("dd/MM/yyyy").format(invoice.dueDate);

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (invoice.status) {
      case InvoiceStatus.paid:
      case InvoiceStatus.paind: // Handling typo in model if exists
        statusColor = Layout04Theme.success;
        statusText = 'PAGO';
        statusIcon = Icons.check_circle_rounded;
        break;
      case InvoiceStatus.open:
        statusColor = Layout04Theme.primary;
        statusText = 'A VENCER';
        statusIcon = Icons.schedule_rounded;
        break;
      case InvoiceStatus.overdue:
        statusColor = Layout04Theme.error;
        statusText = 'VENCIDO';
        statusIcon = Icons.warning_rounded;
        break;
      default:
        statusColor = Layout04Theme.textSecondary;
        statusText = 'DESCONHECIDO';
        statusIcon = Icons.help_outline_rounded;
    }

    return Container(
      decoration: Layout04Theme.cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.description,
                    style: Layout04Theme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currency.format(invoice.amount),
                    style: Layout04Theme.heading2,
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: Layout04Theme.caption.copyWith(
                          color: statusColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Layout04Theme.border),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vencimento: $date',
                style: Layout04Theme.bodySmall,
              ),
              if (invoice.status != InvoiceStatus.paid &&
                  invoice.status != InvoiceStatus.paind)
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.copy_rounded,
                          color: Layout04Theme.textSecondary),
                      onPressed: () {}, // Copy Pix
                      tooltip: 'Copiar PIX',
                    ),
                    IconButton(
                      icon: Icon(Icons.qr_code_rounded,
                          color: Layout04Theme.textSecondary),
                      onPressed: () {}, // Show Barcode
                      tooltip: 'Ver Código de Barras',
                    ),
                  ],
                ),
            ],
          ),
          if (invoice.status != InvoiceStatus.paid &&
              invoice.status != InvoiceStatus.paind) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                style: Layout04Theme.primaryButtonStyle.copyWith(
                  backgroundColor:
                      WidgetStateProperty.all(Layout04Theme.surfaceHighlight),
                  foregroundColor:
                      WidgetStateProperty.all(Layout04Theme.primary),
                ),
                icon: const Icon(Icons.pix, size: 20),
                label: const Text('Pagar com Pix'),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
