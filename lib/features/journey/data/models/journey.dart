import '../../../home/data/models/community_post.dart';

class Journey {
  const Journey({
    required this.id,
    required this.ownerAlias,
    required this.rootPostId,
    required this.privacy,
    required this.posts,
  });

  final String id;
  final String ownerAlias;
  final String rootPostId;
  final String privacy;
  final List<CommunityPost> posts;

  factory Journey.fromJson(Map<String, dynamic> json) {
    final Object? postsValue = json['posts'];

    final List<CommunityPost> parsedPosts;

    if (postsValue is List) {
      parsedPosts = postsValue
          .whereType<Map>()
          .map(
            (postJson) =>
                CommunityPost.fromJson(Map<String, dynamic>.from(postJson)),
          )
          .toList();
    } else {
      parsedPosts = <CommunityPost>[];
    }

    return Journey(
      id: json['id'] as String? ?? '',
      ownerAlias: json['ownerAlias'] as String? ?? '',
      rootPostId: json['rootPostId'] as String? ?? '',
      privacy: json['privacy'] as String? ?? 'Private',
      posts: parsedPosts,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'ownerAlias': ownerAlias,
      'rootPostId': rootPostId,
      'privacy': privacy,
      'posts': posts.map((post) => post.toJson()).toList(),
    };
  }

  Journey copyWith({
    String? id,
    String? ownerAlias,
    String? rootPostId,
    String? privacy,
    List<CommunityPost>? posts,
  }) {
    return Journey(
      id: id ?? this.id,
      ownerAlias: ownerAlias ?? this.ownerAlias,
      rootPostId: rootPostId ?? this.rootPostId,
      privacy: privacy ?? this.privacy,
      posts: posts ?? this.posts,
    );
  }

  CommunityPost? get rootPost {
    for (final CommunityPost post in posts) {
      if (post.id == rootPostId) {
        return post;
      }
    }

    return null;
  }

  List<CommunityPost> get linkedPosts {
    final List<CommunityPost> result = posts
        .where((post) => post.id != rootPostId)
        .toList();

    result.sort((firstPost, secondPost) {
      final DateTime? firstCreatedAt = firstPost.createdAt;
      final DateTime? secondCreatedAt = secondPost.createdAt;

      if (firstCreatedAt == null && secondCreatedAt == null) {
        return posts.indexOf(firstPost).compareTo(posts.indexOf(secondPost));
      }

      if (firstCreatedAt == null) {
        return 1;
      }

      if (secondCreatedAt == null) {
        return -1;
      }

      final comparison = firstCreatedAt.compareTo(secondCreatedAt);
      return comparison == 0
          ? posts.indexOf(firstPost).compareTo(posts.indexOf(secondPost))
          : comparison;
    });

    return List<CommunityPost>.unmodifiable(result);
  }
}
