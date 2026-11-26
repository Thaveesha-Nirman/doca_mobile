import '../models/community_post.dart';

abstract class CommunityPostRepository {
  Future<CommunityPost> createPost({
    required String topic,
    required String status,
    required String title,
    required String body,
    required bool isSensitive,
  });
}

/// Temporary local implementation until a backend endpoint is available.
class TemporaryLocalCommunityPostRepository implements CommunityPostRepository {
  const TemporaryLocalCommunityPostRepository();

  @override
  Future<CommunityPost> createPost({
    required String topic,
    required String status,
    required String title,
    required String body,
    required bool isSensitive,
  }) async {
    return CommunityPost(
      alias: 'Anonymous',
      timeAgo: 'Just now',
      topic: topic,
      status: status,
      title: title,
      body: body,
      votes: 0,
      comments: 0,
      isSensitive: isSensitive,
    );
  }
}
