import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/fatura.dart';
import '../../navigation/customer_shell_scope.dart';
import '../../providers/financeiro_provider.dart';
import '../../services/api_response.dart';
import '../../services/financeiro_service.dart';
import '../../vibe/vibe_invoice.dart';
import '../../vibe/vibe_page_parts.dart';

const _pdfChannel = MethodChannel('br.com.ajust.app_provedor/invoice_pdf');
const _maxPdfBytes = 12 * 1024 * 1024;

Future<void> openInvoiceDocument(BuildContext context, Fatura invoice) =>
    pushCustomerPage<void>(context,
        route: 'invoice_document', page: InvoiceDocumentPage(invoice: invoice));

/// Documento da fatura. Com link do provedor, baixa o PDF dele (sem
/// credenciais do app). Fatura em aberto sem link (ex.: IXC com carteira
/// Sicredi/Santander): pede o PDF do boleto à API, com a sessão do assinante.
class InvoiceDocumentPage extends ConsumerStatefulWidget {
  const InvoiceDocumentPage(
      {super.key, required this.invoice, this.client, this.saveAndShare});

  final Fatura invoice;
  @visibleForTesting
  final http.Client? client;

  /// Grava o PDF e abre a folha do sistema (abrir no leitor, salvar, enviar).
  @visibleForTesting
  final Future<void> Function(Uint8List bytes, String fileName)? saveAndShare;

  @override
  ConsumerState<InvoiceDocumentPage> createState() =>
      _InvoiceDocumentPageState();
}

class _InvoiceDocumentPageState extends ConsumerState<InvoiceDocumentPage> {
  late final http.Client _client = widget.client ?? http.Client();
  Uint8List? _document;
  Uint8List? _image;
  int _page = 0;
  int _pageCount = 0;
  bool _loading = true;
  bool _unavailable = false;

  /// PDF pedido à API (fatura em aberto sem link do provedor).
  late final bool _fromApi = !widget.invoice.isPago &&
      (widget.invoice.urlBoleto?.trim().isEmpty ?? true);

  /// A API respondeu que o boleto não sai pelo app; texto do servidor.
  String? _notIssued;

