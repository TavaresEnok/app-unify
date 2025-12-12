import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_provedor/providers/abrir_chamado_provider.dart';
import 'package:app_provedor/configuration_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'shared/theme/app_colors.dart';
import 'shared/widgets/app_button.dart';
import 'shared/widgets/app_page.dart';
import 'models/provider_config.dart'; // <-- NOVO

class AbrirChamadoPage extends StatelessWidget {
  final String cpfCnpj;
  final ProviderConfig? providerConfig; // <-- NOVO: Recebe config diretamente

  const AbrirChamadoPage({
    super.key,
    required this.cpfCnpj,
    this.providerConfig,
  });

  @override
  Widget build(BuildContext context) {
    // Tenta usar o config passado ou busca do provider (se existir)
    final dynamic config;
    if (providerConfig != null) {
      config = providerConfig!;
    } else {
      // Fallback antigo
      try {
        config = context.read<ConfigurationProvider>().providerConfig!
            as Map<String, dynamic>;
      } catch (e) {
        return const Scaffold(
            body: Center(
                child: Text("Erro de configuração: Provider não encontrado.")));
      }
    }

    return ChangeNotifierProvider(
      create: (_) => AbrirChamadoProvider(cpfCnpj, config.id, config.name),
      child: Consumer<AbrirChamadoProvider>(
        builder: (context, provider, child) {
          final Widget body;
          if (provider.state == AbrirChamadoState.success) {
            body = _buildSuccessMessage(context, provider.ticketId);
          } else {
            body = _buildTicketForm(context, provider);
          }
          return AppPage(
            title: context
                .read<ConfigurationProvider>()
                .getString('open_ticket_title', 'Suporte Técnico'),
            body: body,
          );
        },
      ),
    );
  }

  Widget _buildTicketForm(BuildContext context, AbrirChamadoProvider provider) {
    final theme = Theme.of(context);
    final messageController = TextEditingController();

    if (provider.state == AbrirChamadoState.error &&
        provider.errorMessage.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(provider.errorMessage)),
          ]),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context
                .read<ConfigurationProvider>()
                .getString('ticket_subject_label', 'Como podemos ajudar?'),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.read<ConfigurationProvider>().getString(
                'ticket_intro_message',
                'Preencha os detalhes abaixo e nossa equipe técnica analisará seu caso rapidamente.'),
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Form(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel(
                      theme,
                      context
                          .read<ConfigurationProvider>()
                          .getString('ticket_subject_field_label', 'Assunto'),
                      icon: Icons.label_outline),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: provider.subject,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: AppColors.textPrimary),
                    dropdownColor: AppColors.surface,
                    decoration: _inputDecoration(context
                        .read<ConfigurationProvider>()
                        .getString('ticket_subject_placeholder',
                            'Selecione o motivo do contato')),
                    items: context
                        .read<ConfigurationProvider>()
                        .getStringList('ticket_subjects', [
                          'Geral (Outros Assuntos)',
                          'Lentidão na Internet',
                          'Sem Conexão',
                          'Problema no Wi-Fi',
                          'Faturas/Financeiro'
                        ])
                        .map((subject) => DropdownMenuItem(
                            value: subject, child: Text(subject)))
                        .toList(),
                    onChanged: (value) => provider.setSubject(value!),
                  ),
                  const SizedBox(height: 24),
                  _buildLabel(
                      theme,
                      context
                          .read<ConfigurationProvider>()
                          .getString('ticket_message_label', 'Descrição'),
                      icon: Icons.description_outlined),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: messageController,
                    maxLines: 5,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: AppColors.textPrimary),
                    decoration: _inputDecoration(context
                        .read<ConfigurationProvider>()
                        .getString('ticket_message_placeholder',
                            'Descreva o problema com o máximo de detalhes possível...')),
                  ),
                  const SizedBox(height: 24),
                  _buildLabel(
                      theme,
                      context.read<ConfigurationProvider>().getString(
                          'ticket_attach_image_label', 'Anexo (Opcional)'),
                      icon: Icons.image_outlined),
                  const SizedBox(height: 8),
                  _buildImageUploadArea(context, provider),
                  const SizedBox(height: 32),
                  AppButton(
                    label: context
                        .read<ConfigurationProvider>()
                        .getString('ticket_send_button', 'ENVIAR SOLICITAÇÃO'),
                    onPressed: () =>
                        provider.sendTicket(messageController.text),
                    icon: FontAwesomeIcons.paperPlane,
                    isLoading: provider.state == AbrirChamadoState.sending,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Tempo médio de resposta: 2 horas',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(ThemeData theme, String text, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: theme.primaryColor),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38),
      filled: true,
      fillColor: AppColors.inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue, width: 1.5),
      ),
    );
  }

  Widget _buildImageUploadArea(
      BuildContext context, AbrirChamadoProvider provider) {
    final isImageSelected = provider.imageFile != null;

    return InkWell(
      onTap: isImageSelected ? null : provider.pickImage,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isImageSelected
              ? AppColors.success.withOpacity(0.05)
              : AppColors.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isImageSelected ? AppColors.success : AppColors.inputBorder,
            style: BorderStyle.solid,
            width: 1,
          ),
        ),
        child: isImageSelected
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.image, color: AppColors.success),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Imagem anexada',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold),
                        ),
                        Text(
                          provider.imageFile!.name,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: provider.removeImage,
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.error),
                    tooltip: 'Remover imagem',
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined,
                      size: 32,
                      color: Theme.of(context).primaryColor.withOpacity(0.6)),
                  const SizedBox(height: 8),
                  Text(
                    'Toque para anexar uma foto',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    'Prints ou fotos do equipamento ajudam muito.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSuccessMessage(BuildContext context, String ticketId) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(FontAwesomeIcons.check,
                  size: 60, color: AppColors.success),
            ),
            const SizedBox(height: 32),
            Text(
              context
                  .read<ConfigurationProvider>()
                  .getString('ticket_success_title', 'Chamado Criado!'),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              context.read<ConfigurationProvider>().getString(
                  'ticket_success_message', 'Seu protocolo de atendimento é:'),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Text(
                ticketId.isEmpty ? 'Aguardando ID...' : ticketId,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              context.read<ConfigurationProvider>().getString(
                  'ticket_success_footer',
                  'Nossa equipe técnica já foi notificada e entrará em contato em breve.'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: context
                    .read<ConfigurationProvider>()
                    .getString('back_button', 'VOLTAR AO INÍCIO'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
