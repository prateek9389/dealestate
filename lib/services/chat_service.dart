import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/notification_model.dart';
import './notification_service.dart';
import '../core/utils/error_handler.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createChat(String userId, String adminId) async {
    try {
      // Check if chat already exists
      final querySnapshot = await _firestore
          .collection('chats')
          .where('userId', isEqualTo: userId)
          .where('adminId', isEqualTo: adminId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }

      // Create new chat
      final docRef = _firestore.collection('chats').doc();
      final newChat = ChatModel(
        id: docRef.id,
        userId: userId,
        adminId: adminId,
        lastMessage: 'Chat started',
        updatedAt: DateTime.now(),
      );

      await docRef.set(newChat.toMap());
      return docRef.id;
    } catch (e) {
      ErrorHandler.handleError('Create Chat Error', e);
      rethrow;
    }
  }

  Future<void> sendMessage(String chatId, MessageModel message) async {
    try {
      final docRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(message.id);

      await _firestore.runTransaction((transaction) async {
        transaction.set(docRef, message.toMap());
        transaction.update(_firestore.collection('chats').doc(chatId), {
          'lastMessage': message.text.isEmpty ? 'Image 📷' : message.text,
          'updatedAt': DateTime.now(),
          if (message.receiverId == 'admin') 
            'unreadCountAdmin': FieldValue.increment(1)
          else 
            'unreadCountUser': FieldValue.increment(1),
        });
      });

      final notification = NotificationModel(
        id: '',
        title: message.senderId == 'admin' ? 'Broker Message' : 'New Client Message',
        body: message.text.isEmpty ? 'Sent an image 📷' : message.text,
        type: 'message',
        timestamp: DateTime.now(),
        isRead: false,
        relatedId: chatId,
      );

      // Send to the recipient (User or 'admin')
      NotificationService().sendNotification(message.receiverId, notification);
    } catch (e) {
      ErrorHandler.handleError('Send Message Error', e);
      rethrow;
    }
  }

  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<ChatModel>> getUserChats(String userId, {String role = 'user'}) {
    final queryField = role == 'admin' ? 'adminId' : 'userId';

    return _firestore
        .collection('chats')
        .where(queryField, isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) {
            final chats = snapshot.docs
              .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
              .toList();
            
            // Sort: Unread messages first, then by most recent update
            chats.sort((a, b) {
              final aUnread = role == 'admin' ? a.unreadCountAdmin : a.unreadCountUser;
              final bUnread = role == 'admin' ? b.unreadCountAdmin : b.unreadCountUser;
              
              if (aUnread > 0 && bUnread == 0) return -1;
              if (aUnread == 0 && bUnread > 0) return 1;
              
              return b.updatedAt.compareTo(a.updatedAt);
            });
            return chats;
          },
        );
  }

  Future<void> markAsRead(String chatId, String userId) async {
    try {
      final user = await _firestore.collection('users').doc(userId).get();
      final isAdmin = user.data()?['role'] == 'admin' || userId == 'admin';

      await _firestore.collection('chats').doc(chatId).update({
        if (isAdmin) 'unreadCountAdmin': 0 else 'unreadCountUser': 0,
      });

      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: isAdmin ? 'admin' : userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'isDelivered': true, // Reading implies delivered
        });
      }
      await batch.commit();
    } catch (e) {
      ErrorHandler.handleError('Mark As Read Error', e);
    }
  }

  Future<void> markAsDelivered(String chatId, String userId) async {
    try {
      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .where('isDelivered', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.update(doc.reference, {'isDelivered': true});
      }
      await batch.commit();
    } catch (e) {
      ErrorHandler.handleError('Mark As Delivered Error', e);
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      final batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_firestore.collection('chats').doc(chatId));
      await batch.commit();
    } catch (e) {
      ErrorHandler.handleError('Delete Chat Error', e);
      rethrow;
    }
  }

  Future<int> getTotalUnreadCount(String userId, {String role = 'user'}) async {
    final queryField = role == 'admin' ? 'adminId' : 'userId';
    final countField = role == 'admin' ? 'unreadCountAdmin' : 'unreadCountUser';

    try {
      final snapshot = await _firestore
          .collection('chats')
          .where(queryField, isEqualTo: userId)
          .get();
          
      int total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()[countField] as num? ?? 0).toInt();
      }
      return total;
    } catch (e) {
      ErrorHandler.handleError('Get Total Unread Count Error', e);
      return 0;
    }
  }

  Stream<int> getTotalUnreadCountStream(String userId, {String role = 'user'}) {
    final queryField = role == 'admin' ? 'adminId' : 'userId';
    final countField = role == 'admin' ? 'unreadCountAdmin' : 'unreadCountUser';

    return _firestore
        .collection('chats')
        .where(queryField, isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()[countField] as num? ?? 0).toInt();
      }
      return total;
    });
  }
}
