/// Modèle de groupe/communauté.
///
/// Source de vérité : table Supabase `communities`.
library;

import 'package:meta/meta.dart';

import '../parsers.dart';

/// Groupe/communauté libre, avec feed, membres et rôles.
@immutable
class Community {
  const Community({
    required this.id,
    required this.name,
    this.description = '',
    this.coverUrl,
    required this.category,
    this.visibility = 'public',
    this.memberCount = 0,
    required this.createdBy,
    this.organizationId,
    this.chapterId,
    required this.createdAt,
    this.isMember = false,
    this.isAdmin = false,
    this.conversationId,
  });

  final String id;
  final String name;
  final String description;
  final String? coverUrl;
  final String category;
  final String visibility; // 'public' | 'private'
  final int memberCount;
  final String createdBy;
  final String? organizationId;
  final String? chapterId;
  final DateTime createdAt;

  /// Hydraté côté client : l'utilisateur courant est-il membre ?
  final bool isMember;

  /// Hydraté côté client : l'utilisateur courant est-il admin/modérateur ?
  final bool isAdmin;

  /// ID de la conversation associée pour le chat instantané (nullable).
  final String? conversationId;

  bool get isPublic => visibility == 'public';
  bool get isPrivate => visibility == 'private';

  factory Community.fromJson(Map<String, dynamic> json,
      {bool? isMember, bool? isAdmin}) {
    return Community(
      id: Parsers.string(json, 'id'),
      name: Parsers.string(json, 'name'),
      description: Parsers.string(json, 'description', fallback: ''),
      coverUrl: Parsers.nullableString(json, 'cover_url') ??
          Parsers.nullableString(json, 'coverUrl'),
      category: Parsers.string(json, 'category'),
      visibility: Parsers.string(json, 'visibility', fallback: 'public'),
      memberCount: Parsers.integer(json, 'member_count',
          fallback: Parsers.integer(json, 'memberCount', fallback: 0)),
      createdBy: Parsers.string(json, 'created_by',
          fallback: Parsers.string(json, 'createdBy')),
      organizationId: Parsers.nullableString(json, 'organization_id') ??
          Parsers.nullableString(json, 'organizationId'),
      chapterId: Parsers.nullableString(json, 'chapter_id') ??
          Parsers.nullableString(json, 'chapterId'),
      createdAt: Parsers.nullableDateTime(json, 'created_at') ??
          Parsers.nullableDateTime(json, 'createdAt') ??
          DateTime.now(),
      isMember: isMember ?? false,
      isAdmin: isAdmin ?? false,
      conversationId: Parsers.nullableString(json, 'conversation_id') ??
          Parsers.nullableString(json, 'conversationId'),
    );
  }

  Community copyWith({
    String? name,
    String? description,
    String? coverUrl,
    String? category,
    String? visibility,
    int? memberCount,
    bool? isMember,
    bool? isAdmin,
    String? conversationId,
  }) {
    return Community(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      category: category ?? this.category,
      visibility: visibility ?? this.visibility,
      memberCount: memberCount ?? this.memberCount,
      createdBy: createdBy,
      organizationId: organizationId,
      chapterId: chapterId,
      createdAt: createdAt,
      isMember: isMember ?? this.isMember,
      isAdmin: isAdmin ?? this.isAdmin,
      conversationId: conversationId ?? this.conversationId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Community && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}
