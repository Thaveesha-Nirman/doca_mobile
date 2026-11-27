import '../models/community_post.dart';

abstract class CommunityPostRepository {
  Future<List<CommunityPost>> fetchPosts();
}
