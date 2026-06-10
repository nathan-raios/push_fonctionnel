// lib/models/user_model.dart

class UserModel {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String? photoUrl;
  final String? bio;
  final UserRole role;
  final List<String> favorisIds;
  final List<String> preferences; // catégories préférées
  final DateTime createdAt;
  final bool isVerified;

  UserModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    this.photoUrl,
    this.bio,
    this.role = UserRole.participant,
    this.favorisIds = const [],
    this.preferences = const [],
    required this.createdAt,
    this.isVerified = false,
  });

  String get fullName => '$prenom $nom';

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      bio: map['bio'],
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.participant,
      ),
      favorisIds: List<String>.from(map['favorisIds'] ?? []),
      preferences: List<String>.from(map['preferences'] ?? []),
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      isVerified: map['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'photoUrl': photoUrl,
      'bio': bio,
      'role': role.name,
      'favorisIds': favorisIds,
      'preferences': preferences,
      'createdAt': createdAt,
      'isVerified': isVerified,
    };
  }

  UserModel copyWith({
    String? nom,
    String? prenom,
    String? email,
    String? photoUrl,
    String? bio,
    UserRole? role,
    List<String>? favorisIds,
    List<String>? preferences,
    bool? isVerified,
  }) {
    return UserModel(
      id: id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      favorisIds: favorisIds ?? this.favorisIds,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

enum UserRole { participant, organisateur, admin }