import 'package:diyalizmobile/app/pages/about_page.dart';
import 'package:diyalizmobile/app/pages/splash_page.dart';
import 'package:diyalizmobile/app/widgets/main_shell.dart';
import 'package:diyalizmobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:diyalizmobile/features/auth/presentation/pages/login_page.dart';
import 'package:diyalizmobile/features/auth/presentation/pages/register_page.dart';
import 'package:diyalizmobile/features/modules/presentation/controllers/modules_controller.dart';
import 'package:diyalizmobile/features/modules/presentation/pages/home_page.dart';
import 'package:diyalizmobile/features/modules/presentation/pages/module_page.dart';
import 'package:diyalizmobile/features/profile/presentation/pages/profile_page.dart';
import 'package:diyalizmobile/features/question/presentation/pages/question_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authIsLoading = ref.watch(
    authControllerProvider.select((state) => state.isLoading),
  );
  final authIsAuthenticated = ref.watch(
    authControllerProvider.select((state) => state.isAuthenticated),
  );
  final modulesAsync = ref.watch(modulesControllerProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoading = authIsLoading;
      final isAuthenticated = authIsAuthenticated;
      final location = state.matchedLocation;

      if (isLoading && location != '/splash') {
        return '/splash';
      }

      if (!isLoading && location == '/splash') {
        return isAuthenticated ? '/home' : '/login';
      }

      if (!isAuthenticated &&
          location != '/login' &&
          location != '/register' &&
          location != '/splash' &&
          location != '/about') {
        return '/login';
      }

      if (isAuthenticated &&
          (location == '/login' ||
              location == '/register' ||
              location == '/splash')) {
        return '/home';
      }

      if (location.startsWith('/module/')) {
        final moduleId = state.pathParameters['id'];
        if (moduleId != null && modulesAsync.hasValue) {
          final modules = modulesAsync.value ?? const [];
          final selected = modules.where((m) => m.id == moduleId).firstOrNull;
          if (selected == null || !selected.isUnlocked) {
            return '/home';
          }
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, _) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, _) => const RegisterPage(),
      ),
      GoRoute(
        path: '/about',
        builder: (_, _) => const AboutPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, _) => const HomePage(),
                routes: [
                  GoRoute(
                    path: 'module/:id',
                    builder: (_, state) => ModulePage(
                      moduleId: state.pathParameters['id'] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ask',
                builder: (_, _) => const QuestionPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
