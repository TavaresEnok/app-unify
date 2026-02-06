import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/locator.dart';
import '../services/suporte_service.dart';

enum AbrirChamadoState { idle, sending, success, error }

class AbrirChamadoProvider with ChangeNotifier {
  final SuporteService _suporteService = locator<SuporteService>();
  final String _userCpfCnpj;
  final String _providerId;
  final String _providerName;

  AbrirChamadoState _state = AbrirChamadoState.idle;
  String _subject = 'Geral (Outros Assuntos)';
  XFile? _imageFile;
  String _ticketId = '';
  String _errorMessage = '';

  // Construtor que recebe os dados necessários
  AbrirChamadoProvider(this._userCpfCnpj, this._providerId, this._providerName);

  // Getters para a UI ouvir as mudanças
  AbrirChamadoState get state => _state;
  String get subject => _subject;
  XFile? get imageFile => _imageFile;
  String get ticketId => _ticketId;
  String get errorMessage => _errorMessage;

  // Setters e métodos para a UI interagir com o estado
  void setSubject(String newSubject) {
    _subject = newSubject;
    notifyListeners();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxHeight: 1024, maxWidth: 1024);
    if (pickedFile != null) {
      _imageFile = pickedFile;
      notifyListeners();
    }
  }

  void removeImage() {
    _imageFile = null;
    notifyListeners();
  }

  Future<void> sendTicket(String message) async {
    if (message.trim().isEmpty) {
      _state = AbrirChamadoState.error;
      _errorMessage = 'A descrição do problema é obrigatória.';
      notifyListeners();
      // Reseta para idle para permitir nova tentativa
      Future.delayed(const Duration(seconds: 1), () => _state = AbrirChamadoState.idle);
      return;
    }

    _state = AbrirChamadoState.sending;
    notifyListeners();

    try {
      final newTicketId = await _suporteService.createTicket(
        subject: _subject,
        message: message,
        imageFile: _imageFile,
        providerId: _providerId,
        providerName: _providerName,
        userEmail: _userCpfCnpj,
      );
      _ticketId = newTicketId;
      _state = AbrirChamadoState.success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst("Exception: ", "");
      _state = AbrirChamadoState.error;
    } finally {
      notifyListeners();
    }
  }
}
