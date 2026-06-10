// lib/services/notification_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  // ✅ FIX: Suppression du champ _firestore inutilisé

  Future<void> initialize(BuildContext context) async {
    await _requestPermission();
    await _saveDeviceToken();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // ✅ FIX: Vérification mounted avant d'utiliser le contexte
      if (context.mounted) {
        _showLocalNotification(context, message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (context.mounted) {
        _handleNotificationTap(context, message);
      }
    });
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _saveDeviceToken() async {
    final token = await _messaging.getToken();
    if (token != null) {
      // ✅ FIX: Suppression du print en production
      debugPrint('FCM Token: $token');
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  void _showLocalNotification(BuildContext context, RemoteMessage message) {
    final notification = message.notification;
    if (notification != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.title ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(notification.body ?? ''),
            ],
          ),
          backgroundColor: const Color(0xFF6C63FF),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _handleNotificationTap(BuildContext context, RemoteMessage message) {
    final data = message.data;
    if (data['type'] == 'event') {
      // Navigation vers l'événement
      debugPrint('Navigate to event: ${data['eventId']}');
    }
  }
}