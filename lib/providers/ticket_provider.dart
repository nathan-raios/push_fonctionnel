// lib/providers/ticket_provider.dart

import 'package:flutter/material.dart';
import '../models/ticket_model.dart';
import '../services/ticket_service.dart';

class TicketProvider extends ChangeNotifier {
  final TicketService _ticketService = TicketService();

  List<TicketModel> _tickets = [];
  bool _isLoading = false;
  String? _error;

  List<TicketModel> get tickets => _tickets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<List<TicketModel>> getUserTickets(String userId) {
    return _ticketService.getUserTickets(userId);
  }

  Future<TicketModel?> createTicket({
    required dynamic event,
    required dynamic user,
    required int nombrePlaces,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final ticket = await _ticketService.createTicket(
        event: event,
        user: user,
        nombrePlaces: nombrePlaces,
      );
      _isLoading = false;
      notifyListeners();
      return ticket;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}