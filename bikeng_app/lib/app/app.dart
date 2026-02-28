import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'theme.dart';
import 'routes.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_storage.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';

class HuoYanJinJingApp extends StatefulWidget {
  const HuoYanJinJingApp({super.key});

  @override
  State<HuoYanJinJingApp> createState() => _HuoYanJinJingAppState();
}

class _HuoYanJinJingAppState extends State<HuoYanJinJingApp> {
  late final SecureStorage _secureStorage;
  late final ApiClient _apiClient;
  late final AuthRepository _authRepository;
  late final AuthCubit _authCubit;

  @override
  void initState() {
    super.initState();
    _secureStorage = SecureStorage();
    _apiClient = ApiClient(secureStorage: _secureStorage);
    _authRepository = AuthRepository(
      apiClient: _apiClient,
      secureStorage: _secureStorage,
    );
    _authCubit = AuthCubit(authRepository: _authRepository)
      ..checkAuthStatus();
  }

  @override
  void dispose() {
    _authCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: _authCubit),
      ],
      child: MaterialApp.router(
        title: '火眼金睛',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        routerConfig: createRouter(_authCubit),
      ),
    );
  }
}
