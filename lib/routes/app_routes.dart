import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../presentation/appointments_screen/appointments_screen.dart';
import '../presentation/dashboard_screen/dashboard_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/patients_screen/patients_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';
import '../widgets/app_scaffold.dart';

class AppRoutes {
  static const String initial = '/';
  static const String loginScreen = '/login-screen';
  static const String dashboardScreen = '/dashboard-screen';
  static const String appointmentsScreen = '/appointments-screen';
  static const String patientsScreen = '/patients-screen';
  static const String profileScreen = '/profile-screen';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.initial,
  routes: [
    GoRoute(
      path: AppRoutes.initial,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 280),
      ),
    ),
    GoRoute(
      path: AppRoutes.loginScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 280),
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppScaffold(navigationShell: navigationShell);
      },
      branches: [
        // Branch 0 — Dashboard
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.dashboardScreen,
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const DashboardScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(0.04, 0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                transitionDuration: const Duration(milliseconds: 280),
              ),
            ),
          ],
        ),
        // Branch 1 — Appointments
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.appointmentsScreen,
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const AppointmentsScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(0.04, 0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                transitionDuration: const Duration(milliseconds: 280),
              ),
            ),
          ],
        ),
        // Branch 2 — Patients
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.patientsScreen,
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const PatientsScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(0.04, 0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                transitionDuration: const Duration(milliseconds: 280),
              ),
            ),
          ],
        ),
        // Branch 3 — Profile
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profileScreen,
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const ProfileScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(0.04, 0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                transitionDuration: const Duration(milliseconds: 280),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
