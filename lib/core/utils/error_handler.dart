import 'package:flutter/foundation.dart';

class ErrorHandler {
  static void handleError(String module, dynamic error) {
    if (kDebugMode) {
      print('[ERROR - $module] -> $error');
    }
    // Implement global reporting logic (like Crashlytics) here in future
  }
}
