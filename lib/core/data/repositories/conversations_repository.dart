import 'package:flutter/foundation.dart';

import '../../errors/app_exception.dart';
import '../../logging/app_logger.dart';
import '../models/conversation.dart';
import '../models/member.dart';
import '../supabase_fetchers.dart';

/// Repository d'accès aux conversations et messages.
///
/// Utilise les tables Supabase :
///   - `conversations` (type, name)
///   - `conversation_participants` (members liés à une conversation)
///   - `messages` (contenu des messages)
class ConversationsRepository {
  const ConversationsRepository();

  /// Récupère toutes les conversations (directes + groupes) de l'utilisateur
  /// courant, avec le dernier message et le nombre de non lus.
  ///
  /// Retourne une liste vide si l'utilisateur n'est pas authentifié.
  Future<List<Conversation>> fetchAll() async {
    final authUser = SupabaseFetchers.client.auth.currentUser;
    if (authUser == null) return [];

    try {
      // 0. Résout members.id à partir de authUser.id (auth.users)
      //    car conversation_participants.member_id référence members.id.
      final memberRows = await SupabaseFetchers.selectAll(
        'members',
        columns: 'id',
        limit: 1,
        eq: {'user_id': authUser.id},
      );
      if (memberRows.isEmpty) return [];
      final currentMemberId = memberRows.first['id'] as String;

      // 1. Récupère les IDs des conversations où l'utilisateur participe
      final cpRows = await SupabaseFetchers.selectAll(
        'conversation_participants',
        columns: 'conversation_id, last_read_at',
        eq: {'member_id': currentMemberId},
      );

      if (cpRows.isEmpty) return [];

      final conversationIds = cpRows
          .map((r) => r['conversation_id'] as String)
          .toList(growable: false);

      // Map : conversation_id → last_read_at
      final lastReadByConv = <String, String?>{};
      for (final r in cpRows) {
        lastReadByConv[r['conversation_id'] as String] =
            r['last_read_at'] as String?;
      }

      // 2. Récupère les conversations
      final convRows = await SupabaseFetchers.selectAll(
        'conversations',
        orderBy: 'updated_at',
        ascending: false,
      );

      // 3. Pour chaque conversation, récupère le dernier message
      final conversations = <_ConversationWithTime>[];
      for (final conv in convRows) {
        if (!conversationIds.contains(conv['id'] as String)) continue;

        final convId = conv['id'] as String;
        final isGroup = conv['type'] as String == 'group';

        // Dernier message (avec metadata pour l'aperçu enrichi)
        final msgRows = await SupabaseFetchers.selectAll(
          'messages',
          columns: 'content, metadata, created_at, sender_id',
          orderBy: 'created_at',
          ascending: false,
          limit: 1,
          eq: {'conversation_id': convId},
        );

        String lastMessage = '';
        DateTime? lastMessageAt;
        if (msgRows.isNotEmpty) {
          final msg = msgRows.first;
          final content = msg['content'] as String? ?? '';
          final metadata = msg['metadata'] as Map<String, dynamic>?;
          lastMessage = _previewForMessage(content, metadata);
          final createdAt = msg['created_at'] as String?;
          if (createdAt != null) {
            lastMessageAt = DateTime.tryParse(createdAt);
          }
        }

        // Nom et avatar
        String name;
        String? avatarUrl;
        int memberCount = 0;

        if (isGroup) {
          name = conv['name'] as String? ?? 'Groupe';
          // Récupère le nombre de participants pour les groupes
          final memberRows = await SupabaseFetchers.selectAll(
            'conversation_participants',
            columns: 'member_id',
            eq: {'conversation_id': convId},
          );
          memberCount = memberRows.length;
        } else {
          // Pour les directs, trouver l'autre participant
          final otherMember = await findOtherParticipant(convId, currentMemberId);
          name = otherMember?.name ?? 'Discussion';
          avatarUrl = otherMember?.avatarUrl;
        }

        // Non lus
        int unread = 0;
        final lastReadAtStr = lastReadByConv[convId];
        if (lastReadAtStr != null && lastMessageAt != null) {
          final readDt = DateTime.tryParse(lastReadAtStr);
          if (readDt != null && lastMessageAt.isAfter(readDt)) {
            unread = 1; // Simplifié : on pourrait faire un COUNT SQL
          }
        }

        conversations.add(_ConversationWithTime(
          conversation: Conversation(
            id: convId,
            name: name,
            avatarUrl: avatarUrl,
            lastMessage: lastMessage,
            time: _formatTime(lastMessageAt),
            unread: unread,
            isRead: unread == 0,
            isGroup: isGroup,
            memberCount: memberCount,
          ),
          lastMessageAt: lastMessageAt ?? DateTime(2000),
        ));
      }

      // 4. Détecte les appels actifs dans ces conversations (batch)
      final activeCallConvIds = await _fetchActiveCallConversationIds(
        conversationIds,
        currentMemberId,
      );

      // Met à jour les conversations avec le flag isCallActive
      final updated = conversations.map((c) {
        final active = activeCallConvIds[c.conversation.id];
        return _ConversationWithTime(
          conversation: Conversation(
            id: c.conversation.id,
            name: c.conversation.name,
            avatarUrl: c.conversation.avatarUrl,
            lastMessage: c.conversation.lastMessage,
            time: c.conversation.time,
            unread: c.conversation.unread,
            isRead: c.conversation.isRead,
            isGroup: c.conversation.isGroup,
            memberCount: c.conversation.memberCount,
            isCallActive: active != null,
            isGroupCall: active ?? false,
          ),
          lastMessageAt: c.lastMessageAt,
        );
      }).toList();

      // Trie par date du dernier message (décroissant)
      updated.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

      return updated.map((c) => c.conversation).toList(growable: false);
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger les messages.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Récupère tous les participants d'une conversation (groupe ou directe).
  Future<List<Member>> getAllParticipants(String conversationId) async {
    final rows = await SupabaseFetchers.selectAll(
      'conversation_participants',
      columns: 'member_id',
      eq: {'conversation_id': conversationId},
    );

    final memberIds = rows
        .map((r) => r['member_id'] as String)
        .toList(growable: false);

    if (memberIds.isEmpty) return [];

    // Récupère les infos des membres en une seule requête (évite N+1)
    final response = await SupabaseFetchers.client
        .from('v_member_profiles')
        .select()
        .inFilter('id', memberIds);

    final data = (response as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);

    return data.map(Member.fromJson).toList(growable: false);
  }

  /// Trouve l'autre participant d'une conversation directe.
  Future<Member?> findOtherParticipant(
      String conversationId, String currentMemberId) async {
    final rows = await SupabaseFetchers.selectAll(
      'conversation_participants',
      columns: 'member_id',
      eq: {'conversation_id': conversationId},
    );

    final otherId = rows
        .map((r) => r['member_id'] as String)
        .where((id) => id != currentMemberId)
        .firstOrNull;

    if (otherId == null) return null;

    // Récupère les infos du membre
    // otherId = members.id, donc on filtre par 'id' sur v_member_profiles
    final memberRows = await SupabaseFetchers.selectAll(
      'v_member_profiles',
      limit: 1,
      eq: {'id': otherId},
    );

    if (memberRows.isEmpty) return null;
    return Member.fromJson(memberRows.first);
  }

  /// Retourne un map `conversation_id → isGroupCall` pour les conversations
  /// qui ont un appel actif en cours.
  ///
  /// Interroge `call_invites` (1-to-1, status='accepted') et `group_calls`
  /// (groupe, status='active') en parallèle.
  Future<Map<String, bool>> _fetchActiveCallConversationIds(
    List<String> conversationIds,
    String currentMemberId,
  ) async {
    if (conversationIds.isEmpty) return {};

    final result = <String, bool>{};

    try {
      // Requêtes en parallèle
      final results = await Future.wait([
        // 1-to-1 : call_invites avec status = 'accepted'
        SupabaseFetchers.client
            .from('call_invites')
            .select('conversation_id')
            .inFilter('conversation_id', conversationIds)
            .eq('status', 'accepted')
            .or('caller_id.eq.$currentMemberId,callee_id.eq.$currentMemberId'),
        // Groupe : group_calls avec status = 'active'
        SupabaseFetchers.client
            .from('group_calls')
            .select('conversation_id')
            .inFilter('conversation_id', conversationIds)
            .eq('status', 'active'),
      ]);

      // 1-to-1 calls
      for (final row in (results[0] as List<dynamic>)) {
        final map = row as Map<String, dynamic>;
        final convId = map['conversation_id'] as String?;
        if (convId != null) {
          result[convId] = false; // false = appel 1-to-1 (pas groupe)
        }
      }

      // Group calls
      for (final row in (results[1] as List<dynamic>)) {
        final map = row as Map<String, dynamic>;
        final convId = map['conversation_id'] as String?;
        if (convId != null) {
          result[convId] = true; // true = appel de groupe
        }
      }
    } catch (e) {
      // Silencieux : l'absence de détection n'est pas bloquante.
      debugPrint('[ConversationsRepository] Erreur détection appels actifs: $e');
    }

    return result;
  }

  /// Génère un aperçu humain pour le dernier message dans la liste
  /// de conversations, selon le type de contenu (texte, audio, image, etc.).
  String _previewForMessage(String content, Map<String, dynamic>? metadata) {
    final msgType = metadata?['msg_type'] as String?;
    switch (msgType) {
      case 'audio':
        return '🎤 ${metadata?['duration'] as String? ?? 'Message vocal'}';
      case 'image':
        return '📷 Photo';
      case 'video':
        return '📹 Vidéo';
      case 'file':
        final fileName = metadata?['file_name'] as String? ?? 'Document';
        return '📄 $fileName';
      case 'post_share':
        return '📢 Post partagé';
      case 'call':
        final callStatus = metadata?['call_status'] as String? ?? 'ended';
        final callType = metadata?['call_type'] as String? ?? 'audio';
        final isGroup = metadata?['is_group'] == true;
        final emoji = callType == 'video' ? '📹' : '📞';
        switch (callStatus) {
          case 'ended':
            final dur = metadata?['duration'] as String?;
            return '$emoji Appel${isGroup ? ' de groupe' : ''} terminé${dur != null ? ' · $dur' : ''}';
          case 'rejected':
            return '$emoji Appel refusé';
          case 'cancelled':
            return '$emoji Appel manqué';
          case 'missed':
            return '$emoji Appel manqué';
          default:
            return '$emoji Appel';
        }
      default:
        return content;
    }
  }

  /// Formate un DateTime en temps relatif (même logique que les posts).
  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return "à l'instant";
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) {
      const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      return days[dt.weekday - 1];
    }
    return '${dt.day}/${dt.month}';
  }

