import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../models/cashback_entry.dart';
import 'auth_storage.dart';

class CashbackService {
  CashbackService({
    Dio? dio,
    String? baseUrl,
  })  : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl ?? AppConfig.apiBaseUrl)),
        _ownsDio = dio == null;

  static const String _cashbackPath = '/api/v1/cashback/user';

  final Dio _dio;
  final bool _ownsDio;

  Future<List<CashbackEntry>> fetchUserCashback({
    required int userId,
    String? accessToken,
    String? tokenType,
  }) async {
    final storage = AuthStorage.instance;
    final token = accessToken ?? await storage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw const CashbackServiceException('Not authenticated.');
    }
    String scheme = tokenType ?? await storage.getTokenType() ?? 'Bearer';
    scheme = scheme.trim();
    if (scheme.isEmpty) scheme = 'Bearer';
    final normalizedScheme =
        scheme.toLowerCase() == 'bearer' ? 'Bearer' : scheme;

    try {
      final response = await _dio.get(
        '$_cashbackPath/$userId',
        options: Options(
          headers: {
            'Authorization': '$normalizedScheme $token',
          },
        ),
      );
      dynamic payload = response.data;
      if (payload is String && payload.isNotEmpty) {
        payload = jsonDecode(payload);
      }
      if (payload is! List) {
        throw const CashbackServiceException('Unexpected cashback payload.');
      }
      return payload
          .whereType<Map<String, dynamic>>()
          .map(CashbackEntry.fromJson)
          .toList();
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 401) {
        throw const CashbackUnauthorizedException('Unauthorized');
      }
      final message = status != null
          ? 'Failed to load cashback (status $status).'
          : (error.message ?? 'Failed to load cashback.');
      throw CashbackServiceException(message);
    } on FormatException catch (error) {
      throw CashbackServiceException(
        'Failed to parse cashback entries. ${error.message}',
      );
    }
  }

  void dispose() {
    if (_ownsDio) {
      _dio.close(force: false);
    }
  }
}

class CashbackServiceException implements Exception {
  const CashbackServiceException(this.message);

  final String message;

  @override
  String toString() => 'CashbackServiceException: $message';
}

class CashbackUnauthorizedException extends CashbackServiceException {
  const CashbackUnauthorizedException(super.message);
}
