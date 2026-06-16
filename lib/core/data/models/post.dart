/// Modèles Post, Announcement et PostComment (utilisés par le Home Feed).
///
/// Source de vérité : tables Supabase `posts`, `announcements` et `post_comments`.
library;

import 'dart:convert';

import 'package:meta/meta.dart';

import '../parsers.dart';

/// Publication du fil d'actualité.
@immutable
class Post {
  const Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorCity,
    required this.authorCountry,
    this.authorAvatarUrl,
    required this.content,
    this.imageUrl,
    required this.likesCount,
    required this.commentsCount,
    required this.timeAgo,
    this.isLiked = false,
    this.isBookmarked = false,
    this.sharesCount = 0,
    this.firstLikerName,
    this.eventId,
    this.createdAt,
    this.repostOf,
    this.repostOriginal,
    this.isReposted = false,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String authorCity;
  final String authorCountry;
  final String? authorAvatarUrl;
  final String content;
  final String? imageUrl;

  /// URLs des images du post (carrousel). Parse un tableau JSON stocke dans
  /// le champ `image_url` de la DB, ou retourne une liste a un element
  /// si c'est une URL simple (retrocompatibilite).
  List<String> get imageUrls {
    if (imageUrl == null || imageUrl!.isEmpty) return const [];
    if (imageUrl!.startsWith('[')) {
      try {
        final parsed = jsonDecode(imageUrl!) as List<dynamic>;
        return parsed.map((e) => e.toString()).toList();
      } catch (_) {
        return [imageUrl!];
      }
    }
    return [imageUrl!];
  }
  final int likesCount;
  final int commentsCount;
  final String timeAgo;
  final bool isLiked;

  /// Indique si l'utilisateur courant a mis ce post en favori.
  final bool isBookmarked;

  /// Nombre de partages de ce post.
  final int sharesCount;

  /// Nom de la première personne ayant liké ce post (pour le preview social).
  /// `null` si personne n'a liké ou si la donnée n'est pas disponible.
  final String? firstLikerName;

  /// ID de l'événement lié à ce post (si partagé depuis le module Événements).
  /// `null` pour les posts classiques.
  final String? eventId;

  /// Date de création du post (utile pour calculer `timeAgo` côté client).
  final DateTime? createdAt;

  /// ID du post original si ce post est un repost (null sinon).
  final String? repostOf;

  /// Post original chargé pour l'embed visuel (null si ce n'est pas un repost
  /// ou si le post original n'a pas encore été chargé).
  final Post? repostOriginal;

  /// Indique si l'utilisateur courant a reposté ce post.
  final bool isReposted;

