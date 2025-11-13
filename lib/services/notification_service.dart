import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../models/app_notification.dart';

class NotificationService {
  NotificationService({
    Dio? dio,
    String? baseUrl,
  })  : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl ?? AppConfig.apiBaseUrl)),
        _ownsDio = dio == null;

  static const String _notificationsPath = '/api/v1/notifications';

  final Dio _dio;
  final bool _ownsDio;

  Future<List<AppNotification>> fetchNotifications() async {
    try {
      final response = await _dio.get(_notificationsPath);
      dynamic payload = response.data;
      if (payload is String && payload.isNotEmpty) {
        payload = jsonDecode(payload);
      }
      if (payload is! List) {
        throw const NotificationServiceException(
          'Unexpected notifications payload.',
        );
      }
      return payload
          .whereType<Map<String, dynamic>>()
          .map(AppNotification.fromJson)
          .toList();
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      final message = status != null
          ? 'Failed to load notifications (status $status).'
          : (error.message ?? 'Failed to load notifications.');
      throw NotificationServiceException(message);
    } on FormatException catch (error) {
      throw NotificationServiceException(
        'Failed to parse notifications. ${error.message}',
      );
    }
  }

  void dispose() {
    if (_ownsDio) {
      _dio.close(force: false);
    }
  }
}

class NotificationServiceException implements Exception {
  const NotificationServiceException(this.message);

  final String message;

  @override
  String toString() => 'NotificationServiceException: $message';
}
