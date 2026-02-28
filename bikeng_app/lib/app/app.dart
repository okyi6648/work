import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'theme.dart';
import 'routes.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_storage.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';

class BiKengApp extends StatefulWidget {
  const BiKengApp({super.key});

  @override
  State<BiKengApp> createState() => _BiKengAppState();
}

class _BiKengAppState extends State<BiKengApp> {
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
        title: '避坑',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        routerConfig: createRouter(_authCubit),
      ),
    );
  }
}