  factory Post.fromJson(Map<String, dynamic> json) {
    // author peut être un objet joint (via `author(*)`) ou aplati.
    final authorObj = json['author'] is Map<String, dynamic>
        ? json['author'] as Map<String, dynamic>
        : null;

    // Post original embed (si présent dans la réponse, ex. jointure repost).
    final repostOriginalJson = json['repost_original'] is Map<String, dynamic>
        ? json['repost_original'] as Map<String, dynamic>
        : null;

    return Post(
      id: Parsers.string(json, 'id', fallback: Parsers.string(json, 'post_id')),
      authorId: Parsers.string(json, 'author_id', fallback: Parsers.string(json, 'authorId')),
      authorName: authorObj != null
          ? Parsers.string(authorObj, 'name', fallback: Parsers.string(authorObj, 'full_name'))
          : Parsers.string(json, 'author_name', fallback: Parsers.string(json, 'authorName')),
      authorCity: authorObj != null
          ? Parsers.string(authorObj, 'city')
          : Parsers.string(json, 'author_city', fallback: Parsers.string(json, 'authorCity')),
      authorCountry: authorObj != null
          ? Parsers.string(authorObj, 'country')
          : Parsers.string(json, 'author_country', fallback: Parsers.string(json, 'authorCountry')),
      authorAvatarUrl: Parsers.nullableString(json, 'author_avatar_url') ??
          Parsers.nullableString(json, 'authorAvatarUrl') ??
          (authorObj != null
              ? Parsers.nullableString(authorObj, 'avatar_url') ??
                  Parsers.nullableString(authorObj, 'avatarUrl')
              : null),
      content: Parsers.string(json, 'content'),
      imageUrl: Parsers.nullableString(json, 'image_url') ??
          Parsers.nullableString(json, 'imageUrl'),
      likesCount: Parsers.integer(json, 'likes_count', fallback: Parsers.integer(json, 'likesCount')),
      commentsCount: Parsers.integer(json, 'comments_count', fallback: Parsers.integer(json, 'commentsCount')),
      sharesCount: Parsers.integer(json, 'shares_count', fallback: Parsers.integer(json, 'sharesCount')),
      timeAgo: _computeTimeAgo(
        Parsers.string(json, 'time_ago', fallback: Parsers.string(json, 'timeAgo')),
        Parsers.nullableDateTime(json, 'created_at') ?? Parsers.nullableDateTime(json, 'createdAt'),
      ),
      eventId: Parsers.nullableString(json, 'event_id') ?? Parsers.nullableString(json, 'eventId'),
      createdAt: Parsers.nullableDateTime(json, 'created_at') ?? Parsers.nullableDateTime(json, 'createdAt'),
      repostOf: Parsers.nullableString(json, 'repost_of') ?? Parsers.nullableString(json, 'repostOf'),
      repostOriginal: repostOriginalJson != null ? Post.fromJson(repostOriginalJson) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'author_id': authorId,
        'content': content,
        'image_url': imageUrl,
        'likes_count': likesCount,
        'comments_count': commentsCount,
        'time_ago': timeAgo,
        if (eventId != null) 'event_id': eventId,
      };

  Post copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorCity,
    String? authorCountry,
    String? authorAvatarUrl,
    String? content,
    String? imageUrl,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    String? timeAgo,
    bool? isLiked,
    bool? isBookmarked,
    String? firstLikerName,
    String? eventId,
    DateTime? createdAt,
    String? repostOf,
    Post? repostOriginal,
    bool? isReposted,
  }) {
    return Post(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorCity: authorCity ?? this.authorCity,
      authorCountry: authorCountry ?? this.authorCountry,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      timeAgo: timeAgo ?? this.timeAgo,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      firstLikerName: firstLikerName ?? this.firstLikerName,
      eventId: eventId ?? this.eventId,
      createdAt: createdAt ?? this.createdAt,
      repostOf: repostOf ?? this.repostOf,
      repostOriginal: repostOriginal ?? this.repostOriginal,
      isReposted: isReposted ?? this.isReposted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Post &&
          other.id == id &&
          other.authorId == authorId &&
          other.authorName == authorName &&
          other.content == content &&
          other.imageUrl == imageUrl &&
          other.likesCount == likesCount &&
          other.commentsCount == commentsCount &&
          other.sharesCount == sharesCount &&
          other.isLiked == isLiked &&
          other.isBookmarked == isBookmarked &&
          other.isReposted == isReposted &&
          other.firstLikerName == firstLikerName &&
          other.eventId == eventId &&
          other.createdAt == createdAt &&
          other.repostOf == repostOf;

  @override
  int get hashCode => Object.hash(
        id,
        authorId,
        authorName,
        content,
        imageUrl,
        likesCount,
        commentsCount,
        sharesCount,
        isLiked,
        isBookmarked,
        isReposted,
        firstLikerName,
        eventId,
        createdAt,
        repostOf,
      );
  /// Calcule le temps relatif a afficher a partir de [createdAt].
  /// Si [createdAt] est disponible, il prime toujours sur la valeur
  /// stockee [storedTimeAgo] (qui peut etre perimee comme "a l'instant").
  static String _computeTimeAgo(String storedTimeAgo, DateTime? createdAt) {
    if (createdAt == null) return storedTimeAgo;

    final now = DateTime.now().toUtc();
    final diff = now.difference(createdAt);

    if (diff.inSeconds < 60) return "a l'instant";
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'hier';
    if (diff.inDays < 7) return 'il y a ${diff.inDays}j';
    if (diff.inDays < 30) return 'il y a ${(diff.inDays / 7).floor()} sem.';
    if (diff.inDays < 365) return 'il y a ${(diff.inDays / 30).floor()} mois';
    return 'il y a ${(diff.inDays / 365).floor()} an${(diff.inDays / 365).floor() > 1 ? 's' : ''}';
  }
}

/// Annonce communautaire (en-tete du feed).
@immutable
class Announcement {
  const Announcement({
    required this.id,
    required this.chipLabel,
    required this.chipIcon,
    required this.title,
    required this.description,
    required this.ctaLabel,
  });

  final String id;
  final String chipLabel;
  final String chipIcon;
  final String title;
  final String description;
  final String ctaLabel;

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: Parsers.string(json, 'id'),
      chipLabel: Parsers.string(json, 'chip_label', fallback: Parsers.string(json, 'chipLabel')),
      chipIcon: Parsers.string(json, 'chip_icon', fallback: Parsers.string(json, 'chipIcon')),
      title: Parsers.string(json, 'title'),
      description: Parsers.string(json, 'description'),
      ctaLabel: Parsers.string(json, 'cta_label', fallback: Parsers.string(json, 'ctaLabel')),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'chip_label': chipLabel,
        'chip_icon': chipIcon,
        'title': title,
        'description': description,
        'cta_label': ctaLabel,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Announcement &&
          other.id == id &&
          other.title == title &&
          other.chipLabel == chipLabel;

  @override
  int get hashCode => Object.hash(id, title, chipLabel);
}

/// Commentaire sur un post du fil d'actualité.
///
/// Source de vérité : vue Supabase `v_post_comments` (flat join avec author).
@immutable
class PostComment {
  const PostComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.content,
    required this.createdAt,
    required this.authorName,
    this.authorAvatarUrl,
    required this.authorInitials,
    this.parentCommentId,
    this.likesCount = 0,
    this.isLiked = false,
  });

  final String id;
  final String postId;
  final String authorId;
  final String content;
  final DateTime createdAt;
  final String authorName;
  final String? authorAvatarUrl;
  final String authorInitials;

  /// ID du commentaire parent (null = commentaire racine, non-null = réponse).
  final String? parentCommentId;

  /// Nombre de likes, maintenu par le trigger `tg_comment_like_count`.
  final int likesCount;

  /// Indique si l'utilisateur courant a liké ce commentaire.
  final bool isLiked;

  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      id: Parsers.string(json, 'id'),
      postId: Parsers.string(json, 'post_id', fallback: Parsers.string(json, 'postId')),
      authorId: Parsers.string(json, 'author_id', fallback: Parsers.string(json, 'authorId')),
      content: Parsers.string(json, 'content'),
      createdAt: Parsers.nullableDateTime(json, 'created_at') ??
          Parsers.nullableDateTime(json, 'createdAt') ??
          DateTime.now(),
      authorName: Parsers.string(json, 'author_name', fallback: Parsers.string(json, 'authorName')),
      authorAvatarUrl: Parsers.nullableString(json, 'author_avatar_url') ??
          Parsers.nullableString(json, 'authorAvatarUrl'),
      authorInitials: Parsers.string(json, 'author_initials', fallback: Parsers.string(json, 'authorInitials')),
      parentCommentId: Parsers.nullableString(json, 'parent_comment_id') ??
          Parsers.nullableString(json, 'parentCommentId'),
      likesCount: Parsers.integer(json, 'likes_count', fallback: Parsers.integer(json, 'likesCount')),
    );
  }

  PostComment copyWith({bool? isLiked}) {
    return PostComment(
      id: id,
      postId: postId,
      authorId: authorId,
      content: content,
      createdAt: createdAt,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      authorInitials: authorInitials,
      parentCommentId: parentCommentId,
      likesCount: likesCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostComment &&
          other.id == id &&
          other.content == content &&
          other.isLiked == isLiked;

  @override
  int get hashCode => Object.hash(id, content, isLiked);
}
