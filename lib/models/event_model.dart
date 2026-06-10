// lib/models/event_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String titre;
  final String description;
  final String organisateurId;
  final String organisateurNom;
  final String? organisateurPhoto;
  final EventCategory categorie;
  final String imageUrl;
  final List<String> imagesUrls;
  final DateTime dateDebut;
  final DateTime dateFin;
  final EventLocation location;
  final double prix;
  final int capaciteMax;
  final int nombreParticipants;
  final EventStatus status;
  final List<String> tags;
  final bool isPremium;
  final DateTime createdAt;
  final double? rating;
  final int nombreAvis;

  EventModel({
    required this.id,
    required this.titre,
    required this.description,
    required this.organisateurId,
    required this.organisateurNom,
    this.organisateurPhoto,
    required this.categorie,
    required this.imageUrl,
    this.imagesUrls = const [],
    required this.dateDebut,
    required this.dateFin,
    required this.location,
    this.prix = 0.0,
    required this.capaciteMax,
    this.nombreParticipants = 0,
    this.status = EventStatus.actif,
    this.tags = const [],
    this.isPremium = false,
    required this.createdAt,
    this.rating,
    this.nombreAvis = 0,
  });

  bool get isGratuit => prix == 0.0;
  bool get isComplet => nombreParticipants >= capaciteMax;

  // ✅ FIX: "isPassé" → "isPasse" (caractère illégal é supprimé)
  bool get isPasse => dateFin.isBefore(DateTime.now());
  int get placesRestantes => capaciteMax - nombreParticipants;

  factory EventModel.fromMap(Map<String, dynamic> map, String id) {
    return EventModel(
      id: id,
      titre: map['titre'] ?? '',
      description: map['description'] ?? '',
      organisateurId: map['organisateurId'] ?? '',
      organisateurNom: map['organisateurNom'] ?? '',
      organisateurPhoto: map['organisateurPhoto'],
      categorie: EventCategory.values.firstWhere(
        (e) => e.name == map['categorie'],
        orElse: () => EventCategory.autre,
      ),
      imageUrl: map['imageUrl'] ?? '',
      imagesUrls: List<String>.from(map['imagesUrls'] ?? []),
      dateDebut: (map['dateDebut'] as Timestamp).toDate(),
      dateFin: (map['dateFin'] as Timestamp).toDate(),
      location: EventLocation.fromMap(map['location'] ?? {}),
      prix: (map['prix'] ?? 0.0).toDouble(),
      capaciteMax: map['capaciteMax'] ?? 0,
      nombreParticipants: map['nombreParticipants'] ?? 0,
      status: EventStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => EventStatus.actif,
      ),
      tags: List<String>.from(map['tags'] ?? []),
      isPremium: map['isPremium'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      rating: (map['rating'] as num?)?.toDouble(),
      nombreAvis: map['nombreAvis'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titre': titre,
      'description': description,
      'organisateurId': organisateurId,
      'organisateurNom': organisateurNom,
      'organisateurPhoto': organisateurPhoto,
      'categorie': categorie.name,
      'imageUrl': imageUrl,
      'imagesUrls': imagesUrls,
      'dateDebut': Timestamp.fromDate(dateDebut),
      'dateFin': Timestamp.fromDate(dateFin),
      'location': location.toMap(),
      'prix': prix,
      'capaciteMax': capaciteMax,
      'nombreParticipants': nombreParticipants,
      'status': status.name,
      'tags': tags,
      'isPremium': isPremium,
      'createdAt': Timestamp.fromDate(createdAt),
      'rating': rating,
      'nombreAvis': nombreAvis,
    };
  }

  EventModel copyWith({
    String? titre,
    String? description,
    String? imageUrl,
    EventStatus? status,
  }) {
    return EventModel(
      id: id,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      organisateurId: organisateurId,
      organisateurNom: organisateurNom,
      organisateurPhoto: organisateurPhoto,
      categorie: categorie,
      imageUrl: imageUrl ?? this.imageUrl,
      imagesUrls: imagesUrls,
      dateDebut: dateDebut,
      dateFin: dateFin,
      location: location,
      prix: prix,
      capaciteMax: capaciteMax,
      nombreParticipants: nombreParticipants,
      status: status ?? this.status,
      tags: tags,
      isPremium: isPremium,
      createdAt: createdAt,
      rating: rating,
      nombreAvis: nombreAvis,
    );
  }
}

class EventLocation {
  final String adresse;
  final String ville;
  final String pays;
  final double latitude;
  final double longitude;
  final String? salleNom;

  EventLocation({
    required this.adresse,
    required this.ville,
    required this.pays,
    required this.latitude,
    required this.longitude,
    this.salleNom,
  });

  String get fullAddress => '$adresse, $ville, $pays';

  factory EventLocation.fromMap(Map<String, dynamic> map) {
    return EventLocation(
      adresse: map['adresse'] ?? '',
      ville: map['ville'] ?? '',
      pays: map['pays'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      salleNom: map['salleNom'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'adresse': adresse,
      'ville': ville,
      'pays': pays,
      'latitude': latitude,
      'longitude': longitude,
      'salleNom': salleNom,
      'geopoint': GeoPoint(latitude, longitude),
    };
  }
}

enum EventCategory {
  concert,
  soiree,
  rencontre,
  jeux,
  sport,
  culture,
  festival,
  conference,
  atelier,
  autre,
}

enum EventStatus {
  actif,
  annule,
  complet,
  termine,
  brouillon,
}