  /// Récupère les messages d'une conversation, du plus ancien au plus récent.
  ///
  /// Utilise un embed PostgREST `sender:sender_id(name, avatar_url)` pour
  /// hydrater le nom et l'avatar de l'expéditeur (nécessaire pour les bulles
  /// de messages enrichis : audio, vidéo, fichier, post partagé).
  Future<List<ChatMessage>> fetchMessages(String conversationId) async {
    try {
      final response = await SupabaseFetchers.client
          .from('messages')
          .select('*, metadata, sender:sender_id(full_name, avatar_url)')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      final data = (response as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);

      return data.map(ChatMessage.fromJson).toList(growable: false);
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger les messages.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Trouve ou crée une conversation directe avec un autre membre.
  ///
  /// Vérifie d'abord si une conversation directe existe déjà entre
  /// l'utilisateur courant et [otherMemberId]. Si oui, retourne la
  /// conversation existante. Sinon, en crée une nouvelle avec les
  /// deux participants et retourne la conversation fraîchement créée.
  ///
  /// Lance [AuthException] si l'utilisateur n'est pas connecté ou si
  /// son profil membre est introuvable.
  Future<Conversation> findOrCreateDirectConversation(
      String otherMemberId) async {
    final authUser = SupabaseFetchers.client.auth.currentUser;
    if (authUser == null) {
      throw const AuthException('Vous devez être connecté pour envoyer un message.');
    }

    try {
      // 1. Résout l'ID membre de l'utilisateur courant
      final currentMemberRows = await SupabaseFetchers.selectAll(
        'members',
        columns: 'id',
        limit: 1,
        eq: {'user_id': authUser.id},
      );
      if (currentMemberRows.isEmpty) {
        throw const AuthException('Profil membre introuvable.');
      }
      final currentMemberId = currentMemberRows.first['id'] as String;

      // 2. Cherche les conversations où les deux membres sont participants
      final myConvRows = await SupabaseFetchers.selectAll(
        'conversation_participants',
        columns: 'conversation_id',
        eq: {'member_id': currentMemberId},
      );

      if (myConvRows.isNotEmpty) {
        final myConvIds = myConvRows
            .map((r) => r['conversation_id'] as String)
            .toList(growable: false);

        // Vérifie si l'autre membre participe à une de ces conversations
        final otherCpRows = await SupabaseFetchers.selectAll(
          'conversation_participants',
          columns: 'conversation_id',
          eq: {'member_id': otherMemberId},
        );

        final otherConvIds = otherCpRows
            .map((r) => r['conversation_id'] as String)
            .toSet();

        // Intersection : conversations communes
        final commonId = myConvIds.firstWhere(
          (id) => otherConvIds.contains(id),
          orElse: () => '',
        );

        if (commonId.isNotEmpty) {
          // Conversation existante trouvée
          final otherMember =
              await findOtherParticipant(commonId, currentMemberId);
          return Conversation(
            id: commonId,
            name: otherMember?.name ?? 'Discussion',
            avatarUrl: otherMember?.avatarUrl,
            lastMessage: '',
            time: '',
            isRead: true,
            isGroup: false,
          );
        }
      }

      // 3. Aucune conversation existante → en créer une nouvelle
      final otherMemberRows = await SupabaseFetchers.selectAll(
        'v_member_profiles',
        limit: 1,
        eq: {'id': otherMemberId},
      );

      final otherName =
          otherMemberRows.isNotEmpty
              ? (otherMemberRows.first['name'] as String? ?? 'Membre')
              : 'Membre';
      final otherAvatar =
          otherMemberRows.isNotEmpty
              ? (otherMemberRows.first['avatar_url'] as String?)
              : null;

      final result = await SupabaseFetchers.client
          .from('conversations')
          .insert({'type': 'direct', 'name': ''})
          .select('id')
          .single();

      final newConvId = result['id'] as String;

      // Ajoute les deux participants
      await SupabaseFetchers.client.from('conversation_participants').insert([
        {'conversation_id': newConvId, 'member_id': currentMemberId},
        {'conversation_id': newConvId, 'member_id': otherMemberId},
      ]);

      return Conversation(
        id: newConvId,
        name: otherName,
        avatarUrl: otherAvatar,
        lastMessage: '',
        time: '',
        isRead: true,
        isGroup: false,
      );
    } on AppException {
      rethrow;
    } catch (e, st) {
      log.error(
        'findOrCreateDirectConversation a échoué',
        tag: 'ConversationsRepository',
        error: e,
        stackTrace: st,
      );
      throw ServerException(
        "Impossible de démarrer la conversation.",
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Envoie un message dans une conversation.
  ///
  /// [metadata] est optionnel — utilisé pour les messages spéciaux
  /// comme les partages de post (`msg_type: 'post_share'`).
  Future<void> sendMessage({
    required String conversationId,
    required String senderMemberId,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final payload = <String, dynamic>{
        'conversation_id': conversationId,
        'sender_id': senderMemberId,
        'content': content,
      };
      if (metadata != null && metadata.isNotEmpty) {
        payload['metadata'] = metadata;
      }
      await SupabaseFetchers.client.from('messages').insert(payload);
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        "Impossible d'envoyer le message.",
        cause: e,
        stackTrace: st,
      );
    }
  }
}

/// Paire conversation + DateTime pour le tri (non exposée publiquement).
class _ConversationWithTime {
  final Conversation conversation;
  final DateTime lastMessageAt;

  const _ConversationWithTime({
    required this.conversation,
    required this.lastMessageAt,
  });
}
