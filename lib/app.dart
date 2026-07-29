import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'core/locale/locale_controller.dart';
import 'core/locale/locale_scope.dart';
import 'core/notifications/notification_scope.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/category_repository.dart';
import 'data/repositories/chat_repository.dart';
import 'data/repositories/dashboard_repository.dart';
import 'data/repositories/job_post_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/repositories/order_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'data/repositories/transaction_repository.dart';
import 'l10n/app_localizations.dart';
import 'router/app_router.dart';

class HupWorksApp extends StatefulWidget {
  const HupWorksApp({super.key, required this.localeController});

  final LocaleController localeController;

  @override
  State<HupWorksApp> createState() => _HupWorksAppState();
}

class _HupWorksAppState extends State<HupWorksApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter();
  }

  @override
  Widget build(BuildContext context) {
    return LocaleScope(
      controller: widget.localeController,
      child: MultiRepositoryProvider(
        providers: [
          RepositoryProvider(create: (_) => ProfileRepository()),
          RepositoryProvider(create: (_) => CategoryRepository()),
          RepositoryProvider(create: (_) => OrderRepository()),
          RepositoryProvider(create: (_) => ChatRepository()),
          RepositoryProvider(create: (_) => JobPostRepository()),
          RepositoryProvider(create: (_) => NotificationRepository()),
          RepositoryProvider(create: (_) => TransactionRepository()),
          RepositoryProvider(create: (_) => DashboardRepository()),
        ],
        // Auth uses AuthService + GoRouter session today.
        // AuthBloc / AuthRepository live under lib/features/auth and
        // lib/data/repositories/auth_repository.dart — parked until screens migrate.
        child: NotificationScope(
          child: ListenableBuilder(
            listenable: widget.localeController,
            builder: (context, _) {
              return MaterialApp.router(
                onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
                debugShowCheckedModeBanner: false,
                theme: appTheme(),
                routerConfig: _router,
                locale: widget.localeController.locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
              );
            },
          ),
        ),
      ),
    );
  }
}
