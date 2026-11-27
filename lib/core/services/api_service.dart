import 'dart:convert';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:http/http.dart' as http;

import 'auth_service.dart';

typedef HeaderMap = Map<String, String>;
typedef JsonMap = Map<String, dynamic>;
typedef JsonList = List<dynamic>;

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  String get _baseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (kIsWeb) return 'http://localhost:5000/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://localhost:5000/api';
  }

  Future<HeaderMap> _authHeaders() async {
    final token = await AuthService.instance.getIdToken();
    if (token == null) {
      throw ApiException(401, 'Not signed in with Firebase.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<HeaderMap> _optionalAuthHeaders() async {
    final token = await AuthService.instance.getIdToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  JsonMap _parseResponse(http.Response response) {
    final body = response.body.isNotEmpty
        ? jsonDecode(response.body) as JsonMap
        : <String, dynamic>{};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw ApiException(
      response.statusCode,
      body['message']?.toString() ?? 'Request failed (${response.statusCode})',
    );
  }

  // ==================== AUTH & PROFILE ====================

  Future<JsonMap> syncUser() async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/sync'),
      headers: headers,
    );
    return _parseResponse(response);
  }

  Future<JsonMap> completeOnboarding({
    required String alias,
    required String gender,
    required int age,
    String avatarId = 'avatar_01',
  }) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/onboarding'),
      headers: headers,
      body: jsonEncode({
        'alias': alias,
        'avatarId': avatarId,
        'gender': gender,
        'age': age,
      }),
    );
    return _parseResponse(response);
  }

  Future<JsonMap> getMyProfile() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/profile/me'),
      headers: headers,
    );
    return _parseResponse(response);
  }

  Future<JsonMap> updateMyProfile({
    String? alias,
    String? bio,
    String? gender,
    int? age,
    String? avatarId,
  }) async {
    final headers = await _authHeaders();
    final payload = <String, dynamic>{};
    if (alias != null) payload['alias'] = alias;
    if (bio != null) payload['bio'] = bio;
    if (gender != null) payload['gender'] = gender;
    if (age != null) payload['age'] = age;
    if (avatarId != null) payload['avatarId'] = avatarId;

    final response = await http.patch(
      Uri.parse('$_baseUrl/profile/me'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return _parseResponse(response);
  }

  Future<JsonMap> getPublicProfile(String uid) async {
    final headers = await _optionalAuthHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/users/$uid'),
      headers: headers,
    );
    return _parseResponse(response);
  }

  Future<JsonMap> toggleFollow(String uid) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/users/$uid/follow'),
      headers: headers,
    );
    return _parseResponse(response);
  }

  // ==================== POSTS & LINKED JOURNEYS ====================

