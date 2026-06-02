import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_model.dart';
import '../core/utils/error_handler.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign up with Name, Email, Phone, Password
  Future<UserModel?> signUp(String name, String email, String phone, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        return await createUserDocument(credential.user!, name, phone: phone);
      }
    } catch (e) {
      ErrorHandler.handleError('SignUp Error', e);
      rethrow;
    }
    return null;
  }

  // Create Firestore Document
  Future<UserModel> createUserDocument(User user, String name, {String phone = ''}) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      await user.updateDisplayName(name);

      final newUser = UserModel(
        id: user.uid,
        name: name,
        email: user.email ?? '',
        phone: phone,
        profilePictureUrl: user.photoURL ?? '',
        role: 'user', // Default role is user
        savedPropertyIds: const [],
        createdAt: DateTime.now(),
      );

      await userDoc.set(newUser.toMap());
      return newUser;
    } catch (e) {
      ErrorHandler.handleError('CreateUserDoc Error', e);
      rethrow;
    }
  }

  // Login
  Future<UserModel?> login(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        return await getCurrentUser();
      }
    } catch (e) {
      ErrorHandler.handleError('Login Error', e);
      rethrow;
    }
    return null;
  }

  // Logout
  Future<void> logout() async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      ErrorHandler.handleError('Logout Error', e);
    }
  }

  // Sign In with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      
      final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
      
      // Initialize with serverClientId for Android
      await googleSignIn.initialize(
        serverClientId: webClientId,
      );
      
      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();
      
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // Check if user document already exists
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          // Create document for new Google user
          return await createUserDocument(user, user.displayName ?? 'Google User');
        }
        final userData = doc.data();
        if (userData != null) {
          final userModel = UserModel.fromMap(userData, doc.id);
          // Block admin access via Google
          if (userModel.role == 'admin') {
            await logout(); // Sign out from Firebase and Google
            throw Exception('Admin accounts must sign in using email and password for security.');
          }
          return userModel;
        }
      }
    } catch (e) {
      ErrorHandler.handleError('Google Sign-In Error', e);
      rethrow;
    }
    return null;
  }

  // Get Current User (Model)
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return UserModel.fromMap(doc.data()!, doc.id);
        }
      }
    } catch (e) {
      ErrorHandler.handleError('GetCurrentUser Error', e);
    }
    return null;
  }

  // Get User Role
  Future<String?> getUserRole() async {
    try {
      final userModel = await getCurrentUser();
      return userModel?.role;
    } catch (e) {
      ErrorHandler.handleError('GetUserRole Error', e);
      return null;
    }
  }

  // Update User Profile
  Future<void> updateUserProfile(String name, String phone, {String? profilePictureUrl}) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final Map<String, dynamic> updateData = {
          'name': name,
          'phone': phone,
        };
        
        if (profilePictureUrl != null) {
          updateData['profilePictureUrl'] = profilePictureUrl;
        }

        await _firestore.collection('users').doc(user.uid).update(updateData);
      }
    } catch (e) {
      ErrorHandler.handleError('UpdateUserProfile Error', e);
      rethrow;
    }
  }

  // Get Any User by ID
  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      ErrorHandler.handleError('GetUserById Error', e);
    }
    return null;
  }

  // Get User Stream
  Stream<UserModel?> getUserStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!, doc.id) : null);
  }

  // Change Password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.email != null) {
        // Validation: New password must be different from common simple patterns
        final simplePatterns = ['123456', 'qwerty', 'password', 'welcome'];
        if (simplePatterns.contains(newPassword.toLowerCase())) {
          throw Exception('Password is too simple. Please use a stronger password.');
        }

        // Re-authenticate user
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPassword);
      } else {
        throw Exception('User session expired or invalid.');
      }
    } catch (e) {
      ErrorHandler.handleError('ChangePassword Error', e);
      rethrow;
    }
  }

  // Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      // 1. Check if email exists in our records first to give better feedback
      final userSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userSnapshot.docs.isEmpty) {
        throw Exception('No account found with this email. Please sign up first.');
      }

      // 2. Send the reset link
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      ErrorHandler.handleError('ResetPassword Error', e);
      rethrow;
    }
  }
}
