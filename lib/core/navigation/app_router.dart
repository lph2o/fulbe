import 'package:flutter/material.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/library/library_screen.dart';
import '../../features/jobs/jobs_screen.dart';
import '../../features/finances/finances_screen.dart';
import '../../features/learning/learning_screen.dart';
import '../../features/messages/messages_screen.dart';
import '../navigation/main_shell.dart';

abstract class AppRoutes {
  static const welcome = '/';
  static const home = '/home';
  static const map = '/map';
  static const directory = '/directory';
  static const marketplace = '/marketplace';
  static const profile = '/profile';
  static const library = '/library';
  static const jobs = '/jobs';
  static const finances = '/finances';
  static const learn = '/learn';
  static const messages = '/messages';
}

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.welcome:
      return _fadeRoute(const WelcomeScreen());
    case AppRoutes.home:
      return _fadeRoute(const MainShell(initialIndex: 0));
    case AppRoutes.map:
      return _fadeRoute(const MainShell(initialIndex: 1));
    case AppRoutes.directory:
      return _fadeRoute(const MainShell(initialIndex: 2));
    case AppRoutes.marketplace:
      return _fadeRoute(const MainShell(initialIndex: 3));
    case AppRoutes.profile:
      return _fadeRoute(const MainShell(initialIndex: 4));
    case AppRoutes.library:
      return MaterialPageRoute(builder: (_) => const LibraryScreen());
    case AppRoutes.jobs:
      return MaterialPageRoute(builder: (_) => const JobsScreen());
    case AppRoutes.finances:
      return MaterialPageRoute(builder: (_) => const FinancesScreen());
    case AppRoutes.learn:
      return MaterialPageRoute(builder: (_) => const LearningScreen());
    case AppRoutes.messages:
      return MaterialPageRoute(builder: (_) => const MessagesScreen());
    default:
      return _fadeRoute(const WelcomeScreen());
  }
}

PageRouteBuilder _fadeRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (_, animation, __) => page,
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}
