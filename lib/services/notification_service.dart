import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/utils/error_handler.dart';
import '../models/notification_model.dart';
import '../services/auth_service.dart';

import 'dart:async';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  StreamSubscription<QuerySnapshot>? _userNotificationsSub;
  StreamSubscription<QuerySnapshot>? _adminNotificationsSub;

  Future<void> initializeFCM() async {
    try {
      const AndroidInitializationSettings androidSettings = 
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings = 
          InitializationSettings(android: androidSettings);
      
      await _localNotifications.initialize(
        settings: initSettings,
      );

      // 2. Request Permissions
      await requestPermissions();
      
      // 3. Setup Listeners
      listenForegroundMessages();
      listenForFirestoreNotifications(); // Added Firestore listener for immediate alerts

      final token = await _fcm.getToken();
      if (token != null) {
        final user = _auth.currentUser;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'fcmToken': token,
          });
        }
      }
    } catch (e) {
      ErrorHandler.handleError('FCM Initialization Error', e);
    }
  }

  Future<void> requestPermissions() async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void listenForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showLocalNotification(
          title: message.notification!.title ?? 'New Alert',
          body: message.notification!.body ?? '',
        );
      }
    });
  }

  // Listen to Firestore for new notifications to show in System Bar immediately
  void listenForFirestoreNotifications() {
    _auth.authStateChanges().listen((user) {
      _userNotificationsSub?.cancel();
      _adminNotificationsSub?.cancel();

      if (user == null) return;

      final String targetId = user.uid;

      _userNotificationsSub = _firestore
          .collection('users')
          .doc(targetId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .snapshots()
          .listen((snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data();
            if (data != null) {
              final note = NotificationModel.fromMap(data, change.doc.id);
              // Throttle: only show if it was created in the last minute
              if (note.timestamp.isAfter(DateTime.now().subtract(const Duration(seconds: 30)))) {
                 showLocalNotification(title: note.title, body: note.body);
              }
            }
          }
        }
      });

      // Also listen for Admin if applicable
      AuthService().getUserRole().then((role) {
        if (role == 'admin') {
           _adminNotificationsSub = _firestore
              .collection('users')
              .doc('admin')
              .collection('notifications')
              .where('isRead', isEqualTo: false)
              .snapshots()
              .listen((snapshot) {
            for (var change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                final data = change.doc.data();
                if (data != null) {
                  final note = NotificationModel.fromMap(data, change.doc.id);
                  if (note.timestamp.isAfter(DateTime.now().subtract(const Duration(seconds: 30)))) {
                     showLocalNotification(title: note.title, body: note.body);
                  }
                }
              }
            }
          });
        }
      });
    });
  }

  Future<void> showLocalNotification({required String title, required String body}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'deal_estate_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );
    
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    
    await _localNotifications.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }

  Future<void> sendNotification(String userId, NotificationModel notification) async {
    try {
      // Get user preferences
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      
      // Save to Firestore (Real-time notifications)
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add(notification.toMap());
      
      // Mock Push Notification (if enabled)
      if (userData?['pushEnabled'] != false) {
         if (kDebugMode) print("Push notification triggered for $userId");
      }

      // Mock Email Notification (if enabled)
      if (userData?['emailEnabled'] == true) {
        await sendEmailNotification(userData?['email'] ?? '', notification.title, notification.body);
      }
    } catch (e) {
      ErrorHandler.handleError('Send Notification Error', e);
    }
  }

  Future<void> sendEmailNotification(String email, String title, String body) async {
    // In a real app, integrate with an Email API (SendGrid, Mailgun, etc.)
    if (kDebugMode) {
      print("Sending EMAIL to $email: [$title] $body");
    }
  }

  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();
      
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      ErrorHandler.handleError('Mark All Read Error', e);
    }
  }
}
