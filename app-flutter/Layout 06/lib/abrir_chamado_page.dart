import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_provedor/providers/abrir_chamado_provider.dart';
import 'package:app_provedor/configuration_provider.dart';
import 'shared/theme/app_colors.dart';
import 'shared/widgets/app_button.dart';
import 'shared/widgets/app_page.dart';

class AbrirChamadoPage extends StatelessWidget {
  final String cpfCnpj;

  const AbrirChamadoPage({super.key, required this.cpfCnpj});

  @override
  Widget build(BuildContext context) {
    final providerConfig =
        context.read<ConfigurationProvider>().providerConfig!;

    return ChangeNotifierProvider(
      create: (_) =>
          AbrirChamadoProvider(cpfCnpj, providerConfig.id, providerConfig.name),
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
                  .getString('open_ticket_title', 'Abrir Novo Chamado'),
              body: body);
        },
      ),
    );
  }

  Widget _buildTicketForm(BuildContext context, AbrirChamadoProvider provider) {
    final textTheme = Theme.of(context).textTheme;
    final messageController =
        TextEditingController(); // Controller local para o campo de texto

    // Mostra um snackbar em caso de erro
    if (provider.state == AbrirChamadoState.error &&
        provider.errorMessage.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ ${provider.errorMessage}')));
      });
    }

    return Form(
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Text(
              context
                  .read<ConfigurationProvider>()
                  .getString('ticket_subject_label', 'Assunto do Contato'),
              style: textTheme.headlineMedium),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: provider.subject,
            style: textTheme.bodyLarge,
            decoration: InputDecoration(
                hintText: context.read<ConfigurationProvider>().getString(
                    'ticket_subject_placeholder', 'Selecione um assunto')),
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
              style: textTheme.headlineMedium),
          const SizedBox(height: 12),
          TextFormField(
            controller: messageController,
            maxLines: 5,
            style: textTheme.bodyLarge?.copyWith(height: 1.5),
            decoration: InputDecoration(
                hintText: context.read<ConfigurationProvider>().getString(
                    'ticket_message_placeholder',
                    'Descreva o problema em detalhes...')),
          ),
          const SizedBox(height: 24),
          provider.imageFile == null
              ? OutlinedButton.icon(
                  icon: const Icon(Icons.attach_file, size: 20),
                  label: Text(context.read<ConfigurationProvider>().getString(
                      'ticket_attach_image_label', 'Anexar Imagem (Opcional)')),
                  onPressed: () => provider.pickImage(),
                )
              : _buildImagePreview(context, provider),
          const SizedBox(height: 32),
          AppButton(
            label: context
                .read<ConfigurationProvider>()
                .getString('ticket_send_button', 'ENVIAR CHAMADO'),
            onPressed: () => provider.sendTicket(messageController.text),
            icon: Icons.send,
            isLoading: provider.state == AbrirChamadoState.sending,
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(
      BuildContext context, AbrirChamadoProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(children: [
        Icon(Icons.image, color: Theme.of(context).primaryColor, size: 32),
        const SizedBox(width: 12),
        Expanded(
            child: Text(provider.imageFile!.name,
                style: Theme.of(context).textTheme.bodyLarge,
                overflow: TextOverflow.ellipsis)),
        IconButton(
            icon: const Icon(Icons.close, color: AppColors.error),
            onPressed: () => provider.removeImage()),
      ]),
    );
  }

  Widget _buildSuccessMessage(BuildContext context, String ticketId) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.check_circle_outline, size: 100, color: AppColors.success),
          const SizedBox(height: 24),
          Text(
              context
                  .read<ConfigurationProvider>()
                  .getString('ticket_success_title', 'Chamado Aberto!'),
              style: textTheme.displayLarge),
          const SizedBox(height: 12),
          Text(
              'Seu chamado foi registrado com o ID: $ticketId. Nossa equipe responderá assim que possível.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium),
          const SizedBox(height: 32),
          AppButton(
            label: context
                .read<ConfigurationProvider>()
                .getString('back_button', 'Voltar para Suporte'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ]),
      ),
    );
  }
}
