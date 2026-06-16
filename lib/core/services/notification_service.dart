import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'call_service.dart';

/// Handler exécuté en background (isolé) quand un message FCM arrive.
///
/// Doit être une top-level function ou static, et ne doit pas dépendre
/// de l'état UI.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.data}');

  // Initialise le plugin local pour afficher la notification même en background.
  await _showLocalNotificationFromMessage(message);
}

/// Affiche une notification locale à partir d'un message FCM.
///
/// Utilisé à la fois en foreground et en background.
/// En foreground, passez [plugin] pour éviter de recréer le plugin.
Future<void> _showLocalNotificationFromMessage(
  RemoteMessage message, {
  FlutterLocalNotificationsPlugin? plugin,
}) async {
  final effectivePlugin = plugin ?? FlutterLocalNotificationsPlugin();

  // En background, le plugin doit être initialisé avant show().
  if (plugin == null) {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );
    await effectivePlugin.initialize(initSettings);
  }

  final data = message.data;
  final type = data['type'] as String?;

  if (type != 'call') return;

  final callInviteId = data['call_invite_id'] as String? ?? '';
  final callerName = data['caller_name'] as String? ?? 'Appel entrant';
  final callType = data['call_type'] as String? ?? 'audio';
  final channelName = data['channel_name'] as String? ?? '';
  final callerId = data['caller_id'] as String? ?? '';
  final calleeId = data['callee_id'] as String? ?? '';
  final conversationId = data['conversation_id'] as String? ?? '';

  final isVideo = callType == 'video';
  final title = isVideo ? '📹 Appel vidéo de $callerName' : '📞 Appel de $callerName';
  const body = 'Appuyez pour répondre';

  final payload = 'call|$callInviteId|$channelName|$callerId|$calleeId|$conversationId|$callType';

  const androidDetails = AndroidNotificationDetails(
    'call_invites',
    'Appels entrants',
    channelDescription: 'Notifications pour les appels audio et vidéo entrants',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'Appel entrant',
    showWhen: true,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.call,
    actions: <AndroidNotificationAction>[
      AndroidNotificationAction(
        'accept_call',
        'Accepter',
        showsUserInterface: true,
      ),
      AndroidNotificationAction(
        'reject_call',
        'Refuser',
      ),
    ],
  );

  const darwinDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    interruptionLevel: InterruptionLevel.timeSensitive,
  );

  const notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: darwinDetails,
    macOS: darwinDetails,
  );

  await effectivePlugin.show(
    callInviteId.hashCode,
    title,
    body,
    notificationDetails,
    payload: payload,
  );
}

