import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:payhive/core/api/api_endpoints.dart';

// Provider for ApiClient
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: ApiEndpoints.connectionTimeout,
        receiveTimeout: ApiEndpoints.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Interceptors
    _dio.interceptors.add(_AuthInterceptor());
    _dio.interceptors.add(_LoggerInterceptor());

    // Auto retry for network failures
    _dio.interceptors.add(
      RetryInterceptor(
        dio: _dio,
        retries: 3,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 3),
        ],
        retryEvaluator: (error, attempt) {
          return error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.sendTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.connectionError;
        },
      ),
    );
  }

  Dio get dio => _dio;

  // GET
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.get(path, queryParameters: queryParameters, options: options);
  }

  // POST
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // PUT
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // PATCH
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // DELETE
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // File upload
  Future<Response> uploadFile(
    String path, {
    required FormData formData,
    Options? options,
    ProgressCallback? onSendProgress,
  }) async {
    return _dio.post(
      path,
      data: formData,
      options: options,
      onSendProgress: onSendProgress,
    );
  }
}

class _AuthInterceptor extends Interceptor {
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  static const List<String> _publicEndpoints = [
    ApiEndpoints.authLogin,
    ApiEndpoints.authRegister,
    ApiEndpoints.authRequestPasswordReset,
    '/auth/reset-password',
  ];

  bool _isPublicEndpoint(String path) {
    return _publicEndpoints.any((e) => path.startsWith(e));
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublicEndpoint(options.path)) {
      final token = await _storage.read(key: _tokenKey);

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _storage.delete(key: _tokenKey);
    }

    handler.next(err);
  }
}

class _LoggerInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('╔════════════════ REQUEST ════════════════');
      debugPrint('║ ${options.method} ${options.uri}');
      debugPrint('║ Headers: ${options.headers}');

      if (options.queryParameters.isNotEmpty) {
        debugPrint('║ Query: ${options.queryParameters}');
      }

      if (options.data != null) {
        debugPrint('║ Body: ${options.data}');
      }

      debugPrint('╚══════════════════════════════════════════');
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      final request = response.requestOptions;

      debugPrint('╔════════════════ RESPONSE ═══════════════');
      debugPrint(
        '║ ${request.method} ${request.uri} -> ${response.statusCode}',
      );
      debugPrint('║ Data: ${response.data}');
      debugPrint('╚══════════════════════════════════════════');
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final request = err.requestOptions;

      debugPrint('╔════════════════ ERROR ══════════════════');
      debugPrint('║ ${request.method} ${request.uri}');
      debugPrint('║ Status: ${err.response?.statusCode}');
      debugPrint('║ Message: ${err.message}');

      if (err.response?.data != null) {
        debugPrint('║ Response: ${err.response?.data}');
      }

      debugPrint('╚══════════════════════════════════════════');
    }

    handler.next(err);
  }
}