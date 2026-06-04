import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Picks an image from the gallery and uploads it to the given path.
  Future<String?> pickAndUploadImage(String storagePath) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Compress to save bandwidth
        maxWidth: 1024,
      );

      if (image == null) return null;

      if (kIsWeb) {
        final Uint8List bytes = await image.readAsBytes();
        return await uploadFile(bytes, storagePath);
      } else {
        final File file = File(image.path);
        return await uploadFile(file, storagePath);
      }
    } catch (e) {
      debugPrint('StorageService pickAndUpload error: $e');
      return null;
    }
  }

  // ✅ Upload any file and return its download URL
  Future<String?> uploadFile(dynamic file, String storagePath) async {
    try {
      Reference ref = _storage.ref().child(storagePath);
      UploadTask task;

      if (kIsWeb) {
        // Web: file is Uint8List
        task = ref.putData(file as Uint8List);
      } else {
        // Mobile: file is File
        task = ref.putFile(file as File);
      }

      final snapshot = await task;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('StorageService upload error: $e');
      return null;
    }
  }

  // ✅ Upload profile photo
  Future<String?> uploadProfilePhoto(dynamic file, String uid) {
    return uploadFile(file, 'profiles/$uid/photo.jpg');
  }

  // ✅ Upload pizza image
  Future<String?> uploadPizzaImage(dynamic file, String pizzaId) {
    return uploadFile(file, 'pizzas/$pizzaId.jpg');
  }

  // ✅ Upload restaurant logo
  Future<String?> uploadRestaurantLogo(dynamic file, String restaurantId) {
    return uploadFile(file, 'restaurants/$restaurantId/logo.jpg');
  }

  // ✅ Delete a file by its URL
  Future<void> deleteFileByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      debugPrint('StorageService delete error: $e');
    }
  }
}
