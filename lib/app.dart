import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/category_repository.dart';
import 'data/repositories/chat_repository.dart';
import 'data/repositories/dashboard_repository.dart';
import 'data/repositories/job_post_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/repositories/order_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'data/repositories/recently_viewed_repository.dart';
import 'data/repositories/service_repository.dart';
import 'data/repositories/transaction_repository.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'router/app_router.dart';

class HupWorksApp extends StatefulWidget {
  const HupWorksApp({super.key});

  @override
  State<HupWorksApp> createState() => _HupWorksAppState();
}

class _HupWorksAppState extends State<HupWorksApp> {
  late final AuthRepository _authRepository;
  late final AuthBloc _authBloc;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepository();
    _authBloc = AuthBloc(authRepository: _authRepository)..add(AuthCheckRequested());
    _router = createRouter(_authBloc);
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _authRepository),
        RepositoryProvider(create: (_) => ProfileRepository()),
        RepositoryProvider(create: (_) => CategoryRepository()),
        RepositoryProvider(create: (_) => ServiceRepository()),
        RepositoryProvider(create: (_) => OrderRepository()),
        RepositoryProvider(create: (_) => ChatRepository()),
        RepositoryProvider(create: (_) => JobPostRepository()),
        RepositoryProvider(create: (_) => NotificationRepository()),
        RepositoryProvider(create: (_) => TransactionRepository()),
        RepositoryProvider(create: (_) => DashboardRepository()),
        RepositoryProvider(create: (_) => RecentlyViewedRepository()),
      ],
      child: BlocProvider.value(
        value: _authBloc,
        child: MaterialApp.router(
          title: 'HupWorks',
          theme: appTheme(),
          routerConfig: _router,
        ),
      ),
    );
  }
}
