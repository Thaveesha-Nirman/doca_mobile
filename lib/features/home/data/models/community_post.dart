class CommunityPost {
  const CommunityPost({
    this.id = '',
    required this.alias,
    required this.timeAgo,
    required this.topic,
    required this.status,
    required this.title,
    required this.body,
    required this.votes,
    required this.comments,
    this.isSensitive = false,
    this.rootPostId,
    this.journeyId,
    this.parentPostId,
    this.createdAt,
  });

  final String id;
  final String alias;
  final String timeAgo;
  final String topic;
  final String status;
  final String title;
  final String body;
  final int votes;
  final int comments;
  final bool isSensitive;
  final String? rootPostId;
  final String? journeyId;
  final String? parentPostId;
  final DateTime? createdAt;

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: _stringValue(json['id']),
      alias: _stringValue(json['alias']),
      timeAgo: _stringValue(json['timeAgo']),
      topic: _stringValue(json['topic']),
      status: _stringValue(json['status']),
      title: _stringValue(json['title']),
      body: _stringValue(json['body']),
      votes: _intValue(json['votes']),
      comments: _intValue(json['comments']),
      isSensitive: json['isSensitive'] is bool
          ? json['isSensitive'] as bool
          : false,
      rootPostId: _nullableString(json['rootPostId']),
      journeyId: _nullableString(json['journeyId']),
      parentPostId: _nullableString(json['parentPostId']),
      createdAt: _dateTimeValue(json['createdAt']),
    );
  }

  static String _stringValue(Object? value) => value is String ? value : '';

  static String? _nullableString(Object? value) =>
      value is String ? value : null;

  static int _intValue(Object? value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

  static DateTime? _dateTimeValue(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

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
