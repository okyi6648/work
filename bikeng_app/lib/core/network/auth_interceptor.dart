import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;
  final SecureStorage secureStorage;
  bool _isRefreshing = false;

  AuthInterceptor({
    required this.dio,
    required this.secureStorage,
  });

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for login/sms endpoints
    final noAuthPaths = [
      ApiConstants.smsSend,
      ApiConstants.smsVerify,
    ];
    if (noAuthPaths.contains(options.path)) {
      return handler.next(options);
    }

    final accessToken = await secureStorage.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;

      try {
        final refreshToken = await secureStorage.getRefreshToken();
        if (refreshToken == null || refreshToken.isEmpty) {
          await _clearAndReject(err, handler);
          return;
        }

        // Attempt to refresh the token
        final response = await Dio(BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )).post(
          ApiConstants.refreshToken,
          data: {'refresh_token': refreshToken},
        );

        if (response.statusCode == 200) {
          final newAccessToken = response.data['access_token'] as String;
          final newRefreshToken = response.data['refresh_token'] as String;

          await secureStorage.saveAccessToken(newAccessToken);
          await secureStorage.saveRefreshToken(newRefreshToken);

          // Retry the original request
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newAccessToken';

          final retryResponse = await dio.fetch(options);
          _isRefreshing = false;
          return handler.resolve(retryResponse);
        } else {
          await _clearAndReject(err, handler);
        }
      } catch (e) {
        await _clearAndReject(err, handler);
      }
    } else {
      return handler.next(err);
    }
  }

  Future<void> _clearAndReject(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    _isRefreshing = false;
    await secureStorage.clearAll();
    handler.reject(err);
  }
}
