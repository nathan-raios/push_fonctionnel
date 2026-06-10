// lib/services/ticket_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/ticket_model.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';

class TicketService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  Future<TicketModel> createTicket({
    required EventModel event,
    required UserModel user,
    required int nombrePlaces,
  }) async {
    late TicketModel ticket;

    await _firestore.runTransaction((transaction) async {
      final eventDoc = await transaction.get(
        _firestore.collection('events').doc(event.id),
      );

      if (!eventDoc.exists) {
        throw Exception('Événement introuvable');
      }

      final eventData = eventDoc.data()!;
      final currentParticipants =
          (eventData['nombreParticipants'] as num).toInt();
      final maxCapacity =
          (eventData['capaciteMax'] as num).toInt();

      if (currentParticipants + nombrePlaces > maxCapacity) {
        throw Exception('Plus assez de places disponibles');
      }

      final ticketId = _uuid.v4();
      final qrData = '$ticketId|${event.id}|${user.id}';

      ticket = TicketModel(
        id: ticketId,
        eventId: event.id,
        eventTitre: event.titre,
        eventImageUrl: event.imageUrl,
        userId: user.id,
        userNom: user.fullName,
        userEmail: user.email,
        dateReservation: DateTime.now(),
        dateEvenement: event.dateDebut,
        lieuEvenement: event.location.fullAddress,
        prixPaye: event.prix * nombrePlaces,
        nombrePlaces: nombrePlaces,
        qrCodeData: qrData,
        codeConfirmation: _uuid.v4().substring(0, 8).toUpperCase(),
      );

      transaction.set(
        _firestore.collection('tickets').doc(ticketId),
        ticket.toMap(),
      );

      transaction.update(
        _firestore.collection('events').doc(event.id),
        {'nombreParticipants': FieldValue.increment(nombrePlaces)},
      );
    });

    return ticket;
  }

  // ✅ UN SEUL where() sur userId
  Stream<List<TicketModel>> getUserTickets(String userId) {
    return _firestore
        .collection('tickets')
        .where('userId', isEqualTo: userId)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      final tickets = snapshot.docs
          .map((doc) => TicketModel.fromMap(doc.data(), doc.id))
          .toList();

      // ✅ Tri côté client
      tickets.sort(
        (a, b) => b.dateReservation.compareTo(a.dateReservation),
      );
      return tickets;
    });
  }

  Future<TicketValidationResult> validateTicket(String qrData) async {
    try {
      final parts = qrData.split('|');
      if (parts.length != 3) {
        return TicketValidationResult(
          isValid: false,
          message: 'QR Code invalide',
        );
      }

      final ticketId = parts[0];
      final doc = await _firestore
          .collection('tickets')
          .doc(ticketId)
          .get();

      if (!doc.exists) {
        return TicketValidationResult(
          isValid: false,
          message: 'Ticket non trouvé',
        );
      }

      final ticket = TicketModel.fromMap(doc.data()!, doc.id);

      if (ticket.status == TicketStatus.utilise) {
        return TicketValidationResult(
          isValid: false,
          message: 'Ticket déjà utilisé',
          ticket: ticket,
        );
      }

      if (ticket.status == TicketStatus.annule) {
        return TicketValidationResult(
          isValid: false,
          message: 'Ticket annulé',
          ticket: ticket,
        );
      }

      await _firestore
          .collection('tickets')
          .doc(ticketId)
          .update({'status': TicketStatus.utilise.name});

      return TicketValidationResult(
        isValid: true,
        message: 'Ticket valide ! Bienvenue ! 🎉',
        ticket: ticket,
      );
    } catch (e) {
      return TicketValidationResult(
        isValid: false,
        message: 'Erreur: $e',
      );
    }
  }
}

class TicketValidationResult {
  final bool isValid;
  final String message;
  final TicketModel? ticket;

  TicketValidationResult({
    required this.isValid,
    required this.message,
    this.ticket,
  });
}