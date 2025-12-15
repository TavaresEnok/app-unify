import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/provider_model.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AppConfigTab extends StatefulWidget {
  final ProviderModel provider;
  final Function(Map<String, dynamic>) onSave;

  const AppConfigTab({super.key, required this.provider, required this.onSave});

  @override
  State<AppConfigTab> createState() => _AppConfigTabState();
}

class _AppConfigTabState extends State<AppConfigTab> {
  late String _selectedLayout;
  final TextEditingController _loginBgController = TextEditingController();
  final TextEditingController _homeBgController = TextEditingController();
  bool _forceUpdate = false;

  final List<Map<String, dynamic>> _layouts = [
    {
      'id': 'layout_01',
      'name': 'Clássico',
      'icon': FontAwesomeIcons.tableCells,
      'color': Colors.blue,
    },
    {
      'id': 'layout_02',
      'name': 'Moderno',
      'icon': FontAwesomeIcons.borderAll,
      'color': Colors.indigo,
    },
    {
      'id': 'layout_03',
      'name': 'Futurista',
      'icon': FontAwesomeIcons.layerGroup,
      'color': Colors.purple,
    },
    {
      'id': 'layout_05',
      'name': 'Minimalista',
      'icon': FontAwesomeIcons.square,
      'color': Colors.teal,
    },
    {
      'id': 'layout_06',
      'name': 'Corporativo',
      'icon': FontAwesomeIcons.building,
      'color': Colors.blueGrey,
    },
    {
      'id': 'layout_07',
      'name': 'Premium',
      'icon': FontAwesomeIcons.crown,
      'color': Colors.amber,
    },
  ];

  @override
  void initState() {
    super.initState();
    final config = widget.provider.appConfig ?? {};
    _selectedLayout = config['layout'] ?? 'layout_01';
    _loginBgController.text = config['loginBackgroundUrl'] ?? '';
    _homeBgController.text = config['homeBackgroundUrl'] ?? '';
    _forceUpdate = config['forceUpdate'] ?? false;
  }

  @override
  void dispose() {
    _loginBgController.dispose();
    _homeBgController.dispose();
    super.dispose();
  }

  void _updateConfig() {
    widget.onSave({
      'appConfig': {
        'layout': _selectedLayout,
        'loginBackgroundUrl': _loginBgController.text.trim(),
        'homeBackgroundUrl': _homeBgController.text.trim(),
        'forceUpdate': _forceUpdate,
      },
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Layout do App',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Escolha a aparência do aplicativo para seus clientes.',
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: _layouts.length,
            itemBuilder: (context, index) {
              final layout = _layouts[index];
              final isSelected = _selectedLayout == layout['id'];

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedLayout = layout['id']);
                  _updateConfig();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (layout['color'] as Color).withValues(alpha: 0.2)
                        : Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? (layout['color'] as Color)
                          : Colors.white.withValues(alpha: 0.05),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        layout['icon'],
                        size: 32,
                        color: isSelected
                            ? (layout['color'] as Color)
                            : Colors.grey[500],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        layout['name'],
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.grey[400],
                        ),
                      ),
                      if (isSelected)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Icon(
                            Icons.check_circle,
                            size: 16,
                            color: layout['color'],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 32),
          const Divider(color: Colors.white10),
          const SizedBox(height: 32),

          Text(
            'Imagens de Fundo',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          _buildUrlInput(
            'Background do Login',
            _loginBgController,
            Icons.login,
          ),
          const SizedBox(height: 16),
          _buildUrlInput('Background da Home', _homeBgController, Icons.home),

          const SizedBox(height: 32),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),

          SwitchListTile(
            title: const Text(
              'Forçar Atualização',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'Obrigar clientes a atualizarem o app se houver nova versão.',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            value: _forceUpdate,
            onChanged: (v) {
              setState(() => _forceUpdate = v);
              _updateConfig();
            },
            // ignore: deprecated_member_use
            activeColor: const Color(0xFF2563EB),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildUrlInput(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          onChanged: (_) => _updateConfig(),
          decoration: InputDecoration(
            hintText: 'https://...',
            prefixIcon: Icon(icon, color: Colors.grey[500]),
            filled: true,
            fillColor: Theme.of(context).cardTheme.color,
          ),
        ),
      ],
    );
  }
}
