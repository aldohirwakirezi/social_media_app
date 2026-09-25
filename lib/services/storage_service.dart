
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a post image to:
  /// posts/{userId}/{fileName}
  ///
  /// Returns the Firebase Storage download URL.
  Future<String> uploadPostImage({
    required String userId,
    required File imageFile,
  }) async {
    try {
      // Check that the file exists.
      if (!await imageFile.exists()) {
        throw const StorageException(
          'The selected image could not be found on the device.',
        );
      }

      // Create a unique file name.
      final String originalName = imageFile.path
          .split(Platform.pathSeparator)
          .last;

      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_$originalName';

      // Firebase Storage location.
      final Reference ref = _storage.ref().child(
            'posts/$userId/$fileName',
          );

      print('Starting image upload...');
      print('File: ${imageFile.path}');
      print('Storage path: posts/$userId/$fileName');

      // Upload the file.
      final TaskSnapshot snapshot = await ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: _getContentType(imageFile.path),
        ),
      );

      print('Upload completed: ${snapshot.state}');

      // Get the public/download URL.
      final String downloadUrl = await ref.getDownloadURL();

      print('Download URL obtained successfully.');

      return downloadUrl;
    } on FirebaseException catch (e) {
      print('Firebase Storage error:');
      print('Code: ${e.code}');
      print('Message: ${e.message}');

      throw StorageException(
        'Firebase Storage error (${e.code}): '
        '${e.message ?? "Unknown Firebase error"}',
      );
    } on StorageException {
      rethrow;
    } catch (e) {
      print('Image upload error: $e');

      throw StorageException(
        'Image upload failed: $e',
      );
    }
  }

  /// Determines the correct content type from the image extension.
  String _getContentType(String path) {
    final String extension = path.split('.').last.toLowerCase();

    switch (extension) {
      case 'png':
        return 'image/png';

      case 'webp':
        return 'image/webp';

      case 'gif':
        return 'image/gif';

      case 'heic':
      case 'heif':
        return 'image/heic';

      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  /// Deletes an image from Firebase Storage using its download URL.
  Future<void> deleteImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);

      await ref.delete();

      print('Image deleted successfully.');
    } on FirebaseException catch (e) {
      // If the image has already been deleted,
      // we don't need to show an error.
      if (e.code == 'object-not-found') {
        print('Image was already deleted.');
        return;
      }

      print('Firebase Storage delete error:');
      print('Code: ${e.code}');
      print('Message: ${e.message}');

      throw StorageException(
        'Could not delete image (${e.code}): '
        '${e.message ?? "Unknown error"}',
      );
    } catch (e) {
      throw StorageException(
        'Could not delete image: $e',
      );
    }
  }
}

/// Custom exception for StorageService errors.
class StorageException implements Exception {
  final String message;

  const StorageException(this.message);

  @override
  String toString() => message;
}

