import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;

  AuthCubit({required this.authRepository}) : super(const AuthInitial());

  /// Check if user is already logged in.
  Future<void> checkAuthStatus() async {
    try {
      final loggedIn = await authRepository.isLoggedIn();
      if (loggedIn) {
        emit(const AuthAuthenticated());
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }

  /// Request sending an SMS code to the given phone number.
  Future<void> sendSmsCode(String phone) async {
    emit(const AuthLoading());
    try {
      await authRepository.sendSmsCode(phone);
      emit(AuthSmsSent(phone: phone));
    } catch (e) {
      emit(AuthError(message: '发送验证码失败：${_parseError(e)}'));
    }
  }

  /// Verify the SMS code and login.
  Future<void> verifySmsCode(String phone, String code) async {
    emit(const AuthLoading());
    try {
      await authRepository.verifySmsCode(phone, code);
      emit(const AuthAuthenticated());
    } catch (e) {
      emit(AuthError(message: '登录失败：${_parseError(e)}'));
    }
  }

  /// Logout.
  Future<void> logout() async {
    emit(const AuthLoading());
    try {
      await authRepository.logout();
    } catch (_) {
      // Ignore errors during logout
    } finally {
      emit(const AuthUnauthenticated());
    }
  }

  String _parseError(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return '未知错误';
  }
}
