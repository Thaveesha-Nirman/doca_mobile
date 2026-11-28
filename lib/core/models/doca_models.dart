String formatTimeAgo(String? isoDate) {
  if (isoDate == null || isoDate.isEmpty) return 'Just now';
  final date = DateTime.tryParse(isoDate)?.toLocal();
  if (date == null) return 'Just now';

  final diff = DateTime.now().difference(date);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

String formatClockTime(DateTime? dt) {
  if (dt == null) return '';
  final local = dt.toLocal();
  final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '$hour12:$minute $period';
}

String formatFullTimestamp(DateTime? dt) {
  if (dt == null) return 'Not yet';
  final local = dt.toLocal();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final now = DateTime.now();
  final sameDay = now.year == local.year &&
      now.month == local.month &&
      now.day == local.day;
  final timeStr = formatClockTime(local);
  if (sameDay) return 'Today, $timeStr';
  return '${months[local.month - 1]} ${local.day}, $timeStr';
}

String formatFileSize(int bytes) {
  if (bytes <= 0) return '';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.alias,
    this.avatarId = 'avatar_01',
    this.gender = 'Prefer not to say',
    this.age,
    this.bio = '',
    this.followersCount = 0,
    this.followingCount = 0,
    this.isFollowing = false,
    this.isMe = false,
  });

  final String uid;
  final String alias;
  final String avatarId;
  final String gender;
  final int? age;
  final String bio;
  final int followersCount;
  final int followingCount;
  final bool isFollowing;
  final bool isMe;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: (json['uid'] ?? json['firebaseUid'] ?? '').toString(),
      alias: (json['alias'] ?? 'Anonymous').toString(),
      avatarId: (json['avatarId'] ?? 'avatar_01').toString(),
      gender: (json['gender'] ?? 'Prefer not to say').toString(),
      age: (json['age'] as num?)?.toInt(),
      bio: (json['bio'] ?? '').toString(),
      followersCount: (json['followersCount'] as num?)?.toInt() ?? 0,
      followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
      isFollowing: json['isFollowing'] == true,
      isMe: json['isMe'] == true,
    );
  }

  UserProfile copyWith({
    String? alias,
    String? avatarId,
    String? gender,
    int? age,
    String? bio,
    int? followersCount,
    int? followingCount,
    bool? isFollowing,
  }) {
    return UserProfile(
      uid: uid,
      alias: alias ?? this.alias,
      avatarId: avatarId ?? this.avatarId,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      bio: bio ?? this.bio,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      isFollowing: isFollowing ?? this.isFollowing,
      isMe: isMe,
    );
  }
}

class PostComment {
  const PostComment({
    required this.id,
    required this.postId,
    this.parentCommentId,
    required this.authorUid,
    required this.alias,
    this.avatarId = 'avatar_01',
    required this.body,
    required this.timeAgo,
    this.votes = 0,
    this.userVote,
    this.createdAt,
    this.helpfulCount = 0,
    this.heartCount = 0,
    this.careCount = 0,
    this.myReactions = const [],
    this.isOwner = false,
    this.replies = const [],
  });

  final String id;
  final String postId;
  final String? parentCommentId;
  final String authorUid;
  final String alias;
  final String avatarId;
  final String body;
  final String timeAgo;
  final int votes;
  final String? userVote;
  final DateTime? createdAt;
  final int helpfulCount;
  final int heartCount;
  final int careCount;
  final List<String> myReactions;
  final bool isOwner;
  final List<PostComment> replies;

  factory PostComment.fromJson(Map<String, dynamic> json) {
    final reactions = (json['reactions'] as Map<String, dynamic>?) ?? {};
    final myList = (json['myReactions'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];
    final rawReplies = (json['replies'] as List<dynamic>?) ?? [];

    return PostComment(
      id: (json['id'] ?? '').toString(),
      postId: (json['postId'] ?? '').toString(),
      parentCommentId: json['parentCommentId']?.toString(),
      authorUid: (json['authorUid'] ?? '').toString(),
      alias: (json['alias'] ?? 'Anonymous').toString(),
      avatarId: (json['avatarId'] ?? 'avatar_01').toString(),
      body: (json['body'] ?? '').toString(),
      timeAgo: formatTimeAgo(json['createdAt']?.toString()),
      votes: (json['votes'] as num?)?.toInt() ?? 0,
      userVote: json['userVote']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      helpfulCount: (reactions['helpful'] as num?)?.toInt() ?? 0,
      heartCount: (reactions['heart'] as num?)?.toInt() ?? 0,
      careCount: (reactions['care'] as num?)?.toInt() ?? 0,
      myReactions: myList,
      isOwner: json['isOwner'] == true,
      replies: rawReplies
          .map((r) => PostComment.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.actorUid,
    required this.actorAlias,
    this.actorAvatarId = 'avatar_01',
    required this.type,
    this.referenceId,
    this.requestStatus,
    required this.message,
    this.isRead = false,
    required this.timeAgo,
  });

  final String id;
  final String actorUid;
  final String actorAlias;
  final String actorAvatarId;
  final String type;
  final String? referenceId;
  final String? requestStatus;
  final String message;
  final bool isRead;
  final String timeAgo;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] ?? '').toString(),
      actorUid: (json['actorUid'] ?? '').toString(),
      actorAlias: (json['actorAlias'] ?? 'Anonymous').toString(),
      actorAvatarId: (json['actorAvatarId'] ?? 'avatar_01').toString(),
      type: (json['type'] ?? '').toString(),
      referenceId: json['referenceId']?.toString(),
      requestStatus: json['requestStatus']?.toString(),
      message: (json['message'] ?? '').toString(),
      isRead: json['isRead'] == true,
      timeAgo: formatTimeAgo(json['createdAt']?.toString()),
    );
  }
}

