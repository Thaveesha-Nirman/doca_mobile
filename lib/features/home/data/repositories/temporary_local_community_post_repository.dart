import '../models/community_post.dart';
import 'community_post_repository.dart';

class TemporaryLocalCommunityPostRepository implements CommunityPostRepository {
  const TemporaryLocalCommunityPostRepository();
  @override
  Future<List<CommunityPost>> fetchPosts() async {
    return const [
      CommunityPost(
        id: 'post_123',
        alias: 'CalmOtter47',
        timeAgo: '12 min ago',
        topic: 'Skin irritation',
        status: 'Asking',
        title: 'Has anyone experienced something similar?',
        body: 'I noticed some mild redness after changing my skincare routine.',
        votes: 24,
        comments: 8,
        isSensitive: false,
       
      ),
      CommunityPost(
        id: 'post_124',
        alias: 'QuietMoon22',
        timeAgo: '1 hr ago',
        topic: 'Recovery journey',
        status: 'Ongoing',
        title: 'Week two of tracking my skin changes',
        body:
            'I have been recording my symptoms and keeping my routine simple.',
        votes: 67,
        comments: 19,
        isSensitive: true,
       
      ),
    ];
  }
}
