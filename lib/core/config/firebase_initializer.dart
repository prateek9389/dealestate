import 'package:firebase_core/firebase_core.dart';
import 'app_env.dart';

class FirebaseInitializer {
  static Future<void> init() async {
    try {
      // For web and mobile, it's safer to provide options directly if google-services.json isn't present
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: AppEnv.firebaseApiKey,
          appId: AppEnv.firebaseAppId,
          messagingSenderId: AppEnv.firebaseMessagingSenderId,
          projectId: AppEnv.firebaseProjectId,
          storageBucket: AppEnv.firebaseStorageBucket,
        ),
      );
    } catch (e) {
      if (e is FirebaseException && e.code == 'duplicate-app') {
        // Safe to ignore, app is already initialized
      } else {
        rethrow;
      }
    }
  }
}
