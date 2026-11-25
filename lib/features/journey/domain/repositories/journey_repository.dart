import '../../../home/data/models/community_post.dart';
import '../../data/models/journey.dart';

abstract class JourneyRepository {
  Future<Journey> fetchJourney(String journeyId);
  Future<Journey> createJourney({
    required String rootPostId,
    required String privacy,
  });
  Future<CommunityPost> addJourneyPost({
    required String journeyId,
    required String parentPostId,
    required String title,
    required String body,
    required String topic,
    required String status,
    required bool isSensitive,
  });
}
