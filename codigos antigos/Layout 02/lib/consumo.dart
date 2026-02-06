import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

// Função auxiliar para converter a cor que vem do Firebase
Color _hexToColor(String hexString) {
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceAll('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

class ConsumoPage extends StatefulWidget {
  final Map<String, dynamic> providerConfig;

  const ConsumoPage({super.key, required this.providerConfig});

  @override
  State<ConsumoPage> createState() => _ConsumoPageState();
}

class _ConsumoPageState extends State<ConsumoPage> {
  InAppWebViewController? _webViewController;
  bool _isCustomUiLoaded = false;

  // Variáveis para as cores dinâmicas
  late final Color primaryColor;
  late final String primaryColorHex;

  @override
  void initState() {
    super.initState();
    // Extrai os dados de configuração uma vez no initState
    final tema = widget.providerConfig['tema'] as Map<String, dynamic>;
    primaryColor = _hexToColor(tema['cor_primaria']);
    primaryColorHex = tema['cor_primaria'] as String;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text("Extrato de Consumo"),
        backgroundColor: primaryColor, // <-- COR DINÂMICA
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Stack(
        children: [
          Opacity(
            opacity: _isCustomUiLoaded ? 1.0 : 0.0,
            child: InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri("https://vibetelecom.sgp.net.br/central/extratotrafego/"),
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
              onLoadStop: (controller, url) async {
                await _injectModernCss(controller);
                if (mounted) {
                  setState(() {
                    _isCustomUiLoaded = true;
                  });
                }
              },
            ),
          ),
          if (!_isCustomUiLoaded)
            Center(
              child: CircularProgressIndicator(
                color: primaryColor, // <-- COR DINÂMICA
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _injectModernCss(InAppWebViewController controller) async {
    // O CSS agora usa a cor primária dinâmica
    final customCSS = '''
      :root {
        --cor-primaria: $primaryColorHex;
        --cor-fundo-app: #F5F5F7;
        --cor-fundo-card: #fff;
        --cor-texto: #333;
        --cor-borda-input: #e0e0e0;
        --cor-fundo-input: #f8f9fa;
        --sombra-card: 0 4px 20px rgba(0,0,0,.08);
      }

      body {
        background: var(--cor-fundo-app) !important;
        font-family: Roboto, sans-serif;
      }

      /* Esconde tudo que não queremos */
      .main-header, .sidebar, .breadcrumb, .main-body > h5, .main-body > p {
        display: none !important;
      }

      /* Centraliza e estiliza o card principal */
      .main-body {
        display: flex;
        justify-content: center;
        align-items: flex-start;
        padding: 16px !important;
      }
      .card.card-style-1 {
        width: 100%;
        max-width: 500px;
        background: var(--cor-fundo-card);
        border: none;
        border-radius: 18px;
        box-shadow: var(--sombra-card);
        padding: 16px;
      }

      /* Estiliza as abas 'Internet' e 'Telefonia' */
      .nav-tabs {
        border: none;
        background-color: #efedf0;
        border-radius: 12px;
        padding: 4px;
        display: grid;
        grid-template-columns: 1fr 1fr;
        margin-bottom: 24px;
      }
      .nav-tabs .nav-link {
        border: none !important;
        border-radius: 10px;
        color: #777;
        font-weight: 500;
        text-align: center;
        transition: all 0.3s ease;
      }
      .nav-tabs .nav-link.active {
        background-color: var(--cor-primaria);
        color: white;
        box-shadow: 0 2px 8px rgba(142, 68, 173, 0.4);
      }
      .nav-tabs .nav-link:not(.active):hover {
        background-color: #e4e0e6;
      }

      /* Estiliza os campos de formulário (labels e selects) */
      .form-group label {
        font-weight: 500;
        color: #555;
        margin-bottom: 8px;
        font-size: 14px;
      }
      
      .bootstrap-select .dropdown-toggle {
        background: var(--cor-fundo-input) !important;
        border: 1px solid var(--cor-borda-input) !important;
        border-radius: 12px !important;
        color: var(--cor-texto) !important;
        padding: 12px !important;
        height: auto !important;
        box-shadow: none !important;
      }
      .bootstrap-select .dropdown-toggle:focus {
        border-color: var(--cor-primaria) !important;
      }

      /* Estiliza o botão de consulta */
      form .btn-primary {
        background-color: var(--cor-primaria) !important;
        border-color: var(--cor-primaria) !important;
        border-radius: 12px;
        padding: 14px;
        font-size: 16px;
        font-weight: 500;
        width: 100%;
        margin-top: 16px;
        transition: all 0.2s ease;
      }
      form .btn-primary:hover {
        filter: brightness(1.1);
        box-shadow: 0 4px 12px rgba(142, 68, 173, 0.3);
      }
    ''';

    await controller.injectCSSCode(source: customCSS);
  }
}
