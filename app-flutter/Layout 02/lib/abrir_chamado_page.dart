import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_provedor/providers/abrir_chamado_provider.dart';
import 'package:app_provedor/configuration_provider.dart';
import 'package:app_provedor/shared/theme/app_colors.dart';

class AbrirChamadoPage extends StatefulWidget {
  final String cpfCnpj;

  const AbrirChamadoPage({super.key, required this.cpfCnpj});

  @override
  State<AbrirChamadoPage> createState() => _AbrirChamadoPageState();
}

class _AbrirChamadoPageState extends State<AbrirChamadoPage> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final providerConfig =
        context.read<ConfigurationProvider>().providerConfig!;

    return ChangeNotifierProvider(
      create: (_) => AbrirChamadoProvider(
          widget.cpfCnpj, providerConfig.id, providerConfig.name),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
              context
                  .read<ConfigurationProvider>()
                  .getString('open_ticket_title', 'Novo Chamado'),
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: AppColors.background,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
        ),
        body: Consumer<AbrirChamadoProvider>(
          builder: (context, provider, child) {
            if (provider.state == AbrirChamadoState.success) {
              return _buildSuccessMessage(context, provider.ticketId);
            }
            return _buildTicketForm(context, provider);
          },
        ),
      ),
    );
  }

  Widget _buildTicketForm(BuildContext context, AbrirChamadoProvider provider) {
    final theme = Theme.of(context);

    // Feedback de erro
    if (provider.state == AbrirChamadoState.error &&
        provider.errorMessage.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(provider.errorMessage),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              context.read<ConfigurationProvider>().getString(
                  'ticket_subject_label', 'Sobre o que deseja falar?'),
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: provider.subject,
            style: GoogleFonts.inter(color: AppColors.textPrimary),
            dropdownColor: Colors.white,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
            items: context
                .read<ConfigurationProvider>()
                .getStringList('ticket_subjects', [
                  'Geral (Outros Assuntos)',
                  'Lentidão na Internet',
                  'Sem Conexão',
                  'Problema no Wi-Fi',
                  'Faturas/Financeiro'
                ])
                .map((subject) =>
                    DropdownMenuItem(value: subject, child: Text(subject)))
                .toList(),
            onChanged: (value) => provider.setSubject(value!),
          ),

          const SizedBox(height: 24),

          Text(
              context
                  .read<ConfigurationProvider>()
                  .getString('ticket_message_label', 'Descreva o Problema'),
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _messageController,
            maxLines: 6,
            style: GoogleFonts.inter(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: context.read<ConfigurationProvider>().getString(
                  'ticket_message_placeholder',
                  'Por favor, conte-nos o que está acontecendo com o máximo de detalhes...'),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
          ),

          const SizedBox(height: 24),

          // Upload de Imagem
          provider.imageFile == null
              ? SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.attach_file_rounded),
                    label: Text(context.read<ConfigurationProvider>().getString(
                        'ticket_attach_image_label',
                        'Anexar Print/Foto (Opcional)')),
                    onPressed: () => provider.pickImage(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      side: const BorderSide(color: AppColors.primaryBlue),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(children: [
                    Icon(Icons.image_rounded,
                        color: theme.primaryColor, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(provider.imageFile!.name,
                            style:
                                GoogleFonts.inter(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis)),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.redAccent),
                      onPressed: () => provider.removeImage(),
                    ),
                  ]),
                ),

          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: provider.state == AbrirChamadoState.sending
                  ? null
                  : () => provider.sendTicket(_messageController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: provider.state == AbrirChamadoState.sending
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(
                      context
                          .read<ConfigurationProvider>()
                          .getString('ticket_send_button', 'ENVIAR CHAMADO'),
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage(BuildContext context, String ticketId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded,
                size: 80, color: AppColors.success),
            const SizedBox(height: 24),
            Text(
                context
                    .read<ConfigurationProvider>()
                    .getString('ticket_success_title', 'Chamado Registrado!'),
                style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Text(
              'Seu protocolo é #$ticketId.\nNossa equipe responderá em breve.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 16, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: Text(context
                    .read<ConfigurationProvider>()
                    .getString('back_button', 'Voltar')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
