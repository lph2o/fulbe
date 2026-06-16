import 'dart:convert';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../errors/app_exception.dart';
import '../models/post.dart';
import '../supabase_fetchers.dart';

/// Repository d'accès au fil d'actualité (posts), aux annonces communautaires
/// et aux commentaires.
class PostsRepository {
  const PostsRepository();

  /// Récupère les posts récents, triés du plus récent au plus ancien.
  ///
  /// Utilise un embed `author(*)` si supporté par PostgREST (côté seed, les
  /// colonnes author_* sont aussi aplaties pour la rétrocompatibilité).
  Future<List<Post>> fetchPosts() async {
    try {
      final rows = await SupabaseFetchers.selectAll(
        'v_home_feed',
        orderBy: 'created_at',
        ascending: false,
      );
      return rows.map(Post.fromJson).toList(growable: false);
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger le fil d\'actualité.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Récupère les posts d'un membre spécifique (pour l'écran de profil).
  Future<List<Post>> fetchPostsByMember(String memberId) async {
    try {
      final rows = await SupabaseFetchers.selectAll(
        'v_home_feed',
        eq: {'author_id': memberId},
        orderBy: 'created_at',
        ascending: false,
      );
      return rows.map(Post.fromJson).toList(growable: false);
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger les publications du membre.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Récupère les posts des membres d'un chapitre.
  ///
  /// Fait un join indirect via `members.chapter_id`.
  Future<List<Post>> fetchPostsByChapter(String chapterId) async {
    try {
      // Étape 1 : récupère les member_ids du chapitre
      final memberRows = await SupabaseFetchers.selectAll(
        'members',
        columns: 'id',
        eq: {'chapter_id': chapterId},
      );
      if (memberRows.isEmpty) return [];
      final memberIds = memberRows.map((r) => r['id'] as String).toList();

      // Étape 2 : récupère les posts de ces membres via v_home_feed
      final conditions =
          memberIds.map((id) => 'author_id.eq.$id').join(',');
      final data = await SupabaseFetchers.client
          .from('v_home_feed')
          .select('*')
          .or(conditions)
          .order('created_at', ascending: false)
          .limit(50);

      final rows = (data as List<dynamic>).cast<Map<String, dynamic>>();
      return rows.map(Post.fromJson).toList(growable: false);
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger les publications du chapitre.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Crée un nouveau post sur le fil d'actualité.
  ///
  /// [authorMemberId] est l'UUID du membre dans `public.members`.
  /// [imageFiles] est optionnel — si fourni, chaque fichier est uploadé vers
  /// Supabase Storage (bucket `post-images`) et les URLs publiques sont
  /// stockées en JSON array dans le champ `image_url`.
  ///
  /// [eventId] est optionnel — si fourni, le post est lié à un événement
  /// et affichera une carte de prévisualisation dans le feed.
  Future<Post> createPost({
    required String authorMemberId,
    required String content,
    List<File>? imageFiles,
    String? eventId,
  }) async {
    final List<String> uploadedUrls = [];

    // ── Upload images (si fournies) ────────────────────────────
    if (imageFiles != null && imageFiles.isNotEmpty) {
      for (var i = 0; i < imageFiles.length; i++) {
        try {
          final file = imageFiles[i];
          final ext = file.uri.pathSegments.last.contains('.')
              ? file.uri.pathSegments.last.split('.').last
              : 'jpg';
          final fileName =
              '${DateTime.now().microsecondsSinceEpoch}_$i.$ext';
          await SupabaseFetchers.client.storage
              .from('post-images')
              .upload(fileName, file);

          final url = SupabaseFetchers.client.storage
              .from('post-images')
              .getPublicUrl(fileName);
          uploadedUrls.add(url);
        } catch (e) {
          // Une erreur d'upload → on abandonne l'image
          // mais on continue pour poster au moins le texte
        }
      }

      // Si aucune image n'a pu être uploadée, on prévient l'utilisateur
      if (uploadedUrls.isEmpty && imageFiles.isNotEmpty) {
        throw const ServerException(
          'Impossible de télécharger les images. Vérifiez que le bucket '
          '« post-images » existe dans Supabase Storage.',
        );
      }
    }

    // ── Insérer le post ──────────────────────────────────
    try {
      final now = DateTime.now().toUtc();
      final imagePayload = uploadedUrls.isNotEmpty
          ? jsonEncode(uploadedUrls)
          : null;

      // Insert + récupère l'ID généré par Postgres (.select après insert)
      final inserted = await SupabaseFetchers.client
          .from('posts')
          .insert({
            'author_id': authorMemberId,
            'content': content,
            if (imagePayload != null) 'image_url': imagePayload,
            if (eventId != null) 'event_id': eventId,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .select('id');

      if (inserted.isNotEmpty) {
        final newId = inserted.first['id'] as String;

        // Recharge le post via la vue v_home_feed (jointure auteur)
        final rows = await SupabaseFetchers.selectAll(
          'v_home_feed',
          eq: {'id': newId},
          limit: 1,
        );
        if (rows.isNotEmpty) {
          return Post.fromJson(rows.first);
        }
      }
      throw const ServerException('Post créé mais impossible de le recharger.');
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de créer le post.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Récupère le nom du premier likeur pour chaque post dans [postIds].
  ///
  /// Utilise un embed PostgREST `members(name)` via la FK `user_id` → `members.id`.
  /// Si la jointure échoue (FK non déclarée, table absente), retourne une map
  /// vide sans planter — l'UI affichera un texte générique pour le preview social.
  Future<Map<String, String?>> fetchFirstLikerNames(List<String> postIds) async {
    if (postIds.isEmpty) return {};

    try {
      // PostgREST embed : user_id référence members.id, on utilise le hint de FK
      final conditions = postIds.map((id) => 'post_id.eq.$id').join(',');
      final data = await SupabaseFetchers.client
          .from('post_likes')
          .select('post_id, members(name)')
          .or(conditions)
          .order('created_at', ascending: true)
          .limit(postIds.length * 2); // safe upper bound

      final result = <String, String?>{};
      final seen = <String>{};
      for (final row in (data as List<dynamic>)) {
        final r = row as Map<String, dynamic>;
        final pid = r['post_id'] as String;
        if (seen.contains(pid)) continue;
        seen.add(pid);
        final members = r['members'] as Map<String, dynamic>?;
        result[pid] = members?['name'] as String?;
      }
      // Tous les posts sans like → null
      for (final pid in postIds) {
        result.putIfAbsent(pid, () => null);
      }
      return result;
    } catch (_) {
      // Silencieux : l'UI utilisera un fallback générique
      return {};
    }
  }

  /// Récupère les 2 commentaires les plus récents d'un post (aperçu dans la carte).
  Future<List<PostComment>> fetchCommentsPreview(String postId) async {
    try {
      final rows = await SupabaseFetchers.selectAll(
        'v_post_comments',
        eq: {'post_id': postId},
        orderBy: 'created_at',
        ascending: false,
        limit: 2,
      );
      // Remettre dans l'ordre chronologique pour l'affichage
      return rows.reversed
          .map(PostComment.fromJson)
          .toList(growable: false);
    } on AppException {
      rethrow;
    } on sb.PostgrestException catch (e) {
      if (e.code == '42P01') return [];
      throw ServerException(
        'Impossible de charger l\'aperçu des commentaires.',
        cause: e,
      );
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger l\'aperçu des commentaires.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Récupère le vrai nombre total de commentaires pour un post.
  ///
  /// Fait un COUNT exact sur `post_comments` plutôt que de se fier au
  /// champ `comments_count` de `v_home_feed` (qui peut être désynchronisé).
  Future<int> fetchCommentsCount(String postId) async {
    try {
      final data = await SupabaseFetchers.client
          .from('post_comments')
          .select()
          .eq('post_id', postId)
          .limit(0)
          .count(sb.CountOption.exact);
      return (data as dynamic).count as int? ?? 0;
    } on sb.PostgrestException catch (e) {
      if (e.code == '42P01') return 0;
      rethrow;
    } catch (_) {
      return 0;
    }
  }

  /// Récupère les annonces actives, triées par ordre d'affichage.
  Future<List<Announcement>> fetchAnnouncements() async {
    try {
      final rows = await SupabaseFetchers.selectAll(
        'announcements',
        eq: {'active': true},
        orderBy: 'created_at',
        ascending: false,
      );
      return rows.map(Announcement.fromJson).toList(growable: false);
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger les annonces.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Récupère les commentaires d'un post, du plus ancien au plus récent.
  ///
  /// Utilise la vue `v_post_comments` qui joint les infos auteur.
  ///
  /// Si la vue ou la table n'existe pas encore (migration non appliquée),
  /// retourne une liste vide au lieu de planter — l'UI affichera l'état
  /// "Soyez le premier à commenter !" plutôt qu'un message d'erreur.
  Future<List<PostComment>> fetchComments(String postId) async {
    try {
      final rows = await SupabaseFetchers.selectAll(
        'v_post_comments',
        eq: {'post_id': postId},
        orderBy: 'created_at',
        ascending: true,
      );
      return rows.map(PostComment.fromJson).toList(growable: false);
    } on AppException {
      rethrow;
    } on sb.PostgrestException catch (e) {
      // Erreur 42P01 = relation/table/view does not exist
      // La migration n'a pas encore été appliquée → on retourne une liste vide
      if (e.code == '42P01') return [];
      throw ServerException(
        'Impossible de charger les commentaires.',
        cause: e,
      );
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger les commentaires.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Ajoute un commentaire (ou une réponse) sur un post.
  ///
  /// [authorMemberId] est l'UUID du membre dans `public.members` (pas l'UID auth).
  /// [parentCommentId] est non-null pour une réponse à un commentaire existant.
  /// Ne retourne rien : l'UI invalide ensuite le provider pour re-fetcher
  /// depuis la vue `v_post_comments` qui contient les infos auteur.
  Future<void> addComment({
    required String postId,
    required String authorMemberId,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      await sb.Supabase.instance.client.from('post_comments').insert({
        'post_id': postId,
        'author_id': authorMemberId,
        'content': content,
        if (parentCommentId != null) 'parent_comment_id': parentCommentId,
      });
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible d\'ajouter le commentaire.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  // ── Update / Delete ─────────────────────────────────────────────────────────

  /// Met à jour le contenu (et optionnellement les images) d'un post existant.
  ///
  /// L'utilisateur doit être le propriétaire du post (vérifié par RLS côté serveur).
  Future<Post> updatePost({
    required String postId,
    required String content,
  }) async {
    try {
      final now = DateTime.now().toUtc();

      await SupabaseFetchers.client
          .from('posts')
          .update({
            'content': content,
            'updated_at': now.toIso8601String(),
          })
          .eq('id', postId);

      // Recharge le post mis à jour via la vue
      final rows = await SupabaseFetchers.selectAll(
        'v_home_feed',
        eq: {'id': postId},
        limit: 1,
      );
      if (rows.isNotEmpty) {
        return Post.fromJson(rows.first);
      }
      throw const ServerException('Post modifié mais impossible de le recharger.');
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de modifier le post.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Supprime un post.
  ///
  /// L'utilisateur doit être le propriétaire du post (vérifié par RLS côté serveur).
  Future<void> deletePost(String postId) async {
    try {
      await SupabaseFetchers.client
          .from('posts')
          .delete()
          .eq('id', postId);
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de supprimer le post.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  // ── Likes ─────────────────────────────────────────────────────────────────

  /// Récupère l'ensemble des IDs de posts que l'utilisateur courant a likés.
  ///
  /// Retourne un set vide si non authentifié.
  Future<Set<String>> fetchUserLikedPostIds() async {
    final authUser = SupabaseFetchers.client.auth.currentUser;
    if (authUser == null) return {};

    try {
      // Résout members.id à partir de authUser.id (auth.users)
      final memberRows = await SupabaseFetchers.selectAll(
        'members',
        columns: 'id',
        limit: 1,
        eq: {'user_id': authUser.id},
      );
      if (memberRows.isEmpty) return {};
      final memberId = memberRows.first['id'] as String;

      final rows = await SupabaseFetchers.selectAll(
        'post_likes',
        columns: 'post_id',
        eq: {'user_id': memberId},
      );

      return rows.map((r) => r['post_id'] as String).toSet();
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de vérifier vos likes.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Like ou unlike un post.
  ///
  /// [isLiking] : `true` pour ajouter un like, `false` pour retirer.
  /// Le trigger `tg_post_like_count` (migration 010) met automatiquement
  /// à jour `posts.likes_count`.
  Future<void> toggleLike({
    required String postId,
    required bool isLiking,
  }) async {
    final authUser = SupabaseFetchers.client.auth.currentUser;
    if (authUser == null) return;

    try {
      final memberRows = await SupabaseFetchers.selectAll(
        'members',
        columns: 'id',
        limit: 1,
        eq: {'user_id': authUser.id},
      );
      if (memberRows.isEmpty) return;
      final memberId = memberRows.first['id'] as String;

      if (isLiking) {
        await SupabaseFetchers.client
            .from('post_likes')
            .insert({'post_id': postId, 'user_id': memberId});
      } else {
        await SupabaseFetchers.client
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', memberId);
      }
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de modifier votre like.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  // ── Shares ─────────────────────────────────────────────────────────────────

  /// Enregistre un partage de post (une seule fois par membre).
  ///
  /// [shareType] : 'native' (OS share), 'dm' (message privé), 'repost' (fil)
  /// Le trigger `tg_post_share_count` met automatiquement a jour
  /// `posts.shares_count`.
  Future<void> recordShare(String postId, {String shareType = 'native'}) async {
    final authUser = SupabaseFetchers.client.auth.currentUser;
    if (authUser == null) return;

    try {
      final memberRows = await SupabaseFetchers.selectAll(
        'members',
        columns: 'id',
        limit: 1,
        eq: {'user_id': authUser.id},
      );
      if (memberRows.isEmpty) return;
      final memberId = memberRows.first['id'] as String;

      // INSERT avec ON CONFLICT DO NOTHING (contrainte UNIQUE)
      // pour eviter les doublons si l'utilisateur partage plusieurs fois.
      await SupabaseFetchers.client
          .from('post_shares')
          .insert({
            'post_id': postId,
            'member_id': memberId,
            'share_type': shareType,
          });
    } catch (_) {
      // Silencieux : le partage systeme a fonctionne, le compteur
      // est secondaire. Si la table n'existe pas encore, tant pis.
    }
  }

  /// Récupère l'ensemble des IDs de posts que l'utilisateur courant a repostés.
  Future<Set<String>> fetchUserRepostedPostIds() async {
    final authUser = SupabaseFetchers.client.auth.currentUser;
    if (authUser == null) return {};

    try {
      final memberRows = await SupabaseFetchers.selectAll(
        'members',
        columns: 'id',
        limit: 1,
        eq: {'user_id': authUser.id},
      );
      if (memberRows.isEmpty) return {};
      final memberId = memberRows.first['id'] as String;

      final rows = await SupabaseFetchers.selectAll(
        'posts',
        columns: 'repost_of',
        eq: {'author_id': memberId},
      );

      return rows
          .where((r) => r['repost_of'] != null)
          .map((r) => r['repost_of'] as String)
          .toSet();
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de vérifier vos reposts.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Reposte un post dans le fil d'actualité de l'utilisateur.
  ///
  /// Crée un nouveau post avec `repost_of = postId` et le commentaire en
  /// `content`. Enregistre le partage dans `post_shares` avec `share_type = 'repost'`.
  ///
  /// Retourne le nouveau post créé (avec les infos auteur via v_home_feed).
  Future<Post> repost({
    required String originalPostId,
    required String authorMemberId,
    String comment = '',
  }) async {
    try {
      final now = DateTime.now().toUtc();

      final inserted = await SupabaseFetchers.client
          .from('posts')
          .insert({
            'author_id': authorMemberId,
            'content': comment,
            'repost_of': originalPostId,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .select('id');

      if (inserted.isEmpty) {
        throw const ServerException('Impossible de créer le repost.');
      }

      final newId = inserted.first['id'] as String;

      // Enregistre le partage
      await recordShare(originalPostId, shareType: 'repost');

      // Recharge le post via la vue v_home_feed (jointure auteur)
      final rows = await SupabaseFetchers.selectAll(
        'v_home_feed',
        eq: {'id': newId},
        limit: 1,
      );
      if (rows.isNotEmpty) {
        return Post.fromJson(rows.first);
      }
      throw const ServerException('Repost créé mais impossible de le recharger.');
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de reposter.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Annule un repost (supprime le post créé par le repost).
  ///
  /// Supprime également l'entrée dans `post_shares` pour décrémenter le compteur.
  Future<void> undoRepost(String repostPostId) async {
    try {
      // Récupère le repost_of avant suppression pour nettoyer post_shares
      final rows = await SupabaseFetchers.selectAll(
        'posts',
        columns: 'id, repost_of',
        eq: {'id': repostPostId},
        limit: 1,
      );

      if (rows.isEmpty) return;
      final originalPostId = rows.first['repost_of'] as String?;

      // Supprime le post repost
      await SupabaseFetchers.client
          .from('posts')
          .delete()
          .eq('id', repostPostId);

      // Nettoie post_shares (le trigger décrémente automatiquement)
      if (originalPostId != null) {
        final authUser = SupabaseFetchers.client.auth.currentUser;
        if (authUser != null) {
          final memberRows = await SupabaseFetchers.selectAll(
            'members',
            columns: 'id',
            limit: 1,
            eq: {'user_id': authUser.id},
          );
          if (memberRows.isNotEmpty) {
            final memberId = memberRows.first['id'] as String;
            await SupabaseFetchers.client
                .from('post_shares')
                .delete()
                .eq('post_id', originalPostId)
                .eq('member_id', memberId)
                .eq('share_type', 'repost');
          }
        }
      }
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        "Impossible d'annuler le repost.",
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Récupère le post original pour un repost (embed visuel).
  Future<Post?> fetchRepostOriginal(String originalPostId) async {
    try {
      final rows = await SupabaseFetchers.selectAll(
        'v_home_feed',
        eq: {'id': originalPostId},
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return Post.fromJson(rows.first);
    } catch (_) {
      return null;
    }
  }

  /// Envoie un post en message privé dans une conversation.
  ///
  /// Enregistre également le partage dans `post_shares` avec `share_type = 'dm'`.
  Future<void> sendPostAsDM({
    required String postId,
    required String conversationId,
    required String senderMemberId,
  }) async {
    try {
      await SupabaseFetchers.client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': senderMemberId,
        'content': '', // Contenu vide, l'info est dans metadata
        'metadata': {'msg_type': 'post_share', 'post_id': postId},
      });

      // Enregistre le partage
      await recordShare(postId, shareType: 'dm');
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        "Impossible d'envoyer le post en message.",
        cause: e,
        stackTrace: st,
      );
    }
  }

  // ── Bookmarks ─────────────────────────────────────────────────────────────

  /// Récupère l'ensemble des IDs de posts que l'utilisateur courant a mis en favoris.
  ///
  /// Retourne un set vide si non authentifié ou si la table n'existe pas encore.
  Future<Set<String>> fetchUserBookmarkedPostIds() async {
    final authUser = SupabaseFetchers.client.auth.currentUser;
    if (authUser == null) return {};

    try {
      final memberRows = await SupabaseFetchers.selectAll(
        'members',
        columns: 'id',
        limit: 1,
        eq: {'user_id': authUser.id},
      );
      if (memberRows.isEmpty) return {};
      final memberId = memberRows.first['id'] as String;

      final rows = await SupabaseFetchers.selectAll(
        'post_bookmarks',
        columns: 'post_id',
        eq: {'member_id': memberId},
      );

      return rows.map((r) => r['post_id'] as String).toSet();
    } on sb.PostgrestException catch (e) {
      if (e.code == '42P01') return {};
      rethrow;
    } catch (_) {
      return {};
    }
  }

  /// Ajoute ou retire un post des favoris.
  Future<void> toggleBookmark({
    required String postId,
    required bool isBookmarking,
  }) async {
    final authUser = SupabaseFetchers.client.auth.currentUser;
    if (authUser == null) return;

    try {
      final memberRows = await SupabaseFetchers.selectAll(
        'members',
        columns: 'id',
        limit: 1,
        eq: {'user_id': authUser.id},
      );
      if (memberRows.isEmpty) return;
      final memberId = memberRows.first['id'] as String;

      if (isBookmarking) {
        await SupabaseFetchers.client
            .from('post_bookmarks')
            .insert({'post_id': postId, 'member_id': memberId});
      } else {
        await SupabaseFetchers.client
            .from('post_bookmarks')
            .delete()
            .eq('post_id', postId)
            .eq('member_id', memberId);
      }
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de modifier le favori.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Récupère les posts mis en favoris par l'utilisateur courant.
  ///
  /// Joint `post_bookmarks` → `v_home_feed` pour obtenir les posts complets.
  /// Retourne une liste vide si non authentifié.
  Future<List<Post>> fetchBookmarkedPosts() async {
    final authUser = SupabaseFetchers.client.auth.currentUser;
    if (authUser == null) return [];

    try {
      final memberRows = await SupabaseFetchers.selectAll(
        'members',
        columns: 'id',
        limit: 1,
        eq: {'user_id': authUser.id},
      );
      if (memberRows.isEmpty) return [];
      final memberId = memberRows.first['id'] as String;

      // Récupère les post_ids en favoris
      final bookmarkRows = await SupabaseFetchers.selectAll(
        'post_bookmarks',
        columns: 'post_id',
        eq: {'member_id': memberId},
        orderBy: 'created_at',
        ascending: false,
      );
      if (bookmarkRows.isEmpty) return [];

      final postIds = bookmarkRows.map((r) => r['post_id'] as String).toList();

      // Récupère les posts correspondants via v_home_feed
      final conditions = postIds.map((id) => 'id.eq.$id').join(',');
      final data = await SupabaseFetchers.client
          .from('v_home_feed')
          .select('*')
          .or(conditions)
          .limit(100);

      final rows = (data as List<dynamic>).cast<Map<String, dynamic>>();
      return rows.map(Post.fromJson).toList(growable: false);
    } on sb.PostgrestException catch (e) {
      if (e.code == '42P01') return [];
      throw ServerException(
        'Impossible de charger les favoris.',
        cause: e,
      );
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger les favoris.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  // ── Comment Likes ─────────────────────────────────────────────────────────

  /// Récupère l'ensemble des IDs de commentaires que l'utilisateur courant a likés.
  Future<Set<String>> fetchUserLikedCommentIds() async {
    final authUser = SupabaseFetchers.client.auth.currentUser;
    if (authUser == null) return {};

    try {
      final memberRows = await SupabaseFetchers.selectAll(
        'members',
        columns: 'id',
        limit: 1,
        eq: {'user_id': authUser.id},
      );
      if (memberRows.isEmpty) return {};
      final memberId = memberRows.first['id'] as String;

      final rows = await SupabaseFetchers.selectAll(
        'comment_likes',
        columns: 'comment_id',
        eq: {'user_id': memberId},
      );

      return rows.map((r) => r['comment_id'] as String).toSet();
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de vérifier vos likes de commentaires.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Like ou unlike un commentaire.
  Future<void> toggleCommentLike({
    required String commentId,
    required bool isLiking,
  }) async {
    final authUser = SupabaseFetchers.client.auth.currentUser;
    if (authUser == null) return;

    try {
      final memberRows = await SupabaseFetchers.selectAll(
        'members',
        columns: 'id',
        limit: 1,
        eq: {'user_id': authUser.id},
      );
      if (memberRows.isEmpty) return;
      final memberId = memberRows.first['id'] as String;

      if (isLiking) {
        await SupabaseFetchers.client
            .from('comment_likes')
            .insert({'comment_id': commentId, 'user_id': memberId});
      } else {
        await SupabaseFetchers.client
            .from('comment_likes')
            .delete()
            .eq('comment_id', commentId)
            .eq('user_id', memberId);
      }
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de modifier le like du commentaire.',
        cause: e,
        stackTrace: st,
      );
    }
  }
}
