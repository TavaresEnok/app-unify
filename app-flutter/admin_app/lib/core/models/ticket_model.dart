import 'package:cloud_firestore/cloud_firestore.dart';

class TicketModel {
  final String id;
  final String subject;
  final String? message;
  final String status;
  final String? providerName;
  final String? providerId;
  final String? customerName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TicketModel({
    required this.id,
    required this.subject,
    this.message,
    required this.status,
    this.providerName,
    this.providerId,
    this.customerName,
    this.createdAt,
    this.updatedAt,
  });

  factory TicketModel.fromMap(Map<String, dynamic> map, String id) {
    return TicketModel(
      id: id,
      subject: map['subject'] ?? 'Sem assunto',
      message: map['message'],
      status: map['status'] ?? 'Aberto',
      providerName: map['providerName'],
      providerId: map['providerId'],
      customerName: map['customerName'],
      createdAt: map['createdAt'] is String
          ? DateTime.tryParse(map['createdAt'])
          : null, // Assume String (ISO) from BFF
      updatedAt: map['updatedAt'] is String
          ? DateTime.tryParse(map['updatedAt'])
          : null,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'Aberto':
        return '🔵 Aberto';
      case 'Em Andamento':
        return '🟡 Em Andamento';
      case 'Fechado':
        return '🟢 Fechado';
      default:
        return status;
    }
  }
}
