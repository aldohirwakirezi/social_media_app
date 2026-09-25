
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post.dart';

class PostService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _postsRef =>
      _db.collection('posts');

  Future<void> createPost({
    required String text,
    String? imageUrl,
  }) async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw const PostException(
        'You must be signed in to create a post.',
      );
    }

    if (text.trim().isEmpty) {
      throw const PostException(
        'Post text cannot be empty.',
      );
    }

    try {
      await _postsRef.add({
        'authorId': user.uid,
        'authorEmail': user.email ?? 'Unknown',
        'text': text.trim(),
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw PostException(_messageFor(e));
    } catch (_) {
      throw const PostException(
        'Could not create the post. Please try again.',
      );
    }
  }

  Stream<List<Post>> watchPosts() {
    return _postsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) {
            return snapshot.docs.map(Post.fromFirestore).toList();
          },
        );
  }

  Future<void> updatePost({
    required String postId,
    required String newText,
  }) async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw const PostException(
        'You must be signed in to update a post.',
      );
    }

    if (newText.trim().isEmpty) {
      throw const PostException(
        'Post text cannot be empty.',
      );
    }

    try {
      await _postsRef.doc(postId).update({
        'text': newText.trim(),
      });
    } on FirebaseException catch (e) {
      throw PostException(_messageFor(e));
    } catch (_) {
      throw const PostException(
        'Could not update the post. Please try again.',
      );
    }
  }

  Future<void> deletePost(String postId) async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw const PostException(
        'You must be signed in to delete a post.',
      );
    }

    try {
      await _postsRef.doc(postId).delete();
    } on FirebaseException catch (e) {
      throw PostException(_messageFor(e));
    } catch (_) {
      throw const PostException(
        'Could not delete the post. Please try again.',
      );
    }
  }

  String _messageFor(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'You do not have permission to do that.';
      case 'unavailable':
        return 'Please check your internet connection and try again.';
      case 'not-found':
        return 'That post no longer exists.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}

class PostException implements Exception {
  final String message;

  const PostException(this.message);

  @override
  String toString() => message;
}