  /// Falha passageira ao gerar o boleto (mensagem pronta).
  String? _failure;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    if (_fromApi) {
      _loadFromApi();
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  Future<void> _load() async {
    final uri = Uri.tryParse(widget.invoice.urlBoleto?.trim() ?? '');
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android ||
        uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      if (mounted) {
        setState(() {
          _loading = false;
          _unavailable = true;
        });
      }
      return;
    }
    try {
      final bytes = await _download(uri).timeout(
        const Duration(seconds: 35),
        onTimeout: () {
          _client.close();
          throw TimeoutException('A consulta do documento demorou demais.');
        },
      );
      if (!mounted) return;
      _document = bytes;
      await _render(0);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _unavailable = true;
        });
      }
    } finally {
      _client.close();
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _failure = null;
      _notIssued = null;
    });
    _loadFromApi();
  }

  Future<void> _loadFromApi() async {
    final service = ref.read(financeiroViewModelProvider).service;
    try {
      if (kIsWeb || service == null) {
        throw ApiException(0, FinanceiroService.boletoFailedMessage);
      }
      final bytes = await service.downloadBoletoPdf(widget.invoice.numero,
          client: _client);
      if (!mounted) return;
      _document = bytes;
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _render(0);
      } else if (mounted) {
        // Sem visualização no app: o PDF abre pelo botão abaixo.
        setState(() {
          _loading = false;
          _unavailable = true;
        });
      }
    } on BoletoUnavailableException catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _notIssued = error.message ??
              'Boleto disponível na central do assinante ou com o suporte.';
        });
      }
    } catch (error) {
      // ApiException já traz a frase para o assinante; o resto é genérico.
      if (mounted) {
        setState(() {
          _loading = false;
          _failure = error is ApiException
              ? error.message
              : FinanceiroService.boletoFailedMessage;
        });
      }
    }
  }

  static Future<void> _defaultSaveAndShare(
      Uint8List bytes, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf', name: fileName)]);
  }

  Future<void> _sharePdf() async {
    final bytes = _document;
    if (bytes == null || _sharing) return;
    setState(() => _sharing = true);
    final id = widget.invoice.numero.replaceAll(RegExp(r'[^0-9A-Za-z_-]'), '');
    try {
      await (widget.saveAndShare ?? _defaultSaveAndShare)(
          bytes, 'boleto-${id.isEmpty ? 'fatura' : id}.pdf');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(
            content: Text('Não foi possível abrir o PDF do boleto.')));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<Uint8List> _download(Uri uri) async {
    // Apenas a URL fornecida pelo provedor. Nenhuma credencial do app é enviada.
    final response = await _client
        .send(http.Request('GET', uri))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200 ||
        (response.contentLength ?? 0) > _maxPdfBytes) {
      throw const FormatException('Documento indisponível');
    }
    final builder = BytesBuilder(copy: false);
    var length = 0;
    await for (final chunk
        in response.stream.timeout(const Duration(seconds: 20))) {
      length += chunk.length;
      if (length > _maxPdfBytes) {
        throw const FormatException('Documento indisponível');
      }
      builder.add(chunk);
    }
    final bytes = builder.takeBytes();
    if (bytes.length < 5 ||
        !listEquals(bytes.sublist(0, 5), const [37, 80, 68, 70, 45])) {
      throw const FormatException('Endereço não retornou PDF');
    }
    return bytes;
  }

  Future<void> _render(int page) async {
    if (mounted) setState(() => _loading = true);
    try {
      final result = await _pdfChannel.invokeMapMethod<String, dynamic>(
          'render', {'bytes': _document, 'page': page}).timeout(
        const Duration(seconds: 20),
      );
      final image = result?['image'];
      final count = result?['pages'];
      if (image is! Uint8List || count is! int || count < 1) {
        throw const FormatException('PDF inválido');
      }
      if (mounted) {
        setState(() {
          _page = page;
          _pageCount = count;
          _image = image;
          _loading = false;
          _unavailable = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _unavailable = true;
        });
      }
    }
  }

  Future<void> _openExternal() async {
    final uri = Uri.tryParse(widget.invoice.urlBoleto?.trim() ?? '');
    try {
      if (uri != null &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o documento.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoice = widget.invoice;
    final view = VibeInvoiceView(invoice);
    final finance = ref.watch(financeiroViewModelProvider);
    final current = finance.hasResult &&
        finance.invoices.any((item) =>
            item.numero == invoice.numero &&
            item.vencimento == invoice.vencimento &&
            item.valor == invoice.valor &&
            item.status == invoice.status &&
            item.urlBoleto == invoice.urlBoleto &&
            item.pixCopiaECola == invoice.pixCopiaECola &&
            item.linhaDigitavel == invoice.linhaDigitavel);
    return VibePageScaffold(
      title: view.paid ? 'PDF da fatura' : 'Boleto',
      subtitle: 'Fatura de ${view.month}',
      onBack: () => Navigator.of(context).maybePop(),
      children: [
        if (!current)
          const VibeOkBox(
              strip: true,
              warning: true,
              title:
                  'Os dados da fatura mudaram. Volte e abra o documento novamente.')
        else if (_loading)
          VibeLoading(
              blocks: 2,
              label: _fromApi ? 'Gerando o boleto' : 'Abrindo o documento')
        else if (_notIssued != null)
          VibeOkBox(strip: true, warning: true, title: _notIssued!)
        else if (_failure != null) ...[
          VibeErrorLine(_failure!),
          VibePageButton(
              label: 'Tentar de novo', icon: 'bar', onPressed: _retry),
        ] else if (_fromApi && (_unavailable || _image == null))
          const VibeCard(
              main: true,
              child: VibeEmpty(
                  icon: 'file',
                  title: 'Boleto pronto',
                  text: 'Abra o PDF para ver, salvar ou enviar o boleto.'))
        else if (_unavailable || _image == null)
          const VibeCard(
              main: true,
              child: VibeEmpty(
                  icon: 'file',
                  title: 'Visualização indisponível',
                  text: 'Abra o documento no navegador para continuar.'))
        else ...[
          VibeCard(
              main: true,
              child: Semantics(
                label:
                    'Documento da fatura, página ${_page + 1} de $_pageCount',
                child: Image.memory(_image!, fit: BoxFit.contain),
              )),
          if (_pageCount > 1)
            VibeTwo(
              VibePageButton(
                  label: 'Anterior',
                  ghost: true,
                  small: true,
                  onPressed: _page > 0 ? () => _render(_page - 1) : null),
              VibePageButton(
                  label: 'Próxima (${_page + 1} de $_pageCount)',
                  ghost: true,
                  small: true,
                  onPressed:
                      _page + 1 < _pageCount ? () => _render(_page + 1) : null),
            ),
        ],
        if (view.hasLine)
          VibePageButton(
              label: 'Copiar linha',
              icon: 'copy',
              onPressed: current
                  ? () => VibeInvoiceActions.copyLine(context, invoice)
                  : null),
        if (_fromApi && _document != null)
          VibePageButton(
              label: _sharing ? 'Abrindo o PDF…' : 'Abrir ou salvar PDF',
              icon: 'down',
              ghost: true,
              onPressed: current && !_sharing ? _sharePdf : null)
        else if (!_fromApi)
          VibePageButton(
              label: 'Abrir documento',
              icon: 'down',
              ghost: true,
              onPressed: current ? _openExternal : null),
        if (view.hasPix)
          VibePageButton(
              label: 'Prefiro pagar com Pix',
              icon: 'pix',
              ghost: true,
              onPressed: current
                  ? () => VibeInvoiceActions.copyPix(context, invoice)
                  : null),
        if (!view.paid)
          const VibeNote('O pagamento é feito no app do seu banco.'),
      ],
    );
  }
}
