// lib/providers/event_provider.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';

class EventProvider extends ChangeNotifier {
  final EventService _eventService = EventService();

  List<EventModel> _events = [];
  final List<EventModel> _featuredEvents = [];
  List<EventModel> _searchResults = [];
  EventModel? _selectedEvent;
  EventCategory? _selectedCategory;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  List<EventModel> get events => _events;
  List<EventModel> get featuredEvents => _featuredEvents;
  List<EventModel> get searchResults => _searchResults;
  EventModel? get selectedEvent => _selectedEvent;
  EventCategory? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  List<EventModel> get filteredEvents {
    if (_selectedCategory == null) return _events;
    return _events
        .where((e) => e.categorie == _selectedCategory)
        .toList();
  }

  void setCategory(EventCategory? category) {
    _selectedCategory = category;
    notifyListeners();
    loadEvents(refresh: true);
  }

  void selectEvent(EventModel event) {
    _selectedEvent = event;
    notifyListeners();
  }

  Future<void> loadEvents({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _events = [];
      _hasMore = true;
      _error = null;
    }

    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('🔄 EventProvider: loadEvents(refresh: $refresh)');

      final newEvents = await _eventService.getEvents(
        category: _selectedCategory,
        limit: 20,
      );

      debugPrint('✅ EventProvider: ${newEvents.length} événements reçus');

      _events = refresh
          ? newEvents
          : [..._events, ...newEvents];

      _hasMore = false; // Désactivé pour l'instant
      _error = null;
    } catch (e) {
      debugPrint('❌ EventProvider erreur: $e');
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Stream<List<EventModel>> getFeaturedEvents() {
    return _eventService.getFeaturedEvents();
  }

  Future<void> searchEvents(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _searchResults = await _eventService.searchEvents(query);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createEvent({
    required EventModel event,
    required File imageFile,
    List<File>? additionalImages,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newEvent = await _eventService.createEvent(
        event: event,
        imageFile: imageFile,
        additionalImages: additionalImages,
      );

      // Ajouter en tête de liste
      _events.insert(0, newEvent);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ createEvent erreur: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleFavorite(
    String userId,
    String eventId,
    bool isFav,
  ) async {
    await _eventService.toggleFavorite(userId, eventId, isFav);
  }
}