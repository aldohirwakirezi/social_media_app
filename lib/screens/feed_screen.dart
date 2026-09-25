// Kirezi
// 2401000842
// 23/9/2026


import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/post.dart';
import '../services/post_service.dart';
import '../services/storage_service.dart';
import '../widgets/post_card.dart';
import '../widgets/banner_ad_widget.dart';
import 'create_post_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final PostService _postService = PostService();
  final StorageService _storageService = StorageService();

  late final Stream<List<Post>> _postsStream;

  @override
  void initState() {
    super.initState();
    _postsStream = _postService.watchPosts();
  }

  Future<void> _handleEdit(Post post) async {
  }

  Future<void> _handleDelete(Post post) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text(
          'This will permanently remove the post.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (post.imageUrl != null) {
        await _storageService.deleteImage(post.imageUrl!);
      }

      await _postService.deletePost(post.id);
    } on StorageException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
          ),
        );
      }
    } on PostException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<List<Post>>(
          stream: _postsStream,
          builder: (context, snapshot) {
            final int count = snapshot.data?.length ?? 0;

            return Text('Social Feed ($count)');
          },
        ),
      ),
      bottomNavigationBar: const BannerAdWidget(),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create post',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreatePostScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Post>>(
        stream: _postsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Please check your internet connection and try again.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final List<Post> posts = snapshot.data ?? <Post>[];

          if (posts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Welcome! No posts yet. Tap + to create the first post.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final Post post = posts[index];

              final String? currentUid =
                  FirebaseAuth.instance.currentUser?.uid;

              final bool isOwner = post.authorId == currentUid;

              return PostCard(
                post: post,
                isOwner: isOwner,
                onEdit: isOwner
                    ? () => _handleEdit(post)
                    : null,
                onDelete: isOwner
                    ? () => _handleDelete(post)
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}