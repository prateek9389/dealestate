import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/seller_submission_model.dart';
import '../models/buyer_requirement_model.dart';
import '../models/admin_post_model.dart';
import '../models/notification_model.dart';
import './notification_service.dart';
import '../core/utils/error_handler.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- USERS ---
  Future<int> getUserCount() async {
    try {
      final snapshot = await _firestore.collection('users').count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      ErrorHandler.handleError('Get User Count Error', e);
      return 0;
    }
  }

  // --- SELLER SUBMISSIONS ---

  Future<void> submitProperty(SellerSubmissionModel submission) async {
    try {
      await _firestore
          .collection('seller_submissions')
          .doc(submission.id)
          .set(submission.toMap());

      // Notify Admin
      final notification = NotificationModel(
        id: '',
        title: 'New Property Lead',
        body: '${submission.userName} submitted a new ${submission.propertyType} in ${submission.location}.',
        type: 'property',
        timestamp: DateTime.now(),
        isRead: false,
        relatedId: submission.id,
      );
      await NotificationService().sendNotification('admin', notification);
    } catch (e) {
      ErrorHandler.handleError('Submit Property Error', e);
      rethrow;
    }
  }

  Future<List<SellerSubmissionModel>> getUserSubmissions(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('seller_submissions')
          .where('userId', isEqualTo: userId)
          .get();

      return querySnapshot.docs
          .map((doc) => SellerSubmissionModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      ErrorHandler.handleError('Get User Submissions Error', e);
      return [];
    }
  }

  Future<List<SellerSubmissionModel>> getAllSellerSubmissions() async {
    try {
      final querySnapshot = await _firestore
          .collection('seller_submissions')
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs
          .map((doc) => SellerSubmissionModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      ErrorHandler.handleError('Get All Seller Submissions Error', e);
      return [];
    }
  }

  Future<void> approveSubmission(String collection, String submissionId) async {
    try {
      final doc = await _firestore.collection(collection).doc(submissionId).get();
      if (!doc.exists) return;
      final userId = doc.data()?['userId'];

      await _firestore.collection(collection).doc(submissionId).update({
        'status': 'approved',
      });

      if (userId != null) {
        final notification = NotificationModel(
          id: '',
          title: 'Submission Approved',
          body: 'Your property submission has been approved and moved to public listings.',
          type: 'property',
          timestamp: DateTime.now(),
          isRead: false,
          relatedId: submissionId,
        );
        NotificationService().sendNotification(userId, notification);
      }
    } catch (e) {
      ErrorHandler.handleError('Approve Submission Error', e);
      rethrow;
    }
  }

  Future<void> rejectSubmission(String collection, String submissionId) async {
    try {
      final doc = await _firestore.collection(collection).doc(submissionId).get();
      if (!doc.exists) return;
      final userId = doc.data()?['userId'];

      await _firestore.collection(collection).doc(submissionId).update({
        'status': 'rejected',
      });

      if (userId != null) {
        final notification = NotificationModel(
          id: '',
          title: 'Submission Rejected',
          body: 'Your property submission was rejected. Please contact support for details.',
          type: 'property',
          timestamp: DateTime.now(),
          isRead: false,
          relatedId: submissionId,
        );
        NotificationService().sendNotification(userId, notification);
      }
    } catch (e) {
      ErrorHandler.handleError('Reject Submission Error', e);
      rethrow;
    }
  }

  Future<void> deleteSellerSubmission(String docId) async {
    try {
      await _firestore.collection('seller_submissions').doc(docId).delete();
    } catch (e) {
      ErrorHandler.handleError('Delete Seller Submission Error', e);
      rethrow;
    }
  }

  // --- BUYER REQUIREMENTS ---

  Future<void> submitRequirement(BuyerRequirementModel requirement) async {
    try {
      await _firestore
          .collection('buyer_requirements')
          .doc(requirement.id)
          .set(requirement.toMap());

      // Notify Admin
      final notification = NotificationModel(
        id: '',
        title: 'New Buyer Requirement',
        body: '${requirement.userName} is looking for a ${requirement.propertyType} in ${requirement.preferredLocation}.',
        type: 'property',
        timestamp: DateTime.now(),
        isRead: false,
        relatedId: requirement.id,
      );
      await NotificationService().sendNotification('admin', notification);
    } catch (e) {
      ErrorHandler.handleError('Submit Requirement Error', e);
      rethrow;
    }
  }

  Future<List<BuyerRequirementModel>> getAllBuyerRequirements() async {
    try {
      final querySnapshot = await _firestore
          .collection('buyer_requirements')
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs
          .map((doc) => BuyerRequirementModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      ErrorHandler.handleError('Get All Buyer Requirements Error', e);
      return [];
    }
  }

  Future<void> deleteBuyerRequirement(String docId) async {
    try {
      await _firestore.collection('buyer_requirements').doc(docId).delete();
    } catch (e) {
      ErrorHandler.handleError('Delete Buyer Requirement Error', e);
      rethrow;
    }
  }

  Future<int> getAdminPostCount() async {
    try {
      final snapshot = await _firestore.collection('admin_posts').get();
      return snapshot.docs.length;
    } catch (e) {
      ErrorHandler.handleError('Get Admin Post Count Error', e);
      return 0;
    }
  }

  // --- ADMIN POSTS ---

  Future<void> createAdminPost(AdminPostModel adminPost) async {
    try {
      await _firestore
          .collection('admin_posts')
          .doc(adminPost.id)
          .set(adminPost.toMap());
      // For global notifications, usually cloud functions are used.
      // Skipping per-user notification here to avoid performance issues.
    } catch (e) {
      ErrorHandler.handleError('Create Admin Post Error', e);
      rethrow;
    }
  }

  Future<List<AdminPostModel>> getAdminPosts() async {
    try {
      final querySnapshot = await _firestore
          .collection('admin_posts')
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs
          .map((doc) => AdminPostModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      ErrorHandler.handleError('Get Admin Posts Error', e);
      return [];
    }
  }

  Future<AdminPostModel?> getAdminPostById(String id) async {
    try {
      final doc = await _firestore.collection('admin_posts').doc(id).get();
      if (doc.exists && doc.data() != null) {
        return AdminPostModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      ErrorHandler.handleError('Get Admin Post By Id Error', e);
      return null;
    }
  }

  Stream<List<AdminPostModel>> getAdminPostsStream() {
    return _firestore
        .collection('admin_posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AdminPostModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> deleteAdminPost(String postId) async {
    try {
      await _firestore.collection('admin_posts').doc(postId).delete();
    } catch (e) {
      ErrorHandler.handleError('Delete Admin Post Error', e);
      rethrow;
    }
  }

  Stream<List<SellerSubmissionModel>> getUserSubmissionsStream(String userId) {
    return _firestore
        .collection('seller_submissions')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => SellerSubmissionModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<BuyerRequirementModel>> getUserRequirementsStream(String userId) {
    return _firestore
        .collection('buyer_requirements')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => BuyerRequirementModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<void> toggleFavorite(String userId, String propertyId) async {
    try {
      final userDoc = _firestore.collection('users').doc(userId);
      final doc = await userDoc.get();
      if (doc.exists) {
        List<String> favorites = List<String>.from(doc.data()?['savedPropertyIds'] ?? []);
        if (favorites.contains(propertyId)) {
          await userDoc.update({
            'savedPropertyIds': FieldValue.arrayRemove([propertyId])
          });
        } else {
          await userDoc.update({
            'savedPropertyIds': FieldValue.arrayUnion([propertyId])
          });
        }
      }
    } catch (e) {
      ErrorHandler.handleError('Toggle Favorite Error', e);
    }
  }

  Stream<List<AdminPostModel>> getSavedPropertiesStream(List<String> propertyIds) {
    if (propertyIds.isEmpty) return Stream.value([]);
    return _firestore
        .collection('admin_posts')
        .where(FieldPath.documentId, whereIn: propertyIds.take(10).toList())
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AdminPostModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
