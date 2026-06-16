/// Modèle de publication dans le feed d'un groupe/communauté.
///
/// Source de vérité : table Supabase `community_posts`.
library;

import 'package:meta/meta.dart';

import '../parsers.dart';

/// Publication dans le feed d'un groupe.
@immutable
class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.communityId,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    this.isMine = false,
  });

  final String id;
  final String communityId;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;

  /// Hydraté côté client : le post est-il de l'utilisateur courant ?
  final bool isMine;

  factory CommunityPost.fromJson(Map<String, dynamic> json,
      {bool? isMine, String? currentMemberId}) {
    // Support d'un embed PostgREST `author:author_id(full_name, avatar_url)`
    final author = json['author'] as Map<String, dynamic>?;
    final rawName = json['author_name'] as String?;
    final authorName = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : (author?['full_name'] as String? ??
            author?['name'] as String? ??
            'Membre');

    final authorId = Parsers.string(json, 'author_id',
        fallback: Parsers.string(json, 'authorId'));

    return CommunityPost(
      id: Parsers.string(json, 'id'),
      communityId: Parsers.string(json, 'community_id',
          fallback: Parsers.string(json, 'communityId')),
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl: Parsers.nullableString(json, 'author_avatar_url') ??
          Parsers.nullableString(json, 'authorAvatarUrl') ??
          author?['avatar_url'] as String?,
      content: Parsers.string(json, 'content'),
      imageUrl: Parsers.nullableString(json, 'image_url') ??
          Parsers.nullableString(json, 'imageUrl'),
      createdAt: Parsers.nullableDateTime(json, 'created_at') ??
          Parsers.nullableDateTime(json, 'createdAt') ??
          DateTime.now(),
      isMine: isMine ?? (currentMemberId != null && authorId == currentMemberId),
    );
  }

  CommunityPost copyWith({bool? isMine}) {
    return CommunityPost(
      id: id,
      communityId: communityId,
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      content: content,
      imageUrl: imageUrl,
      createdAt: createdAt,
      isMine: isMine ?? this.isMine,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommunityPost &&
          other.id == id &&
          other.content == content;

  @override
  int get hashCode => Object.hash(id, content);
}
