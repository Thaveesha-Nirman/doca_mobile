class CommunityPost {
  const CommunityPost({
    required this.alias,
    required this.timeAgo,
    required this.topic,
    required this.status,
    required this.title,
    required this.body,
    required this.votes,
    required this.comments,
    this.isSensitive = false,
  });

  final String alias;
  final String timeAgo;
  final String topic;
  final String status;
  final String title;
  final String body;
  final int votes;
  final int comments;
  final bool isSensitive;
}
