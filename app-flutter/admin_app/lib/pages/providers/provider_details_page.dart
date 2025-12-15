import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/provider_model.dart';
import '../../core/providers/providers.dart';
import 'provider_settings_page.dart';

class ProviderDetailsPage extends ConsumerStatefulWidget {
  final ProviderModel provider;

  const ProviderDetailsPage({super.key, required this.provider});

  @override
  ConsumerState<ProviderDetailsPage> createState() =>
      _ProviderDetailsPageState();
}

class _ProviderDetailsPageState extends ConsumerState<ProviderDetailsPage> {
  late TextEditingController _nameController;
  late TextEditingController _apiUrlController;
  late bool _isActive;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.provider.name);
    _apiUrlController = TextEditingController(
      text: widget.provider.apiUrl ?? '',
    );
    _isActive = widget.provider.active;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _apiUrlController.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    try {
      final updatedProvider = widget.provider.copyWith(
        name: _nameController.text.trim(),
        apiUrl: _apiUrlController.text.trim(),
        active: _isActive,
      );

      await ref.read(providerRepositoryProvider).saveProvider(updatedProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Provedor atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _hasChanges = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Provedor'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        actions: [
          if (_hasChanges)
            TextButton.icon(
              onPressed: _isSaving ? null : _saveChanges,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save, color: Colors.white),
              label: const Text(
                'Salvar',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Hero(
                      tag: 'provider_logo_${widget.provider.id}',
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor:
                            _parseColor(widget.provider.themeColor) ??
                            const Color(0xFF2563EB).withValues(alpha: 0.1),
                        child:
                            widget.provider.logoUrl != null &&
                                widget.provider.logoUrl!.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  widget.provider.logoUrl!,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Text(
                                        widget.provider.name.isNotEmpty
                                            ? widget.provider.name[0]
                                                  .toUpperCase()
                                            : '?',
                                        style: GoogleFonts.inter(
                                          color: const Color(0xFF2563EB),
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                ),
                              )
                            : Text(
                                widget.provider.name.isNotEmpty
                                    ? widget.provider.name[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF2563EB),
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.provider.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'ID: ${widget.provider.id}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Settings Button - NOVO
            Card(
              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF2563EB),
                  child: Icon(Icons.settings, color: Colors.white),
                ),
                title: const Text(
                  'Configurações Avançadas',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Cores, Features, Integrações'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ProviderSettingsPage(provider: widget.provider),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Form Section
            const Text(
              'Informações Básicas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Name Field
            TextField(
              controller: _nameController,
              onChanged: (_) => _markChanged(),
              decoration: InputDecoration(
                labelText: 'Nome do Provedor',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 16),

            // API URL Field
            TextField(
              controller: _apiUrlController,
              onChanged: (_) => _markChanged(),
              decoration: InputDecoration(
                labelText: 'URL da API (SGP)',
                hintText: 'https://api.exemplo.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 16),

            // Active Switch
            Card(
              child: SwitchListTile(
                title: const Text('Provedor Ativo'),
                subtitle: Text(
                  _isActive
                      ? 'O provedor está ativo no sistema'
                      : 'O provedor está desativado',
                ),
                value: _isActive,
                onChanged: (value) {
                  setState(() => _isActive = value);
                  _markChanged();
                },
                // ignore: deprecated_member_use
                activeColor: const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 24),

            // Theme Color Preview
            if (widget.provider.themeColor != null) ...[
              const Text(
                'Cor do Tema',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _parseColor(widget.provider.themeColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  title: const Text('Cor Primária'),
                  subtitle: Text(widget.provider.themeColor ?? 'Não definida'),
                  trailing: const Icon(Icons.edit, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProviderSettingsPage(provider: widget.provider),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return null;
    }
  }
}
