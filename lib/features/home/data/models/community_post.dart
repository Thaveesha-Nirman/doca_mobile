import '../../../../core/models/doca_models.dart';

class CommunityPost {
  const CommunityPost({
    this.id = '',
    this.feedItemId = '',
    this.authorUid = '',
    required this.alias,
    this.avatarId = 'avatar_01',
    required this.timeAgo,
    this.topic = '',
    required this.status,
    required this.title,
    required this.body,
    required this.votes,
    this.userVote,
    required this.comments,
    this.sharesCount = 0,
    this.isSharedByMe = false,
    this.isOwner = false,
    this.journeyRootId = '',
    this.isJourneyRoot = true,
    this.stepNumber = 1,
    this.journeyCount = 1,
    this.images = const [],
    this.isSensitive = false,
    this.shareId,
    this.sharedByUid,
    this.sharedByAlias,
    this.shareCaption = '',
    this.sharedTimeAgo,
    this.isSharerMe = false,
  });

  final String id;
  final String feedItemId;
  final String authorUid;
  final String alias;
  final String avatarId;
  final String timeAgo;
  final String topic;
  final String status;
  final String title;
  final String body;
  final int votes;
  final String? userVote;
  final int comments;
  final int sharesCount;
  final bool isSharedByMe;
  final bool isOwner;
  final String journeyRootId;
  final bool isJourneyRoot;
  final int stepNumber;
  final int journeyCount;
  final List<String> images;
  final bool isSensitive;

  // Facebook-style shared post metadata
  final String? shareId;
  final String? sharedByUid;
  final String? sharedByAlias;
  final String shareCaption;
  final String? sharedTimeAgo;
  final bool isSharerMe;

  bool get isSharedPost =>
      sharedByAlias != null && sharedByAlias!.trim().isNotEmpty;

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    final parsedImages = rawImages is List
        ? rawImages.map((e) => e.toString()).toList()
        : <String>[];

    final postId = (json['id'] ?? '').toString();
    final sharedBy = json['sharedBy'] as Map<String, dynamic>?;

    return CommunityPost(
      id: postId,
      feedItemId: (json['feedItemId'] ?? postId).toString(),
      authorUid: (json['authorUid'] ?? '').toString(),
      alias: (json['alias'] ?? 'Anonymous').toString(),
      avatarId: (json['avatarId'] ?? 'avatar_01').toString(),
      timeAgo: formatTimeAgo(json['createdAt']?.toString()),
      topic: (json['topic'] ?? '').toString(),
      status: (json['status'] ?? 'Asking').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      votes: (json['votes'] as num?)?.toInt() ?? 0,
      userVote: json['userVote']?.toString(),
      comments: (json['comments'] as num?)?.toInt() ?? 0,
      sharesCount: (json['sharesCount'] as num?)?.toInt() ?? 0,
      isSharedByMe: json['isSharedByMe'] == true,
      isOwner: json['isOwner'] == true,
      journeyRootId: (json['journeyRootId'] ?? postId).toString(),
      isJourneyRoot: json['isJourneyRoot'] != false,
      stepNumber: (json['stepNumber'] as num?)?.toInt() ?? 1,
      journeyCount: (json['journeyCount'] as num?)?.toInt() ?? 1,
      images: parsedImages,
      isSensitive: json['isSensitive'] == true,
      shareId: sharedBy?['id']?.toString(),
      sharedByUid: sharedBy?['uid']?.toString(),
      sharedByAlias: sharedBy?['alias']?.toString(),
      shareCaption: (sharedBy?['caption'] ?? '').toString(),
      sharedTimeAgo: sharedBy != null
          ? formatTimeAgo(sharedBy['sharedAt']?.toString())
          : null,
      isSharerMe: sharedBy?['isMe'] == true,
    );
  }

  CommunityPost withUpdatedPostData(CommunityPost fresh) {
    return CommunityPost(
      id: id,
      feedItemId: feedItemId,
      authorUid: fresh.authorUid,
      alias: fresh.alias,
      avatarId: fresh.avatarId,
      timeAgo: fresh.timeAgo,
      topic: fresh.topic,
      status: fresh.status,
      title: fresh.title,
      body: fresh.body,
      votes: fresh.votes,
      userVote: fresh.userVote,
      comments: fresh.comments,
      sharesCount: fresh.sharesCount,
      isSharedByMe: fresh.isSharedByMe,
      isOwner: fresh.isOwner,
      journeyRootId: fresh.journeyRootId,
      isJourneyRoot: fresh.isJourneyRoot,
      stepNumber: fresh.stepNumber,
      journeyCount: fresh.journeyCount,
      images: fresh.images,
      isSensitive: fresh.isSensitive,
      shareId: shareId,
      sharedByUid: sharedByUid,
      sharedByAlias: sharedByAlias,
      shareCaption: shareCaption,
      sharedTimeAgo: sharedTimeAgo,
      isSharerMe: isSharerMe,
    );
  }

  CommunityPost copyWith({
    String? title,
    String? body,
    String? status,
    int? votes,
    String? userVote,
    bool clearUserVote = false,
    int? comments,
    int? sharesCount,
    bool? isSharedByMe,
    int? journeyCount,
    List<String>? images,
    bool? isSensitive,
    String? shareCaption,
  }) {
    return CommunityPost(
      id: id,
      feedItemId: feedItemId,
      authorUid: authorUid,
      alias: alias,
      avatarId: avatarId,
      timeAgo: timeAgo,
      topic: topic,
      status: status ?? this.status,
      title: title ?? this.title,
      body: body ?? this.body,
      votes: votes ?? this.votes,
      userVote: clearUserVote ? null : (userVote ?? this.userVote),
      comments: comments ?? this.comments,
      sharesCount: sharesCount ?? this.sharesCount,
      isSharedByMe: isSharedByMe ?? this.isSharedByMe,
      isOwner: isOwner,
      journeyRootId: journeyRootId,
      isJourneyRoot: isJourneyRoot,
      stepNumber: stepNumber,
      journeyCount: journeyCount ?? this.journeyCount,
      images: images ?? this.images,
      isSensitive: isSensitive ?? this.isSensitive,
      shareId: shareId,
      sharedByUid: sharedByUid,
      sharedByAlias: sharedByAlias,
      shareCaption: shareCaption ?? this.shareCaption,
      sharedTimeAgo: sharedTimeAgo,
      isSharerMe: isSharerMe,
    );
  }
}