Future<JsonList> getPosts({
    String tab = 'forYou',
    String query = '',
    String? status,
    Set<String> symptoms = const {},
    String? bodyArea,
    bool hasPhotosOnly = false,
    bool journeysOnly = false,
    String sortBy = '',
  }) async {
    final isFollowing = tab == 'following';
    final headers = isFollowing
        ? await _authHeaders()
        : await _optionalAuthHeaders();

    final params = <String, String>{};
    if (!isFollowing) {
      params['tab'] = tab;
    }
    if (query.trim().isNotEmpty) {
      params['q'] = query.trim();
    }
    if (status != null && status.trim().isNotEmpty) {
      params['status'] = status.trim();
    }
    if (symptoms.isNotEmpty) {
      params['symptoms'] = symptoms.join(',');
    }
    if (bodyArea != null && bodyArea.trim().isNotEmpty) {
      params['bodyArea'] = bodyArea.trim();
    }
    if (hasPhotosOnly) {
      params['hasPhotos'] = 'true';
    }
    if (journeysOnly) {
      params['onlyJourneys'] = 'true';
    }
    if (sortBy.trim().isNotEmpty) {
      params['sort'] = sortBy.trim();
    }

    final endpoint =
        isFollowing ? '$_baseUrl/posts/following' : '$_baseUrl/posts';
    final uri = Uri.parse(endpoint).replace(
      queryParameters: params.isEmpty ? null : params,
    );

    final response = await http.get(uri, headers: headers);
    final data = _parseResponse(response);
    return (data['posts'] as JsonList?) ?? [];
  }

  Future<JsonList> getMyPosts({bool onlyRoots = false}) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$_baseUrl/posts/mine').replace(
      queryParameters: onlyRoots ? {'onlyRoots': 'true'} : null,
    );
    final response = await http.get(uri, headers: headers);
    final data = _parseResponse(response);
    return (data['posts'] as JsonList?) ?? [];
  }

  Future<JsonList> getSharedPosts() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/posts/shared'),
      headers: headers,
    );
    final data = _parseResponse(response);
    return (data['posts'] as JsonList?) ?? [];
  }

  Future<JsonMap> getJourneyTimeline(String postId) async {
    final headers = await _optionalAuthHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/posts/$postId/journey'),
      headers: headers,
    );
    return _parseResponse(response);
  }

  Future<JsonMap> createPost({
    required String title,
    required String body,
    required String status,
    required List<String> images,
    required bool isSensitive,
    String? parentPostId,
  }) async {
    final headers = await _authHeaders();
    final payload = <String, dynamic>{
      'title': title,
      'body': body,
      'status': status,
      'images': images,
      'isSensitive': isSensitive,
    };
    if (parentPostId != null && parentPostId.isNotEmpty) {
      payload['parentPostId'] = parentPostId;
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/posts'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return _parseResponse(response);
  }

  Future<JsonMap> updatePost({
    required String postId,
    required String title,
    required String body,
    required String status,
    required List<String> images,
    required bool isSensitive,
  }) async {
    final headers = await _authHeaders();
    final response = await http.patch(
      Uri.parse('$_baseUrl/posts/$postId'),
      headers: headers,
      body: jsonEncode({
        'title': title,
        'body': body,
        'status': status,
        'images': images,
        'isSensitive': isSensitive,
      }),
    );
    return _parseResponse(response);
  }

  Future<JsonMap> deletePost(String postId) async {
    final headers = await _authHeaders();
    final response = await http.delete(
      Uri.parse('$_baseUrl/posts/$postId'),
      headers: headers,
    );
    return _parseResponse(response);
  }

  Future<JsonMap> votePost(String postId, String type) async {
    final headers = await _authHeaders();
    final response = await http.patch(
      Uri.parse('$_baseUrl/posts/$postId/vote'),
      headers: headers,
      body: jsonEncode({'type': type}),
    );
    return _parseResponse(response);
  }

  Future<JsonMap> toggleSharePost(
    String postId, {
    String caption = '',
  }) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/posts/$postId/share'),
      headers: headers,
      body: jsonEncode({'caption': caption}),
    );
    return _parseResponse(response);
  }

  Future<JsonMap> unsharePost(String postId) async {
    final headers = await _authHeaders();
    final response = await http.delete(
      Uri.parse('$_baseUrl/posts/$postId/share'),
      headers: headers,
    );
    return _parseResponse(response);
  }

  Future<JsonMap> updateShareCaption(String shareId, String caption) async {
    final headers = await _authHeaders();
    final response = await http.patch(
      Uri.parse('$_baseUrl/shares/$shareId'),
      headers: headers,
      body: jsonEncode({'caption': caption}),
    );
    return _parseResponse(response);
  }

  Future<JsonMap> deleteShare(String shareId) async {
    final headers = await _authHeaders();
    final response = await http.delete(
      Uri.parse('$_baseUrl/shares/$shareId'),
      headers: headers,
    );
    return _parseResponse(response);
  }

  // ==================== COMMENTS & REACTIONS ====================

 Future<JsonMap> getComments(String postId, {String sort = 'newest'}) async {
    final headers = await _optionalAuthHeaders();
    final uri = Uri.parse('$_baseUrl/posts/$postId/comments').replace(
      queryParameters: {'sort': sort},
    );
    final response = await http.get(uri, headers: headers);
    return _parseResponse(response);
  }

  Future<JsonMap> voteComment(String commentId, String type) async {
    final headers = await _authHeaders();
    final response = await http.patch(
      Uri.parse('$_baseUrl/comments/$commentId/vote'),
      headers: headers,
      body: jsonEncode({'type': type}),
    );
    return _parseResponse(response);
  }

  Future<JsonMap> addComment({
    required String postId,
    required String body,
    String? parentCommentId,
  }) async {
    final headers = await _authHeaders();
    final payload = <String, dynamic>{'body': body};
    if (parentCommentId != null && parentCommentId.isNotEmpty) {
      payload['parentCommentId'] = parentCommentId;
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/posts/$postId/comments'),
      headers: headers,
      body: jsonEncode(payload),
    );
    return _parseResponse(response);
  }

  Future<JsonMap> toggleCommentReaction(String commentId, String type) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/comments/$commentId/react'),
      headers: headers,
      body: jsonEncode({'type': type}),
    );
    return _parseResponse(response);
  }

  Future<JsonMap> deleteComment(String commentId) async {
    final headers = await _authHeaders();
    final response = await http.delete(
      Uri.parse('$_baseUrl/comments/$commentId'),
      headers: headers,
    );
    return _parseResponse(response);
  }

  // ==================== INBOX, REQUESTS & CHAT ====================

  Future<JsonMap> getNotifications() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/inbox/notifications'),
      headers: headers,
    );
    return _parseResponse(response);
  }

  Future<JsonMap> markNotificationsRead() async {
    final headers = await _authHeaders();
    final response = await http.patch(
      Uri.parse('$_baseUrl/inbox/notifications/read'),
      headers: headers,
    );
    return _parseResponse(response);
  }

  Future<JsonMap> getMessageRequestStatus(String targetUid) async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/inbox/message-requests/status/$targetUid'),
      headers: headers,
    );
    return _parseResponse(response);
  }

  Future<JsonMap> sendMessageRequest(String toUid, {String intro = ''}) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/inbox/message-requests'),
      headers: headers,
      body: jsonEncode({'toUid': toUid, 'introMessage': intro}),
    );
    return _parseResponse(response);
  }

  Future<JsonMap> respondToMessageRequest(
    String requestId,
    String action,
  ) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/inbox/message-requests/$requestId/respond'),
      headers: headers,
      body: jsonEncode({'action': action}),
    );
    return _parseResponse(response);
  }

  Future<JsonList> getConversations() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/inbox/conversations'),
      headers: headers,
    );
    final data = _parseResponse(response);
    return (data['conversations'] as JsonList?) ?? [];
  }

  Future<JsonList> getMessages(String conversationId) async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/inbox/conversations/$conversationId/messages'),
      headers: headers,
    );
    final data = _parseResponse(response);
    return (data['messages'] as JsonList?) ?? [];
  }

  Future<JsonMap> sendMessage(String conversationId, String body) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/inbox/conversations/$conversationId/messages'),
      headers: headers,
      body: jsonEncode({'body': body}),
    );
    return _parseResponse(response);
  }

  Future<void> registerFcmToken(String token) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/inbox/fcm-token'),
      headers: headers,
      body: jsonEncode({'token': token}),
    );
    _parseResponse(response);
  }

  Future<void> removeFcmToken(String token) async {
    final headers = await _authHeaders();
    final response = await http.delete(
      Uri.parse('$_baseUrl/inbox/fcm-token'),
      headers: headers,
      body: jsonEncode({'token': token}),
    );
    _parseResponse(response);
  }
}