import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

typedef RetryDataFactory = Future<dynamic> Function();

final authBoxProvider = Provider<Box<dynamic>>((ref) {
  return Hive.box('auth');
});

final apiBaseUrlProvider = Provider<String>((ref) {
  const configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
  if (configuredBaseUrl.isNotEmpty) {
    return configuredBaseUrl;
  }

  // With ADB reverse tunnel (adb reverse tcp:8000 tcp:8000),
  // the emulator can reach the host backend via localhost.
  return 'http://localhost:8000';
});

class ApiClient {
  ApiClient({
    required String baseUrl,
    required Box<dynamic> authBox,
  }) : _baseUrl = baseUrl,
       _authBox = authBox;

  final String _baseUrl;
  final Box<dynamic> _authBox;

  Dio createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 120),
        contentType: Headers.jsonContentType,
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _authBox.get('access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final retried = error.requestOptions.extra['retried_with_alt_host'] == true;
          final fallbackBaseUrl = _alternateBaseUrl(error.requestOptions.baseUrl);

          if (!retried && fallbackBaseUrl != null && _isConnectionRefused(error)) {
            final requestOptions = error.requestOptions;
            final retryData = await _rebuildRetryData(requestOptions);
            if (requestOptions.data is FormData && retryData == null) {
              return handler.next(error);
            }

            final retryRequest = requestOptions.copyWith(
              baseUrl: fallbackBaseUrl,
              data: retryData ?? requestOptions.data,
              extra: {
                ...requestOptions.extra,
                'retried_with_alt_host': true,
              },
            );

            try {
              final response = await dio.fetch<dynamic>(retryRequest);
              return handler.resolve(response);
            } on DioException catch (retryError) {
              return handler.next(retryError);
            }
          }

          handler.next(error);
        },
      ),
    );

    return dio;
  }

  bool _isConnectionRefused(DioException error) {
    if (error.type != DioExceptionType.connectionError) {
      return false;
    }

    final message = error.message?.toLowerCase() ?? '';
    return message.contains('connection refused') ||
        message.contains('failed host lookup') ||
        message.contains('connection error');
  }

  String? _alternateBaseUrl(String currentBaseUrl) {
    if (kIsWeb || !Platform.isAndroid) {
      return null;
    }

    if (currentBaseUrl.contains('10.0.2.2')) {
      return currentBaseUrl.replaceFirst('10.0.2.2', 'localhost');
    }

    if (currentBaseUrl.contains('localhost')) {
      return currentBaseUrl.replaceFirst('localhost', '10.0.2.2');
    }

    return null;
  }

  Future<dynamic> _rebuildRetryData(RequestOptions requestOptions) async {
    final factory = requestOptions.extra['retry_data_factory'];
    if (factory is RetryDataFactory) {
      return factory();
    }
    return null;
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    baseUrl: ref.watch(apiBaseUrlProvider),
    authBox: ref.watch(authBoxProvider),
  );
});

final dioProvider = Provider<Dio>((ref) {
  return ref.watch(apiClientProvider).createDio();
});
