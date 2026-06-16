import 'package:supabase_flutter/supabase_flutter.dart';

import '../../errors/app_exception.dart';
import '../models/call_entry.dart';

/// Repository pour l'historique des appels (onglet APPELS).
class CallHistoryRepository {
  const CallHistoryRepository();

  /// Récupère l'historique des appels (1-to-1) du membre courant,
  /// trié du plus récent au plus ancien.
  ///
  /// Joint les infos membre (name, avatar_url) pour l'autre participant.
  Future<List<CallEntry>> fetchCallHistory(String memberId) async {
    try {
      final response = await Supabase.instance.client
          .from('call_invites')
          .select('id, call_type, status, created_at, started_at, ended_at, conversation_id, caller_id, callee_id, '
              'caller:caller_id(full_name, avatar_url), '
              'callee:callee_id(full_name, avatar_url)')
          .or('caller_id.eq.$memberId,callee_id.eq.$memberId')
          .inFilter('status', ['ended', 'missed', 'rejected', 'cancelled'])
          .order('created_at', ascending: false)
          .limit(50);

      return (response as List)
          .cast<Map<String, dynamic>>()
          .map((json) => CallEntry.fromJson(json, memberId))
          .toList(growable: false);
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger l\'historique des appels.',
        cause: e,
        stackTrace: st,
      );
    }
  }
}
