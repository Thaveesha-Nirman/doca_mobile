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

  String get _baseUrl {
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
      Uri.parse('$_baseUrl/users/me'),
      headers: headers,
    );
    return _parseResponse(response);
  }

  /// Fetches all global community posts from MongoDB.
  Future<JsonList> getPosts() async {
    final response = await http.get(Uri.parse('$_baseUrl/posts'));
    final data = _parseResponse(response);
    return (data['posts'] as JsonList?) ?? [];
  }

  /// Fetches only the logged-in user's posts for "My Journeys".
  Future<JsonList> getMyPosts() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/posts/mine'),
      headers: headers,
    );
    final data = _parseResponse(response);
    return (data['posts'] as JsonList?) ?? [];
  }

  /// Publishes a new post (with optional base64 photos) to MongoDB.
  Future<JsonMap> createPost({
    required String title,
    required String body,
    required String status,
    required List<String> images,
    required bool isSensitive,
  }) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/posts'),
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
}