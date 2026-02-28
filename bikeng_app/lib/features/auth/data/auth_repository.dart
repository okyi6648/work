import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/storage/secure_storage.dart';

class AuthRepository {
  final ApiClient apiClient;
  final SecureStorage secureStorage;

  AuthRepository({
    required this.apiClient,
    required this.secureStorage,
  });

  /// Send SMS verification code to the given phone number.
  Future<void> sendSmsCode(String phone, {String purpose = 'login'}) async {
    await apiClient.post(
      ApiConstants.smsSend,
      data: {
        'phone': phone,
        'purpose': purpose,
      },
    );
  }

  /// Verify SMS code and save tokens on success.
  Future<void> verifySmsCode(String phone, String code) async {
    final response = await apiClient.post(
      ApiConstants.smsVerify,
      data: {
        'phone': phone,
        'code': code,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final accessToken = data['access_token'] as String;
    final refreshToken = data['refresh_token'] as String;

    await secureStorage.saveAccessToken(accessToken);
    await secureStorage.saveRefreshToken(refreshToken);
  }

  /// Refresh the access token using the stored refresh token.
  Future<void> refreshToken() async {
    final currentRefreshToken = await secureStorage.getRefreshToken();
    if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
      throw Exception('No refresh token available');
    }

    final response = await apiClient.post(
      ApiConstants.refreshToken,
      data: {
        'refresh_token': currentRefreshToken,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final newAccessToken = data['access_token'] as String;
    final newRefreshToken = data['refresh_token'] as String;

    await secureStorage.saveAccessToken(newAccessToken);
    await secureStorage.saveRefreshToken(newRefreshToken);
  }

  /// Logout: call API and clear stored tokens.
  Future<void> logout() async {
    try {
      await apiClient.post(ApiConstants.logout);
    } catch (_) {
      // Even if API call fails, we still clear local storage
    } finally {
      await secureStorage.clearAll();
    }
  }

  /// Check whether the user is logged in by looking for a stored access token.
  Future<bool> isLoggedIn() async {
    final token = await secureStorage.getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
