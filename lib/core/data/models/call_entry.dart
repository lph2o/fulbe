/// Modèle d'entrée d'historique d'appel (onglet APPELS).
///
/// Source de vérité : table Supabase `call_invites` avec jointures membres.
library;

import 'package:meta/meta.dart';

import '../parsers.dart';

/// État final d'un appel pour l'affichage dans l'historique.
enum CallEntryStatus { missed, ended, rejected, cancelled }

/// Entrée d'historique d'appel (1-to-1 uniquement pour l'instant).
@immutable
class CallEntry {
  const CallEntry({
    required this.id,
    required this.callType,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    required this.conversationId,
    required this.otherMemberId,
    required this.otherMemberName,
    this.otherMemberAvatarUrl,
    required this.isOutgoing,
  });

  final String id;
  final String callType; // 'audio' | 'video'
  final CallEntryStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String conversationId;
  final String otherMemberId;
  final String otherMemberName;
  final String? otherMemberAvatarUrl;
  final bool isOutgoing;

  /// Durée formatée "mm:ss" ou null si l'appel n'a pas été connecté.
  String? get durationFormatted {
    if (startedAt == null || endedAt == null) return null;
    final d = endedAt!.difference(startedAt!);
    if (d.inSeconds < 1) return null;
    return '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }

  factory CallEntry.fromJson(Map<String, dynamic> json, String currentMemberId) {
    // Jointure caller:caller_id(name, avatar_url) ou callee:callee_id(name, avatar_url)
    final callerObj = json['caller'] as Map<String, dynamic>?;
    final calleeObj = json['callee'] as Map<String, dynamic>?;

    final callerId = Parsers.string(json, 'caller_id');
    final calleeId = Parsers.string(json, 'callee_id');
    final isOutgoing = callerId == currentMemberId;

    final otherMember = isOutgoing ? calleeObj : callerObj;
    final otherMemberId = isOutgoing ? calleeId : callerId;
    final otherMemberName = otherMember != null
        ? (Parsers.string(otherMember, 'full_name', fallback: Parsers.string(otherMember, 'name')))
        : 'Membre';
    final otherMemberAvatarUrl = otherMember != null
        ? (Parsers.nullableString(otherMember, 'avatar_url') ?? Parsers.nullableString(otherMember, 'avatarUrl'))
        : null;

    return CallEntry(
      id: Parsers.string(json, 'id'),
      callType: Parsers.string(json, 'call_type'),
      status: _parseStatus(Parsers.string(json, 'status')),
      createdAt: Parsers.nullableDateTime(json, 'created_at') ?? DateTime.now(),
      startedAt: Parsers.nullableDateTime(json, 'started_at'),
      endedAt: Parsers.nullableDateTime(json, 'ended_at'),
      conversationId: Parsers.string(json, 'conversation_id'),
      otherMemberId: otherMemberId,
      otherMemberName: otherMemberName,
      otherMemberAvatarUrl: otherMemberAvatarUrl,
      isOutgoing: isOutgoing,
    );
  }

  static CallEntryStatus _parseStatus(String s) {
    switch (s) {
      case 'missed':
        return CallEntryStatus.missed;
      case 'ended':
        return CallEntryStatus.ended;
      case 'rejected':
        return CallEntryStatus.rejected;
      case 'cancelled':
        return CallEntryStatus.cancelled;
      default:
        return CallEntryStatus.ended; // pending/accepted → fallback
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CallEntry && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
