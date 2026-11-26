import '../../../home/data/models/community_post.dart';
import '../../domain/repositories/journey_repository.dart';
import '../models/journey.dart';

/// In-memory skeleton data only. Ownership is simulated, not authentication.
class LocalJourneyRepository implements JourneyRepository {
  LocalJourneyRepository() {
    _seed('my_journey', 'my_root', currentAlias, 'Private', true);
    _seed(
      'journey_124',
      'shared_root',
      'QuietMoon22',
      'Shared Anonymously',
      false,
    );
  }

  static final LocalJourneyRepository instance = LocalJourneyRepository();
  static const String currentAlias = 'CalmOtter47';
  final Map<String, Journey> _journeys = {};
  final Map<String, CommunityPost> _posts = {};
  final Set<String> _ownedPosts = {};
  final Set<String> _ownedJourneys = {};
  int _sequence = 0;

  List<Journey> get ownedJourneys =>
      _journeys.values.where((journey) => ownsJourney(journey.id)).toList();
  bool ownsJourney(String id) => _ownedJourneys.contains(id);
  bool ownsPost(String? id) => _ownedPosts.contains(id);

  void registerOwnedPost(CommunityPost post) {
    if (post.id.isEmpty) {
      throw ArgumentError('A post ID is required.');
    }
    _posts[post.id] = post;
    _ownedPosts.add(post.id);
  }

  void _seed(
    String id,
    String rootId,
    String alias,
    String privacy,
    bool owned,
  ) {
    final root = CommunityPost(
      id: rootId,
      alias: alias,
      timeAgo: '2 days ago',
      topic: 'Recovery journey',
      status: 'Ongoing',
      title: 'Starting to track changes',
      body: 'I am keeping a record of my observations over time.',
      votes: 0,
      comments: 0,
      journeyId: id,
      rootPostId: rootId,
      createdAt: DateTime.utc(2026, 11, 24),
    );
    final update = root.copyWith(
      id: '${rootId}_update',
      title: 'A follow-up observation',
      body: 'Today I recorded another update in the same journey.',
      parentPostId: rootId,
      createdAt: DateTime.utc(2026, 11, 25),
      timeAgo: '1 day ago',
    );
    _journeys[id] = Journey(
      id: id,
      ownerAlias: alias,
      rootPostId: rootId,
      privacy: privacy,
      posts: List.unmodifiable([root, update]),
    );
    _posts[rootId] = root;
    _posts[update.id] = update;
    if (owned) {
      _ownedJourneys.add(id);
      _ownedPosts.addAll([rootId, update.id]);
    }
  }

  @override
  Future<Journey> fetchJourney(String journeyId) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final journey = _journeys[journeyId];
    if (journey == null) throw StateError('Journey not found.');
    if (journey.privacy == 'Private' && !ownsJourney(journeyId)) {
      throw StateError('This journey is private.');
    }
    return journey;
  }

  @override
  Future<Journey> createJourney({
    required String rootPostId,
    required String privacy,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!['Private', 'Shared Anonymously'].contains(privacy)) {
      throw ArgumentError('Choose a supported privacy value.');
    }
    final root = _posts[rootPostId];
    if (root == null || !ownsPost(rootPostId)) {
      throw StateError('An owned root post is required.');
    }
    if (root.journeyId != null) {
      return fetchJourney(root.journeyId!);
    }
    final id = 'local_journey_${++_sequence}';
    final linkedRoot = root.copyWith(journeyId: id, rootPostId: rootPostId);
    final journey = Journey(
      id: id,
      ownerAlias: root.alias,
      rootPostId: rootPostId,
      privacy: privacy,
      posts: List.unmodifiable([linkedRoot]),
    );
    _journeys[id] = journey;
    _posts[rootPostId] = linkedRoot;
    _ownedJourneys.add(id);
    return journey;
  }

  @override
  Future<CommunityPost> addJourneyPost({
    required String journeyId,
    required String parentPostId,
    required String title,
    required String body,
    required String topic,
    required String status,
    required bool isSensitive,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final journey = _journeys[journeyId];
    if (journey == null || !ownsJourney(journeyId)) {
      throw StateError('Only the journey owner can add posts.');
    }
    if (!journey.posts.any((post) => post.id == parentPostId)) {
      throw StateError('The parent post must belong to this journey.');
    }
    if (title.trim().isEmpty || body.trim().isEmpty) {
      throw ArgumentError('Title and body are required.');
    }
    final post = CommunityPost(
      id: 'local_post_${++_sequence}',
      alias: journey.ownerAlias,
      timeAgo: 'Just now',
      title: title.trim(),
      body: body.trim(),
      topic: topic,
      status: status,
      isSensitive: isSensitive,
      votes: 0,
      comments: 0,
      journeyId: journeyId,
      rootPostId: journey.rootPostId,
      parentPostId: parentPostId,
      createdAt: DateTime.now().toUtc(),
    );
    _journeys[journeyId] = journey.copyWith(
      posts: List.unmodifiable([...journey.posts, post]),
    );
    _posts[post.id] = post;
    _ownedPosts.add(post.id);
    return post;
  }
}
