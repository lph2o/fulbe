/// Modèle de conversation (messagerie directe et groupes).
///
/// Source de vérité : tables Supabase `conversations`, `conversation_participants`,
/// et `messages`.
library;

import 'package:meta/meta.dart';

import '../parsers.dart';

/// Conversation (directe ou de groupe) affichée dans la liste de messages.
@immutable
class Conversation {
  const Conversation({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.lastMessage,
    required this.time,
    this.unread = 0,
    this.isRead = true,
    this.isGroup = false,
    this.isCallActive = false,
    this.isGroupCall = false,
    this.memberCount = 0,
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final String lastMessage;
  final String time;
  final int unread;
  final bool isRead;
  final bool isGroup;

  /// Indique si un appel est actuellement en cours dans cette conversation.
  final bool isCallActive;

  /// Si [isCallActive], précise s'il s'agit d'un appel de groupe.
  final bool isGroupCall;

  /// Nombre de participants (utile pour l'affichage des groupes).
  final int memberCount;

  /// Construit une [Conversation] depuis le résultat d'une requête Supabase
  /// qui joint les tables conversations + participants + messages.
  ///
  /// Attend les colonnes :
  ///   - id, type, name (conversations)
  ///   - last_message, last_message_at, last_sender_name (dénormalisés)
  ///   - unread_count, avatar_url (calculés ou joints)
  factory Conversation.fromJson(Map<String, dynamic> json) {
    final isGroup = Parsers.string(json, 'type') == 'group';

    return Conversation(
      id: Parsers.string(json, 'id'),
      name: Parsers.string(json, 'name',
          fallback: Parsers.string(json, 'display_name', fallback: 'Discussion')),
      avatarUrl: Parsers.nullableString(json, 'avatar_url') ??
          Parsers.nullableString(json, 'avatarUrl'),
      lastMessage: Parsers.string(json, 'last_message',
          fallback: Parsers.string(json, 'lastMessage')),
      time: Parsers.string(json, 'last_message_at',
          fallback: Parsers.string(json, 'time')),
      unread: Parsers.integer(json, 'unread_count',
          fallback: Parsers.integer(json, 'unread')),
      isRead: Parsers.boolean(json, 'is_read', fallback: Parsers.boolean(json, 'isRead')),
      isGroup: isGroup,
      isCallActive: Parsers.boolean(json, 'is_call_active',
          fallback: Parsers.boolean(json, 'isCallActive')),
      isGroupCall: Parsers.boolean(json, 'is_group_call',
          fallback: Parsers.boolean(json, 'isGroupCall')),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Conversation && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

/// Message dans une conversation.
@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.createdAt,
    this.senderAvatarUrl,
    this.isMine = false,
    this.metadata,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime createdAt;
  final String? senderAvatarUrl;
  final bool isMine;

  /// Métadonnées optionnelles (ex: {"msg_type": "post_share", "post_id": "..."}).
  final Map<String, dynamic>? metadata;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Le nom et l'avatar peuvent venir :
    //   (A) de colonnes dénormalisées dans `messages` (sender_name, sender_avatar_url)
    //   (B) d'un embed PostgREST `sender:sender_id(name,avatar_url)`
    final sender = json['sender'] as Map<String, dynamic>?;
    final rawName =
        json['sender_name'] as String? ?? json['senderName'] as String?;
    final senderName = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : (sender?['full_name'] as String? ?? sender?['name'] as String?) ?? 'Membre';

    return ChatMessage(
      id: Parsers.string(json, 'id'),
      conversationId: Parsers.string(json, 'conversation_id',
          fallback: Parsers.string(json, 'conversationId')),
      senderId: Parsers.string(json, 'sender_id',
          fallback: Parsers.string(json, 'senderId')),
      senderName: senderName,
      content: Parsers.string(json, 'content'),
      createdAt: Parsers.nullableDateTime(json, 'created_at') ??
          Parsers.nullableDateTime(json, 'createdAt') ??
          DateTime.now(),
      senderAvatarUrl: Parsers.nullableString(json, 'sender_avatar_url') ??
          Parsers.nullableString(json, 'senderAvatarUrl') ??
          sender?['avatar_url'] as String?,
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata'] as Map<String, dynamic>
          : null,
    );
  }

  ChatMessage copyWith({bool? isMine, Map<String, dynamic>? metadata}) {
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      createdAt: createdAt,
      senderAvatarUrl: senderAvatarUrl,
      isMine: isMine ?? this.isMine,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          other.id == id &&
          other.content == content &&
          other.isMine == isMine;

  @override
  int get hashCode => Object.hash(id, content, isMine);
}
