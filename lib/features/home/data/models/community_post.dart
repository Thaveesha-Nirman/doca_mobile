class CommunityPost {
  const CommunityPost({
    this.id,
    required this.alias,
    required this.timeAgo,
    required this.topic,
    required this.status,
    required this.title,
    required this.body,
    required this.votes,
    required this.comments,
    this.isSensitive = false,
    this.journeyId,
    this.rootPostId,
    this.parentPostId,
    this.createdAt,
  });

  final String? id;
  final String alias;
  final String timeAgo;
  final String topic;
  final String status;
  final String title;
  final String body;
  final int votes;
  final int comments;
  final bool isSensitive;
  final String? journeyId;
  final String? rootPostId;
  final String? parentPostId;
  final DateTime? createdAt;

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    final String? createdAtValue = json['createdAt'] as String?;

    return CommunityPost(
      id: json['id'] as String?,
      alias: json['alias'] as String? ?? '',
      timeAgo: json['timeAgo'] as String? ?? '',
      topic: json['topic'] as String? ?? '',
      status: json['status'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      votes: (json['votes'] as num?)?.toInt() ?? 0,
      comments: (json['comments'] as num?)?.toInt() ?? 0,
      isSensitive: json['isSensitive'] as bool? ?? false,
      journeyId: json['journeyId'] as String?,
      rootPostId: json['rootPostId'] as String?,
      parentPostId: json['parentPostId'] as String?,
      createdAt: createdAtValue == null
          ? null
          : DateTime.tryParse(createdAtValue),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'alias': alias,
      'timeAgo': timeAgo,
      'topic': topic,
      'status': status,
      'title': title,
      'body': body,
      'votes': votes,
      'comments': comments,
      'isSensitive': isSensitive,
      'journeyId': journeyId,
      'rootPostId': rootPostId,
      'parentPostId': parentPostId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  CommunityPost copyWith({
    String? id,
    String? alias,
    String? timeAgo,
    String? topic,
    String? status,
    String? title,
    String? body,
    int? votes,
    int? comments,
    bool? isSensitive,
    String? journeyId,
    String? rootPostId,
    String? parentPostId,
    DateTime? createdAt,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      alias: alias ?? this.alias,
      timeAgo: timeAgo ?? this.timeAgo,
      topic: topic ?? this.topic,
      status: status ?? this.status,
      title: title ?? this.title,
      body: body ?? this.body,
      votes: votes ?? this.votes,
      comments: comments ?? this.comments,
      isSensitive: isSensitive ?? this.isSensitive,
      journeyId: journeyId ?? this.journeyId,
      rootPostId: rootPostId ?? this.rootPostId,
      parentPostId: parentPostId ?? this.parentPostId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
