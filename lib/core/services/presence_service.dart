import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service de présence en ligne.
///
/// ### Fonctionnement
/// 1. **Heartbeat** : toutes les 60 secondes, appelle la RPC `update_last_seen()`
///    pour mettre à jour `members.last_seen` de l'utilisateur courant.
/// 2. **Souscription Realtime** : écoute les changements sur `public.members`
///    pour les IDs surveillés et notifie les listeners via [onPresenceChanged].
/// 3. **Statut en ligne** : un membre est considéré "en ligne" si son
///    `last_seen` est à moins de 2 minutes.
class PresenceService {
  PresenceService._();

  static final PresenceService instance = PresenceService._();

  Timer? _heartbeatTimer;
  RealtimeChannel? _presenceChannel;

  /// IDs des membres actuellement surveillés.
  final Set<String> _watchedMemberIds = {};

  /// Cache des statuts : memberId → DateTime du dernier last_seen connu.
  final Map<String, DateTime> _lastSeenCache = {};

  /// StreamController pour diffuser les changements de présence.
  final _controller = StreamController<Map<String, DateTime>>.broadcast();

  /// Flux des statuts de présence pour les membres surveillés.
  /// Émet une map : memberId → lastSeenDateTime à chaque changement.
  Stream<Map<String, DateTime>> get presenceStream => _controller.stream;

  /// Durée après laquelle un membre est considéré "hors ligne".
  static const offlineThreshold = Duration(minutes: 2);

  // ── Initialisation et cycle de vie ──────────────────────────────────

  /// Démarre le heartbeat et la souscription Realtime.
  ///
  /// Appeler dans le `initState` de l'écran qui a besoin de présence.
  void start({Set<String>? watchMemberIds}) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _updatePresence(),
    );
    // Premier heartbeat immédiat
    _updatePresence();

    if (watchMemberIds != null && watchMemberIds.isNotEmpty) {
      watch(watchMemberIds);
    }
  }

  /// Arrête le heartbeat et la souscription Realtime.
  ///
  /// Appeler dans le `dispose` de l'écran.
  void stop() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _presenceChannel?.unsubscribe();
    _presenceChannel = null;
    _watchedMemberIds.clear();
  }

  // ── Surveillance de membres ─────────────────────────────────────────

  /// Ajoute des IDs de membres à surveiller (s'abonne via Realtime).
  void watch(Set<String> memberIds) {
    final newIds = memberIds.difference(_watchedMemberIds);
    if (newIds.isEmpty) return;

    _watchedMemberIds.addAll(newIds);
    _resubscribe();
  }

  /// Retire des IDs de membres de la surveillance.
  void unwatch(Set<String> memberIds) {
    _watchedMemberIds.removeAll(memberIds);
    if (_watchedMemberIds.isEmpty) {
      _presenceChannel?.unsubscribe();
      _presenceChannel = null;
    } else {
      _resubscribe();
    }
  }

  // ── Statut en ligne ─────────────────────────────────────────────────

  /// Retourne `true` si le membre est considéré en ligne
  /// (last_seen datant de moins de 2 minutes).
  bool isOnline(String memberId) {
    final lastSeen = _lastSeenCache[memberId];
    if (lastSeen == null) return false;
    return DateTime.now().difference(lastSeen) < offlineThreshold;
  }

  /// Retourne le [DateTime] du dernier `last_seen` connu pour ce membre.
  DateTime? lastSeenOf(String memberId) => _lastSeenCache[memberId];

  /// Texte formaté pour le statut de présence.
  ///
  /// - "En ligne" si connecté dans les 2 dernières minutes
  /// - "Vu à l'instant" si connecté dans la dernière minute
  /// - "Vu il y a X min" si connecté il y a moins d'une heure
  /// - "Vu à HH:MM" si connecté aujourd'hui
  /// - "Vu le JJ/MM à HH:MM" si hier ou avant
  String presenceText(String memberId) {
    final lastSeen = _lastSeenCache[memberId];
    if (lastSeen == null) return 'Hors ligne';

    final now = DateTime.now();
    final diff = now.difference(lastSeen);

    if (isOnline(memberId)) return 'En ligne';
    if (diff.inSeconds < 60) return 'Vu à l\'instant';
    if (diff.inMinutes < 60) {
      return 'Vu il y a ${diff.inMinutes} min';
    }
    if (diff.inDays < 1) {
      final hour = lastSeen.hour.toString().padLeft(2, '0');
      final minute = lastSeen.minute.toString().padLeft(2, '0');
      return 'Vu à $hour:$minute';
    }
    final day = lastSeen.day.toString().padLeft(2, '0');
    final month = lastSeen.month.toString().padLeft(2, '0');
    final hour = lastSeen.hour.toString().padLeft(2, '0');
    final minute = lastSeen.minute.toString().padLeft(2, '0');
    return 'Vu le $day/$month à $hour:$minute';
  }

  // ── Interne ─────────────────────────────────────────────────────────

  Future<void> _updatePresence() async {
    try {
      await Supabase.instance.client.rpc('update_last_seen');
    } catch (e) {
      debugPrint('[PresenceService] Heartbeat error: $e');
    }
  }

  void _resubscribe() {
    _presenceChannel?.unsubscribe();

    if (_watchedMemberIds.isEmpty) return;

    _presenceChannel = Supabase.instance.client
        .channel('presence_service')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'members',
          callback: (payload) {
            _handlePresenceChange(payload);
          },
        )
        .subscribe();
  }

  void _handlePresenceChange(PostgresChangePayload payload) {
    final newRecord = payload.newRecord;
    final memberId = newRecord['id'] as String?;
    if (memberId == null || !_watchedMemberIds.contains(memberId)) return;

    final lastSeenRaw = newRecord['last_seen'] as String?;
    if (lastSeenRaw == null) return;

    final lastSeen = DateTime.tryParse(lastSeenRaw);
    if (lastSeen == null) return;

    _lastSeenCache[memberId] = lastSeen;
    // Notifie les listeners avec une copie fraîche
    _controller.add(Map.of(_lastSeenCache));
  }

  /// Nettoie le stream controller.
  void dispose() {
    stop();
    _controller.close();
  }
}
