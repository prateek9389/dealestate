import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/utils/error_handler.dart';

class CloudinaryService {
  final String? cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
  final String? uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'];

  // Upload Image to Cloudinary via REST API to avoid exposing secrets
  Future<String?> uploadImage(File file) async {
    return _uploadMedia(file, 'image');
  }

  // Upload Video to Cloudinary
  Future<String?> uploadVideo(File file) async {
    return _uploadMedia(file, 'video');
  }

  // Helper method to upload media
  Future<String?> _uploadMedia(File file, String resourceType) async {
    if (cloudName == null || uploadPreset == null) {
      ErrorHandler.handleError('Cloudinary config missing', null);
      return null;
    }

    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload',
      );
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset!
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final Map<String, dynamic> data = json.decode(responseData);
        return data['secure_url']; // Returns secure URL over HTTPS
      } else {
        ErrorHandler.handleError(
          'Upload failed with status: ${response.statusCode}',
          null,
        );
      }
    } catch (e) {
      ErrorHandler.handleError('Cloudinary Upload Error', e);
    }
    return null;
  }

  // Note: Deleting media from client usually requires API Secret which should not be exposed.
  // It is highly recommended to do deletions via Cloud Functions backend.
  // Here is a placeholder if a backend endpoint was configured.
  Future<bool> deleteMedia(String publicId) async {
    try {
      // To properly delete securely:
      // Call a Firebase Cloud function that securely uses CLOUDINARY_API_SECRET
      // E.g., final response = await http.post('your-cloud-function-url', body: {'public_id': publicId});
      return false; // Implement securely via cloud functions
    } catch (e) {
      ErrorHandler.handleError('Delete Media Error', e);
      return false;
    }
  }
}
