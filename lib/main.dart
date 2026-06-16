import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/navigation/app_router.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/config_error_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await initializeDateFormatting('fr_FR', null);

  // ── Garde-fou de configuration ────────────────────────────────────────
  final hasValidConfig = AppConstants.hasSupabaseConfig;

  if (hasValidConfig) {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      publishableKey: AppConstants.supabasePublishableKey,
    );
  } else {
    debugPrint(
      '[FulbeConnect] Configuration Supabase manquante. '
      "L'écran d'erreur de configuration sera affiché. "
      'Renseignez SUPABASE_URL et SUPABASE_PUBLISHABLE_KEY via '
      '--dart-define (voir .env.example).',
    );
  }

  runApp(ProviderScope(
    child: FulbeConnectApp(hasValidConfig: hasValidConfig),
  ));
}

class FulbeConnectApp extends StatefulWidget {
  final bool hasValidConfig;

  const FulbeConnectApp({
    super.key,
    required this.hasValidConfig,
  });

  @override
  State<FulbeConnectApp> createState() => _FulbeConnectAppState();
}

class _FulbeConnectAppState extends State<FulbeConnectApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<DeepLink>? _deepLinkSub;

  @override
  void initState() {
    super.initState();
    if (widget.hasValidConfig) {
      _initDeepLinks();
      _initNotifications();
    }
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    NotificationService.instance.dispose();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    final service = DeepLinkService();
    _deepLinkSub = service.links.listen(_handleDeepLink);
  }

  Future<void> _initNotifications() async {
    await NotificationService.instance.initialize();

    // Navigation quand l'utilisateur tape sur une notification d'appel.
    NotificationService.onIncomingCallTap = ({
      required callInviteId,
      required channelName,
      required callerId,
      required calleeId,
      required conversationId,
      required callType,
    }) {
      final nav = _navigatorKey.currentState;
      if (nav == null) return;

      nav.pushNamed(
        AppRoutes.incomingCall,
        arguments: {
          'callInviteId': callInviteId,
          'channelName': channelName,
          'callerId': callerId,
          'calleeId': calleeId,
          'conversationId': conversationId,
          'callType': callType,
        },
      );
    };
  }

  void _handleDeepLink(DeepLink link) {
    switch (link) {
      case ProfileDeepLink(:final memberId):
        _navigateToProfile(memberId);
      case UnknownDeepLink():
        break; // ignoré silencieusement
    }
  }

  void _navigateToProfile(String memberId) {
    final nav = _navigatorKey.currentState;
    if (nav == null) return;

    // Remplace toute la pile par la route cible
    nav.pushNamedAndRemoveUntil(
      AppRoutes.publicProfile,
      arguments: memberId,
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fulɓe Connect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      navigatorKey: _navigatorKey,
      home: widget.hasValidConfig ? null : const ConfigErrorScreen(),
      initialRoute:
          widget.hasValidConfig ? AppRoutes.authGate : null,
      onGenerateRoute:
          widget.hasValidConfig ? generateRoute : null,
    );
  }
}
