import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skinit_mobile/features/home/data/models/community_post.dart';
import 'package:skinit_mobile/features/journey/data/models/journey.dart';
import 'package:skinit_mobile/features/journey/data/repositories/local_journey_repository.dart';
import 'package:skinit_mobile/features/journey/domain/repositories/journey_repository.dart';
import 'package:skinit_mobile/features/journey/presentation/screens/journey_screen.dart';

class RetryRepository implements JourneyRepository {
  bool failed = true;
  @override
  Future<Journey> fetchJourney(String id) async {
    if (failed) throw StateError('Temporary failure');
    return const Journey(
      id: 'empty',
      ownerAlias: 'Anonymous',
      rootPostId: 'missing',
      privacy: 'Private',
      posts: [],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'conversion and append preserve links and reject foreign writes',
    () async {
      final repository = LocalJourneyRepository();
      const root = CommunityPost(
        id: 'new_root',
        alias: 'Anonymous',
        timeAgo: 'Just now',
        topic: 'General health',
        status: 'Ongoing',
        title: 'First post',
        body: 'A longer first post body',
        votes: 0,
        comments: 0,
      );
      repository.registerOwnedPost(root);
      final journey = await repository.createJourney(
        rootPostId: 'new_root',
        privacy: 'Private',
      );
      expect(journey.rootPost!.id, 'new_root');
      expect(journey.rootPost!.parentPostId, isNull);
      expect(journey.linkedPosts, isEmpty);
      final post = await repository.addJourneyPost(
        journeyId: journey.id,
        parentPostId: 'new_root',
        title: 'Update',
        body: 'An update body',
        topic: 'General health',
        status: 'Ongoing',
        isSensitive: false,
      );
      expect(post.rootPostId, 'new_root');
      expect(post.journeyId, journey.id);
      expect(post.parentPostId, 'new_root');
      expect(
        (await repository.fetchJourney(journey.id)).linkedPosts.single.id,
        post.id,
      );
      await expectLater(
        repository.addJourneyPost(
          journeyId: 'journey_124',
          parentPostId: 'shared_root',
          title: 'Foreign update',
          body: 'Body',
          topic: 'General health',
          status: 'Ongoing',
          isSensitive: false,
        ),
        throwsStateError,
      );
      await expectLater(
        repository.addJourneyPost(
          journeyId: journey.id,
          parentPostId: 'shared_root',
          title: 'Wrong parent',
          body: 'Body',
          topic: 'General health',
          status: 'Ongoing',
          isSensitive: false,
        ),
        throwsStateError,
      );
      await expectLater(repository.fetchJourney('missing'), throwsStateError);
    },
  );

  testWidgets('owner sees loading, root, linked posts and Add Post', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: JourneyScreen(
          journeyId: 'my_journey',
          repository: LocalJourneyRepository(),
          isCurrentUserOwner: true,
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Root post'), findsOneWidget);
    expect(find.text('Journey update'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Add Post'), 200);
    expect(find.text('Add Post'), findsOneWidget);
  });

  testWidgets('another user sees no Add Post', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: JourneyScreen(
          journeyId: 'journey_124',
          repository: LocalJourneyRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Owner: QuietMoon22'), findsOneWidget);
    expect(find.text('Privacy: Shared Anonymously'), findsOneWidget);
    expect(find.text('Add Post'), findsNothing);
  });

  testWidgets('failed load retries and shows empty state', (tester) async {
    final repository = RetryRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: JourneyScreen(journeyId: 'empty', repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    repository.failed = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('No journey posts yet'), findsOneWidget);
  });
}
