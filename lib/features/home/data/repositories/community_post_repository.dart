import '../models/community_post.dart';

abstract class CommunityPostRepository {
  Future<List<CommunityPost>> fetchPosts();

  Future<CommunityPost> createPost({
    required String topic,
    required String status,
    required String title,
    required String body,
    required bool isSensitive,
  });
}
