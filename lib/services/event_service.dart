// lib/services/event_service.dart
// VERSION DIAGNOSTIC : charge TOUT sans filtre

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import 'cloudinary_service.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'events';

  // ==================== CREATE ====================

  Future<EventModel> createEvent({
    required EventModel event,
    required File imageFile,
    List<File>? additionalImages,
  }) async {
    try {
      final imageResponse = await CloudinaryService.uploadImage(
        imageFile: imageFile,
        folder: 'events/${event.organisateurId}',
      );

      List<String> additionalUrls = [];
      if (additionalImages != null && additionalImages.isNotEmpty) {
        final responses = await CloudinaryService.uploadMultipleImages(
          images: additionalImages,
          folder: 'events/${event.organisateurId}',
        );
        additionalUrls = responses.map((r) => r.secureUrl).toList();
      }

      final docRef = _firestore.collection(_collection).doc();
      final newEvent = EventModel(
        id: docRef.id,
        titre: event.titre,
        description: event.description,
        organisateurId: event.organisateurId,
        organisateurNom: event.organisateurNom,
        organisateurPhoto: event.organisateurPhoto,
        categorie: event.categorie,
        imageUrl: imageResponse.secureUrl,
        imagesUrls: additionalUrls,
        dateDebut: event.dateDebut,
        dateFin: event.dateFin,
        location: event.location,
        prix: event.prix,
        capaciteMax: event.capaciteMax,
        tags: event.tags,
        isPremium: event.isPremium,
        createdAt: DateTime.now(),
      );

      await docRef.set(newEvent.toMap());
      return newEvent;
    } catch (e) {
      throw Exception('Erreur création événement: $e');
    }
  }

  // ==================== READ ====================

  // ✅ VERSION SIMPLE: charge TOUT sans filtre complexe
  Future<List<EventModel>> getEvents({
    int limit = 20,
    DocumentSnapshot? lastDocument,
    EventCategory? category,
    EventStatus status = EventStatus.actif,
  }) async {
    try {
      debugLog('📥 Chargement événements...');

      // ✅ AUCUN filtre Firestore → pas d'index requis
      final snapshot = await _firestore
          .collection(_collection)
          .limit(100)
          .get();

      debugLog('📦 ${snapshot.docs.length} documents trouvés dans Firestore');

      if (snapshot.docs.isEmpty) {
        debugLog('⚠️ Collection "events" vide ou inexistante');
        return [];
      }

      // Parser tous les documents
      final allEvents = <EventModel>[];
      for (final doc in snapshot.docs) {
        try {
          final event = EventModel.fromMap(doc.data(), doc.id);
          allEvents.add(event);
          debugLog('✅ Event parsé: ${event.titre} | status: ${event.status.name} | date: ${event.dateDebut}');
        } catch (e) {
          debugLog('❌ Erreur parsing doc ${doc.id}: $e');
        }
      }

      debugLog('📊 Total parsés: ${allEvents.length}');

      // Filtres côté client
      var filtered = allEvents;

      // Filtre status
      filtered = filtered
          .where((e) => e.status == status)
          .toList();
      debugLog('📊 Après filtre status(${status.name}): ${filtered.length}');

      // Filtre catégorie
      if (category != null) {
        filtered = filtered
            .where((e) => e.categorie == category)
            .toList();
        debugLog('📊 Après filtre catégorie: ${filtered.length}');
      }

      // Trier par date
      filtered.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));

      debugLog('✅ Événements retournés: ${filtered.length}');
      return filtered;
    } catch (e) {
      debugLog('❌ Erreur getEvents: $e');
      throw Exception('Erreur: $e');
    }
  }

  void debugLog(String msg) {
    // ignore: avoid_print
    print(msg);
  }

  // ✅ Featured Events - Sans filtre date
  Stream<List<EventModel>> getFeaturedEvents() {
    return _firestore
        .collection(_collection)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      debugLog('🌟 Featured: ${snapshot.docs.length} docs');

      final events = <EventModel>[];
      for (final doc in snapshot.docs) {
        try {
          final event = EventModel.fromMap(doc.data(), doc.id);
          events.add(event);
        } catch (e) {
          debugLog('❌ Featured parse error: $e');
        }
      }

      // Filtres côté client
      final featured = events
          .where((e) =>
              e.isPremium &&
              e.status == EventStatus.actif)
          .toList();

      featured.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));
      debugLog('🌟 Featured filtrés: ${featured.length}');

      return featured.take(5).toList();
    });
  }

  // Stream temps réel d'un événement
  Stream<EventModel?> getEventStream(String eventId) {
    return _firestore
        .collection(_collection)
        .doc(eventId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return EventModel.fromMap(doc.data()!, doc.id);
    });
  }

  // Events organisateur
  Stream<List<EventModel>> getOrganizerEvents(String organizerId) {
    return _firestore
        .collection(_collection)
        .where('organisateurId', isEqualTo: organizerId)
        .snapshots()
        .map((snapshot) {
      final events = snapshot.docs
          .map((doc) => EventModel.fromMap(doc.data(), doc.id))
          .toList();
      events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return events;
    });
  }

  // Recherche côté client
  Future<List<EventModel>> searchEvents(String query) async {
    if (query.isEmpty) return [];

    try {
      final snapshot = await _firestore
          .collection(_collection)
          .limit(100)
          .get();

      final lowerQuery = query.toLowerCase().trim();

      return snapshot.docs
          .map((doc) => EventModel.fromMap(doc.data(), doc.id))
          .where((e) =>
              e.status == EventStatus.actif &&
              (e.titre.toLowerCase().contains(lowerQuery) ||
               e.description.toLowerCase().contains(lowerQuery) ||
               e.location.ville.toLowerCase().contains(lowerQuery) ||
               e.tags.any((t) =>
                   t.toLowerCase().contains(lowerQuery))))
          .toList();
    } catch (e) {
      throw Exception('Erreur recherche: $e');
    }
  }

  Future<List<EventModel>> getFavoriteEvents(
      List<String> eventIds) async {
    if (eventIds.isEmpty) return [];

    final snapshots = await Future.wait(
      eventIds.map(
        (id) => _firestore.collection(_collection).doc(id).get(),
      ),
    );

    return snapshots
        .where((doc) => doc.exists)
        .map((doc) => EventModel.fromMap(doc.data()!, doc.id))
        .toList();
  }

  Future<void> updateEvent(
      EventModel event, {File? newImage}) async {
    try {
      Map<String, dynamic> updateData = event.toMap();
      if (newImage != null) {
        final response = await CloudinaryService.uploadImage(
          imageFile: newImage,
          folder: 'events/${event.organisateurId}',
        );
        updateData['imageUrl'] = response.secureUrl;
      }
      await _firestore
          .collection(_collection)
          .doc(event.id)
          .update(updateData);
    } catch (e) {
      throw Exception('Erreur mise à jour: $e');
    }
  }

  Future<void> incrementParticipants(
      String eventId, int count) async {
    await _firestore
        .collection(_collection)
        .doc(eventId)
        .update({
      'nombreParticipants': FieldValue.increment(count),
    });
  }

  Future<void> toggleFavorite(
    String userId,
    String eventId,
    bool isFav,
  ) async {
    await _firestore.collection('users').doc(userId).update({
      'favorisIds': isFav
          ? FieldValue.arrayUnion([eventId])
          : FieldValue.arrayRemove([eventId]),
    });
  }

  Future<void> deleteEvent(String eventId) async {
    await _firestore
        .collection(_collection)
        .doc(eventId)
        .update({'status': EventStatus.annule.name});
  }
}