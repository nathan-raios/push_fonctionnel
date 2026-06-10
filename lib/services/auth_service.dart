// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream de l'état d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Utilisateur courant
  User? get currentUser => _auth.currentUser;

  // Inscription
  Future<UserModel> register({
    required String nom,
    required String prenom,
    required String email,
    required String password,
    UserRole role = UserRole.participant,
  }) async {
    try {
      // Créer le compte Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;
      
      // Mettre à jour le profil
      await user.updateDisplayName('$prenom $nom');

      // Créer le document dans Firestore
      final userModel = UserModel(
        id: user.uid,
        nom: nom,
        prenom: prenom,
        email: email,
        role: role,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userModel.toMap());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Connexion
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      return await getUserById(credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Déconnexion
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Réinitialisation mot de passe
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Récupérer un utilisateur par ID
  Future<UserModel> getUserById(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) throw Exception('Utilisateur non trouvé');
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  // Mettre à jour le profil
  Future<void> updateProfile(UserModel user) async {
    await _firestore
        .collection('users')
        .doc(user.id)
        .update(user.toMap());
  }

  // Gestion des erreurs Firebase Auth
  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return Exception('Le mot de passe est trop faible');
      case 'email-already-in-use':
        return Exception('Cet email est déjà utilisé');
      case 'user-not-found':
        return Exception('Aucun compte avec cet email');
      case 'wrong-password':
        return Exception('Mot de passe incorrect');
      case 'invalid-email':
        return Exception('Email invalide');
      case 'user-disabled':
        return Exception('Ce compte a été désactivé');
      default:
        return Exception('Erreur: ${e.message}');
    }
  }
}