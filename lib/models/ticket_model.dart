// lib/models/ticket_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class TicketModel {
  final String id;
  final String eventId;
  final String eventTitre;
  final String eventImageUrl;
  final String userId;
  final String userNom;
  final String userEmail;
  final DateTime dateReservation;
  final DateTime dateEvenement;
  final String lieuEvenement;
  final double prixPaye;
  final int nombrePlaces;
  final TicketStatus status;
  final String qrCodeData;
  final String? codeConfirmation;

  TicketModel({
    required this.id,
    required this.eventId,
    required this.eventTitre,
    required this.eventImageUrl,
    required this.userId,
    required this.userNom,
    required this.userEmail,
    required this.dateReservation,
    required this.dateEvenement,
    required this.lieuEvenement,
    required this.prixPaye,
    required this.nombrePlaces,
    this.status = TicketStatus.confirme,
    required this.qrCodeData,
    this.codeConfirmation,
  });

  factory TicketModel.fromMap(Map<String, dynamic> map, String id) {
    return TicketModel(
      id: id,
      eventId: map['eventId'] ?? '',
      eventTitre: map['eventTitre'] ?? '',
      eventImageUrl: map['eventImageUrl'] ?? '',
      userId: map['userId'] ?? '',
      userNom: map['userNom'] ?? '',
      userEmail: map['userEmail'] ?? '',
      dateReservation: (map['dateReservation'] as Timestamp).toDate(),
      dateEvenement: (map['dateEvenement'] as Timestamp).toDate(),
      lieuEvenement: map['lieuEvenement'] ?? '',
      prixPaye: (map['prixPaye'] as num?)?.toDouble() ?? 0.0,
      nombrePlaces: map['nombrePlaces'] ?? 1,
      status: TicketStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TicketStatus.confirme,
      ),
      qrCodeData: map['qrCodeData'] ?? '',
      codeConfirmation: map['codeConfirmation'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'eventTitre': eventTitre,
      'eventImageUrl': eventImageUrl,
      'userId': userId,
      'userNom': userNom,
      'userEmail': userEmail,
      'dateReservation': Timestamp.fromDate(dateReservation),
      'dateEvenement': Timestamp.fromDate(dateEvenement),
      'lieuEvenement': lieuEvenement,
      'prixPaye': prixPaye,
      'nombrePlaces': nombrePlaces,
      'status': status.name,
      'qrCodeData': qrCodeData,
      'codeConfirmation': codeConfirmation,
    };
  }
}

enum TicketStatus {
  confirme,
  utilise,
  annule,
  // ✅ FIX: "remboursé" → "rembourse" (caractère illégal supprimé)
  rembourse,
}