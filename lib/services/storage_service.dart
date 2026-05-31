import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
