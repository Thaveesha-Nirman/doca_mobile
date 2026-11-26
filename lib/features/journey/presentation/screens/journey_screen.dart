import 'package:material_ui/material_ui.dart';

import '../../../home/data/models/community_post.dart';
import '../../../home/presentation/screens/create_post_screen.dart';
import '../../data/models/journey.dart';
import '../../data/repositories/local_journey_repository.dart';
import '../../domain/repositories/journey_repository.dart';

class JourneyScreen extends StatefulWidget {
  const JourneyScreen({
    this.journeyId,
    this.repository,
    this.isCurrentUserOwner = false,
    this.refreshToken = 0,
    super.key,
  });

  final String? journeyId;
  final JourneyRepository? repository;
  final bool isCurrentUserOwner;
  final int refreshToken;

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  JourneyRepository get _repository =>
      widget.repository ?? LocalJourneyRepository.instance;
  Journey? _journey;
  bool _loading = true;
  bool _adding = false;
  String? _error;
  CommunityPost? _pendingPost;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant JourneyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.journeyId != oldWidget.journeyId ||
        widget.repository != oldWidget.repository ||
        widget.refreshToken != oldWidget.refreshToken) {
      _pendingPost = null;
      _load();
    }
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final journey = await _repository.fetchJourney(
        widget.journeyId ?? 'my_journey',
      );
      if (!mounted || request != _request) return;
      setState(() {
        _journey = journey;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || request != _request) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _addPost() async {
    final journey = _journey;
    if (_adding || journey == null || !widget.isCurrentUserOwner) return;
    setState(() => _adding = true);
    try {
      _pendingPost ??= await Navigator.of(context).push<CommunityPost>(
        MaterialPageRoute(builder: (_) => const CreatePostScreen()),
      );
      if (!mounted || _pendingPost == null) return;
      final draft = _pendingPost!;
      final updates = journey.linkedPosts;
      final parentId = updates.isEmpty ? journey.rootPostId : updates.last.id;
      if (parentId.isEmpty) throw StateError('The parent post has no ID.');
      await _repository.addJourneyPost(
        journeyId: journey.id,
        parentPostId: parentId,
        title: draft.title,
        body: draft.body,
        topic: draft.topic,
        status: draft.status,
        isSensitive: draft.isSensitive,
      );
      _pendingPost = null;
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Journey post added')));
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not add post: $error')));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Widget _postCard(CommunityPost post, {bool root = false}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              root ? 'Root post' : 'Journey update',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Text(post.alias),
            Text('${post.topic} · ${post.status}'),
            const SizedBox(height: 8),
            Text(post.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(post.body),
            const SizedBox(height: 8),
            Text(post.createdAt?.toLocal().toString() ?? post.timeAgo),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Journey')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    final journey = _journey;
    if (journey == null) {
      return const Center(child: Text('No journey posts yet'));
    }
    final root = journey.rootPost;
    final updates = journey.linkedPosts;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.journeyId == null && _repository is LocalJourneyRepository)
          Wrap(
            spacing: 8,
            children: (_repository as LocalJourneyRepository).ownedJourneys
                .map(
                  (owned) => OutlinedButton(
                    onPressed: () async {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => JourneyScreen(
                            journeyId: owned.id,
                            repository: _repository,
                            isCurrentUserOwner: true,
                          ),
                        ),
                      );
                      if (mounted) _load();
                    },
                    child: Text(owned.rootPost?.title ?? 'Open journey'),
                  ),
                )
                .toList(),
          ),
        Text(
          root?.topic ?? 'Journey',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text('Owner: ${journey.ownerAlias}'),
        Text('Privacy: ${journey.privacy}'),
        if (journey.posts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No journey posts yet'),
          )
        else if (root == null)
          const Text('The root post is unavailable.')
        else
          _postCard(root, root: true),
        ...updates.map(_postCard),
        if (root != null && updates.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No additional journey posts yet'),
          ),
        if (widget.isCurrentUserOwner && root != null) ...[
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _adding ? null : _addPost,
            child: Text(
              _adding
                  ? 'Adding...'
                  : _pendingPost == null
                  ? 'Add Post'
                  : 'Retry adding post',
            ),
          ),
        ],
      ],
    );
  }
}
