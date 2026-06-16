import 'package:supabase_flutter/supabase_flutter.dart';

import '../../errors/app_exception.dart';
import '../models/community.dart';
import '../models/community_post.dart';

/// Repository pour les groupes/communautés.
class CommunitiesRepository {
  const CommunitiesRepository();

  /// Récupère toutes les communautés (publiques + celles dont l'utilisateur
  /// courant est membre).
  Future<List<Community>> fetchAll() async {
    try {
      final response = await Supabase.instance.client
          .from('communities')
          .select('*')
          .order('member_count', ascending: false)
          .limit(50);

      return (response as List)
          .cast<Map<String, dynamic>>()
          .map((json) => Community.fromJson(json))
          .toList(growable: false);
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger les communautés.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Récupère une communauté par son ID.
  Future<Community> fetchById(String id) async {
    try {
      final response = await Supabase.instance.client
          .from('communities')
          .select('*')
          .eq('id', id)
          .single();

      return Community.fromJson(response as Map<String, dynamic>);
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger les détails de la communauté.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Crée une nouvelle communauté. Retourne la communauté créée.
  Future<Community> create({
    required String name,
    required String description,
    String? coverUrl,
    required String category,
    required String visibility,
    required String createdBy,
    String? organizationId,
    String? chapterId,
  }) async {
    try {
      final response = await Supabase.instance.client
          .from('communities')
          .insert({
            'name': name,
            'description': description,
            if (coverUrl != null) 'cover_url': coverUrl,
            'category': category,
            'visibility': visibility,
            'created_by': createdBy,
            if (organizationId != null) 'organization_id': organizationId,
            if (chapterId != null) 'chapter_id': chapterId,
          })
          .select()
          .single();

      final community =
          Community.fromJson(response as Map<String, dynamic>);

      // Ajoute automatiquement le créateur comme admin
      await Supabase.instance.client.from('community_members').insert({
        'community_id': community.id,
        'member_id': createdBy,
        'role': 'admin',
      });

      return community;
    } catch (e, st) {
      throw ServerException(
        'Impossible de créer la communauté.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Met à jour une communauté.
  Future<void> update({
    required String id,
    String? name,
    String? description,
    String? coverUrl,
    String? category,
    String? visibility,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (coverUrl != null) data['cover_url'] = coverUrl;
      if (category != null) data['category'] = category;
      if (visibility != null) data['visibility'] = visibility;

      await Supabase.instance.client
          .from('communities')
          .update(data)
          .eq('id', id);
    } catch (e, st) {
      throw ServerException(
        'Impossible de modifier la communauté.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Supprime une communauté.
  Future<void> delete(String id) async {
    try {
      await Supabase.instance.client
          .from('communities')
          .delete()
          .eq('id', id);
    } catch (e, st) {
      throw ServerException(
        'Impossible de supprimer la communauté.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  // ── Adhésion ──────────────────────────────────────────────────────────────

  /// L'utilisateur courant rejoint un groupe.
  Future<void> join(String communityId, String memberId) async {
    try {
      await Supabase.instance.client.from('community_members').insert({
        'community_id': communityId,
        'member_id': memberId,
      });
    } catch (e, st) {
      throw ServerException(
        'Impossible de rejoindre la communauté.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// L'utilisateur courant quitte un groupe.
  Future<void> leave(String communityId, String memberId) async {
    try {
      await Supabase.instance.client
          .from('community_members')
          .delete()
          .eq('community_id', communityId)
          .eq('member_id', memberId);
    } catch (e, st) {
      throw ServerException(
        'Impossible de quitter la communauté.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Vérifie si un membre est membre actif d'un groupe.
  Future<bool> checkMembership(String communityId, String memberId) async {
    try {
      final response = await Supabase.instance.client
          .from('community_members')
          .select('id')
          .eq('community_id', communityId)
          .eq('member_id', memberId)
          .eq('status', 'active')
          .limit(1);
      return (response as List).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Vérifie si un membre est admin/modérateur d'un groupe.
  Future<bool> checkAdmin(String communityId, String memberId) async {
    try {
      final response = await Supabase.instance.client
          .from('community_members')
          .select('id')
          .eq('community_id', communityId)
          .eq('member_id', memberId)
          .inFilter('role', ['admin', 'moderator'])
          .eq('status', 'active')
          .limit(1);
      return (response as List).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Récupère les IDs des communautés dont l'utilisateur est membre.
  Future<Set<String>> fetchJoinedIds(String memberId) async {
    try {
      final response = await Supabase.instance.client
          .from('community_members')
          .select('community_id')
          .eq('member_id', memberId)
          .eq('status', 'active');

      return (response as List)
          .cast<Map<String, dynamic>>()
          .map((json) => json['community_id'] as String)
          .toSet();
    } catch (_) {
      return {};
    }
  }

  /// Récupère les IDs des communautés dont l'utilisateur est admin.
  Future<Set<String>> fetchAdminIds(String memberId) async {
    try {
      final response = await Supabase.instance.client
          .from('community_members')
          .select('community_id')
          .eq('member_id', memberId)
          .inFilter('role', ['admin', 'moderator'])
          .eq('status', 'active');

      return (response as List)
          .cast<Map<String, dynamic>>()
          .map((json) => json['community_id'] as String)
          .toSet();
    } catch (_) {
      return {};
    }
  }

  // ── Posts ─────────────────────────────────────────────────────────────────

  /// Récupère les posts d'une communauté (récent → ancien).
  /// Optionnellement joint les infos de l'auteur via embed PostgREST.
  Future<List<CommunityPost>> fetchPosts(String communityId,
      {String? currentMemberId}) async {
    try {
      final response = await Supabase.instance.client
          .from('community_posts')
          .select('*, author:author_id(full_name, avatar_url)')
          .eq('community_id', communityId)
          .order('created_at', ascending: false)
          .limit(50);

      return (response as List)
          .cast<Map<String, dynamic>>()
          .map((json) =>
              CommunityPost.fromJson(json, currentMemberId: currentMemberId))
          .toList(growable: false);
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger les publications.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Ajoute un post dans le feed d'une communauté.
  Future<CommunityPost> addPost({
    required String communityId,
    required String authorId,
    required String content,
    String? imageUrl,
  }) async {
    try {
      final response = await Supabase.instance.client
          .from('community_posts')
          .insert({
            'community_id': communityId,
            'author_id': authorId,
            'content': content,
            if (imageUrl != null) 'image_url': imageUrl,
          })
          .select()
          .single();

      return CommunityPost.fromJson(response as Map<String, dynamic>);
    } catch (e, st) {
      throw ServerException(
        'Impossible de publier dans la communauté.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Met à jour le contenu d'un post.
  Future<void> updatePost({
    required String postId,
    required String content,
    String? imageUrl,
  }) async {
    try {
      final Map<String, dynamic> data = {'content': content};
      if (imageUrl != null) data['image_url'] = imageUrl;
      await Supabase.instance.client
          .from('community_posts')
          .update(data)
          .eq('id', postId);
    } catch (e, st) {
      throw ServerException(
        'Impossible de modifier la publication.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Supprime un post.
  Future<void> deletePost(String postId) async {
    try {
      await Supabase.instance.client
          .from('community_posts')
          .delete()
          .eq('id', postId);
    } catch (e, st) {
      throw ServerException(
        'Impossible de supprimer la publication.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  // ── Chat ─────────────────────────────────────────────────────────────────────

  /// Crée ou récupère la conversation associée à une communauté pour le chat.
  /// Retourne l'ID de la conversation.
  Future<String> getOrCreateConversation(String communityId) async {
    try {
      final response = await Supabase.instance.client.rpc(
        'ensure_community_conversation',
        params: {'p_community_id': communityId},
      );
      return response as String;
    } catch (e, st) {
      throw ServerException(
        'Impossible de créer la conversation du groupe.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Ajoute un participant à la conversation de la communauté.
  /// Appelé quand un membre rejoint le groupe.
  Future<void> addConversationParticipant(
      String communityId, String memberId) async {
    try {
      final communityResponse = await Supabase.instance.client
          .from('communities')
          .select('conversation_id')
          .eq('id', communityId)
          .single();
      final convId =
          (communityResponse as Map<String, dynamic>)['conversation_id']
              as String?;
      if (convId == null) return;

      await Supabase.instance.client
          .from('conversation_participants')
          .upsert({
            'conversation_id': convId,
            'member_id': memberId,
          });
    } catch (_) {
      // Silencieux
    }
  }

  // ── Invitations ────────────────────────────────────────────────────────────

  /// Récupère le code d'invitation d'une communauté.
  /// Retourne `null` si aucun code n'a été généré.
  Future<String?> getInviteCode(String communityId) async {
    try {
      final response = await Supabase.instance.client
          .from('community_invites')
          .select('code')
          .eq('community_id', communityId)
          .maybeSingle();

      if (response == null) return null;
      return (response as Map<String, dynamic>)['code'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Génère (ou régénère) un code d'invitation pour une communauté.
  /// Retourne le nouveau code.
  Future<String> generateInviteCode({
    required String communityId,
    required String createdBy,
  }) async {
    try {
      // Supprime l'ancien code s'il existe
      await Supabase.instance.client
          .from('community_invites')
          .delete()
          .eq('community_id', communityId);

      // Utilise la fonction gen_invite_code() pour générer un code côté DB
      final codeResponse = await Supabase.instance.client.rpc(
        'gen_invite_code',
      );
      final code = codeResponse as String;

      await Supabase.instance.client.from('community_invites').insert({
        'community_id': communityId,
        'code': code,
        'created_by': createdBy,
      });

      return code;
    } catch (e, st) {
      throw ServerException(
        'Impossible de générer le code d\'invitation.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Rejoint une communauté via un code d'invitation.
  /// Retourne l'ID de la communauté rejointe, ou lève une exception.
  Future<String> joinByInviteCode(String code) async {
    try {
      final response = await Supabase.instance.client.rpc(
        'join_community_by_invite_code',
        params: {'invite_code': code},
      );
      return response as String;
    } catch (e) {
      // Les erreurs de la fonction sont renvoyées telles quelles
      throw ServerException(
        e.toString(),
        cause: e,
      );
    }
  }

  // ── Membres ──────────────────────────────────────────────────────────────

  /// Récupère la liste des membres d'une communauté.
  Future<List<Map<String, dynamic>>> fetchMembers(String communityId) async {
    try {
      final response = await Supabase.instance.client
          .from('community_members')
          .select('*, member:member_id(full_name, avatar_url)')
          .eq('community_id', communityId)
          .eq('status', 'active')
          .order('joined_at', ascending: true);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger les membres.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Met à jour le rôle d'un membre.
  Future<void> updateMemberRole(
      String communityId, String memberId, String role) async {
    try {
      await Supabase.instance.client
          .from('community_members')
          .update({'role': role})
          .eq('community_id', communityId)
          .eq('member_id', memberId);
    } catch (e, st) {
      throw ServerException(
        'Impossible de modifier le rôle du membre.',
        cause: e,
        stackTrace: st,
      );
    }
  }
}