class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.otherUid,
    required this.otherAlias,
    this.otherAvatarId = 'avatar_01',
    required this.lastMessageText,
    required this.timeAgo,
    this.unreadCount = 0,
  });

  final String id;
  final String otherUid;
  final String otherAlias;
  final String otherAvatarId;
  final String lastMessageText;
  final String timeAgo;
  final int unreadCount;

  bool get hasUnread => unreadCount > 0;

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final other = (json['otherUser'] as Map<String, dynamic>?) ?? {};
    return ChatConversation(
      id: (json['id'] ?? '').toString(),
      otherUid: (other['uid'] ?? '').toString(),
      otherAlias: (other['alias'] ?? 'Anonymous').toString(),
      otherAvatarId: (other['avatarId'] ?? 'avatar_01').toString(),
      lastMessageText: (json['lastMessageText'] ?? '').toString(),
      timeAgo: formatTimeAgo(json['lastMessageAt']?.toString()),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class ChatAttachment {
  const ChatAttachment({
    required this.type,
    required this.name,
    required this.mimeType,
    required this.size,
    required this.data,
  });

  final String type; // 'image' | 'file'
  final String name;
  final String mimeType;
  final int size;
  final String data; // base64

  bool get isImage => type == 'image';
  bool get isPdf =>
      mimeType.toLowerCase().contains('pdf') ||
      name.toLowerCase().endsWith('.pdf');

  factory ChatAttachment.fromJson(Map<String, dynamic> json) {
    return ChatAttachment(
      type: (json['type'] ?? 'file').toString(),
      name: (json['name'] ?? 'document').toString(),
      mimeType: (json['mimeType'] ?? 'application/octet-stream').toString(),
      size: (json['size'] as num?)?.toInt() ?? 0,
      data: (json['data'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'name': name,
        'mimeType': mimeType,
        'size': size,
        'data': data,
      };
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderUid,
    required this.isMine,
    required this.body,
    required this.timeAgo,
    this.attachment,
    this.isEdited = false,
    this.editedAt,
    this.isDeleted = false,
    this.createdAt,
    this.deliveredAt,
    this.seenAt,
  });

  final String id;
  final String conversationId;
  final String senderUid;
  final bool isMine;
  final String body;
  final String timeAgo;
  final ChatAttachment? attachment;
  final bool isEdited;
  final DateTime? editedAt;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? deliveredAt;
  final DateTime? seenAt;

  bool get isSeen => seenAt != null;
  bool get isDelivered => deliveredAt != null || seenAt != null;
  String get sentClockTime =>
      createdAt != null ? formatClockTime(createdAt) : timeAgo;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final rawAtt = json['attachment'];
    return ChatMessage(
      id: (json['id'] ?? '').toString(),
      conversationId: (json['conversationId'] ?? '').toString(),
      senderUid: (json['senderUid'] ?? '').toString(),
      isMine: json['isMine'] == true,
      body: (json['body'] ?? '').toString(),
      timeAgo: formatTimeAgo(json['createdAt']?.toString()),
      attachment: rawAtt is Map<String, dynamic>
          ? ChatAttachment.fromJson(rawAtt)
          : null,
      isEdited: json['isEdited'] == true,
      editedAt: json['editedAt'] != null
          ? DateTime.tryParse(json['editedAt'].toString())
          : null,
      isDeleted: json['isDeleted'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.tryParse(json['deliveredAt'].toString())
          : null,
      seenAt: json['seenAt'] != null
          ? DateTime.tryParse(json['seenAt'].toString())
          : null,
    );
  }
}