/// Service central de gestion des notifications push et locales.
///
/// Responsabilités :
///   1. Initialise Firebase Messaging au démarrage de l'app.
///   2. Demande la permission de notification (iOS + Android 13+).
///   3. Enregistre le token FCM dans Supabase (table `member_fcm_tokens`).
///   4. Écoute les messages FCM en foreground et background.
///   5. Affiche les notifications locales avec actions (Accepter / Refuser).
///   6. Gère les taps sur les notifications et les actions rapides.
class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  late final FirebaseMessaging _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? _currentToken;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<String>? _tokenRefreshSub;

  // ── Initialisation ─────────────────────────────────────────────────────

  /// Initialise Firebase Messaging + notifications locales.
  ///
  /// À appeler une fois dans `main.dart` après `Supabase.initialize`.
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Firebase Core
    try {
      await Firebase.initializeApp();
      _firebaseMessaging = FirebaseMessaging.instance;
    } catch (e) {
      debugPrint('[NotificationService] Firebase non configuré: $e');
      return;
    }

    // 2. Permission de notification
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );
    debugPrint(
        '[NotificationService] Permission: ${settings.authorizationStatus}');

    // 3. Handler background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Initialisation du plugin local
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
    );

    // 5. Crée le canal Android une seule fois
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'call_invites',
      'Appels entrants',
      description: 'Notifications pour les appels audio et vidéo entrants',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 6. Écoute les messages en foreground
    _foregroundSub = FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM] Foreground message: ${message.data}');
      _showLocalNotificationFromMessage(message, plugin: _localNotifications);
    });

    // 6. Récupère le token initial et l'enregistre
    await _registerToken();

    // 7. Écoute le rafraîchissement du token
    _tokenRefreshSub = _firebaseMessaging.onTokenRefresh.listen((token) {
      _currentToken = token;
      _saveTokenToSupabase(token);
    });

    // 8. Écoute les taps sur notification quand l'app était en background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM] onMessageOpenedApp: ${message.data}');
      final data = message.data;
      if (data['type'] == 'call') {
        _handleAcceptCall(
          callInviteId: data['call_invite_id'] as String? ?? '',
          channelName: data['channel_name'] as String? ?? '',
          callerId: data['caller_id'] as String? ?? '',
          calleeId: data['callee_id'] as String? ?? '',
          conversationId: data['conversation_id'] as String? ?? '',
          callType: data['call_type'] == 'video' ? CallType.video : CallType.audio,
        );
      }
    });

    _isInitialized = true;
  }

  // ── Token management ───────────────────────────────────────────────────

  /// Récupère et enregistre le token FCM courant.
  Future<void> _registerToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        _currentToken = token;
        await _saveTokenToSupabase(token);
      }
    } catch (e) {
      debugPrint('[NotificationService] Erreur token FCM: $e');
    }
  }

  /// Enregistre le token FCM dans Supabase.
  ///
  /// La table `member_fcm_tokens` stocke les tokens par membre_id.
  /// Un membre peut avoir plusieurs tokens (multi-device).
  Future<void> _saveTokenToSupabase(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('member_fcm_tokens').upsert({
        'member_id': user.id,
        'token': token,
        'platform': Platform.operatingSystem,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'token');
    } catch (e) {
      debugPrint('[NotificationService] Erreur sauvegarde token: $e');
    }
  }

  /// Supprime le token FCM de Supabase (appelé au logout).
  Future<void> removeToken() async {
    if (_currentToken == null) return;
    try {
      await Supabase.instance.client
          .from('member_fcm_tokens')
          .delete()
          .eq('token', _currentToken!);
    } catch (e) {
      debugPrint('[NotificationService] Erreur suppression token: $e');
    }
  }

  // ── Notification handlers ────────────────────────────────────────────

  /// Gère la réponse à une notification locale (foreground / app ouverte).
  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || !payload.startsWith('call|')) return;

    final parts = payload.split('|');
    if (parts.length < 7) return;

    final callInviteId = parts[1];
    final channelName = parts[2];
    final callerId = parts[3];
    final calleeId = parts[4];
    final conversationId = parts[5];
    final callType = parts[6] == 'video' ? CallType.video : CallType.audio;

    if (response.actionId == 'accept_call') {
      _handleAcceptCall(
        callInviteId: callInviteId,
        channelName: channelName,
        callerId: callerId,
        calleeId: calleeId,
        conversationId: conversationId,
        callType: callType,
      );
    } else if (response.actionId == 'reject_call') {
      _handleRejectCall(
        callInviteId: callInviteId,
        callerId: callerId,
        calleeId: calleeId,
        conversationId: conversationId,
        callType: callType,
      );
    } else if (response.notificationResponseType ==
        NotificationResponseType.selectedNotification) {
      // Tap simple sur la notification → ouvre l'appel entrant
      _handleAcceptCall(
        callInviteId: callInviteId,
        channelName: channelName,
        callerId: callerId,
        calleeId: calleeId,
        conversationId: conversationId,
        callType: callType,
      );
    }
  }

  /// Gère la réponse en background (action rapide quand l'app est fermée).
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    // En background, on ne peut pas naviguer dans l'app.
    // Si l'utilisateur tape "Accepter", on laisse la notification
    // ouvrir l'app, puis le foreground handler gère la suite.
    // Si l'utilisateur tape "Refuser", on met à jour le statut via Supabase.
    final payload = response.payload;
    if (payload == null || !payload.startsWith('call|')) return;

    final parts = payload.split('|');
    if (parts.length < 7) return;

    final callInviteId = parts[1];

    if (response.actionId == 'reject_call') {
      // Vérifie que Supabase est initialisé avant d'appeler le client.
      try {
        final client = Supabase.instance.client;
        client
            .from('call_invites')
            .update({'status': 'rejected'})
            .eq('id', callInviteId)
            .then((_) => debugPrint('[FCM] Call rejected in background'))
            .catchError((e) => debugPrint('[FCM] Error rejecting call: $e'));
      } catch (e) {
        debugPrint('[FCM] Supabase not initialized in background: $e');
      }
    }
  }

  // ── Navigation helpers ─────────────────────────────────────────────────

  void _handleAcceptCall({
    required String callInviteId,
    required String channelName,
    required String callerId,
    required String calleeId,
    required String conversationId,
    required CallType callType,
  }) {
    // La navigation est gérée par le parent (main.dart ou ConversationDetailScreen)
    // via un event bus ou un global navigator key.
    onIncomingCallTap?.call(
      callInviteId: callInviteId,
      channelName: channelName,
      callerId: callerId,
      calleeId: calleeId,
      conversationId: conversationId,
      callType: callType,
    );
  }

  void _handleRejectCall({
    required String callInviteId,
    required String callerId,
    required String calleeId,
    required String conversationId,
    required CallType callType,
  }) {
    final callData = CallData(
      callInviteId: callInviteId,
      channelName: '',
      callerId: callerId,
      calleeId: calleeId,
      conversationId: conversationId,
      callType: callType,
      status: CallStatus.ringing,
    );
    CallService.instance.rejectCall(callData).catchError((e) {
      debugPrint('[NotificationService] Reject error: $e');
    });
  }

  /// Callback appelé quand l'utilisateur tape sur une notification d'appel.
  ///
  /// Doit être assigné par le navigateur de l'app pour ouvrir l'écran
  /// d'appel entrant.
  static void Function({
    required String callInviteId,
    required String channelName,
    required String callerId,
    required String calleeId,
    required String conversationId,
    required CallType callType,
  })? onIncomingCallTap;

  // ── Cleanup ────────────────────────────────────────────────────────────

  /// Libère les ressources.
  Future<void> dispose() async {
    await _foregroundSub?.cancel();
    await _tokenRefreshSub?.cancel();
    _foregroundSub = null;
    _tokenRefreshSub = null;
  }
}
