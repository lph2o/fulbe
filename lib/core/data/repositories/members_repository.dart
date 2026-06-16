import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart'
    hide AuthException;

import '../../errors/app_exception.dart';
import '../models/member.dart';
import '../supabase_fetchers.dart';

/// Repository d'accès aux membres (annuaire, profil, world map).
class MembersRepository {
  const MembersRepository();

  /// Récupère un membre par son ID.
  ///
  /// Retourne `null` si le membre n'est pas trouvé.
  Future<Member?> fetchById(String memberId) async {
    try {
      final rows = await SupabaseFetchers.selectAll(
        'v_member_profiles',
        limit: 1,
        eq: {'id': memberId},
      );
      if (rows.isEmpty) return null;
      return Member.fromJson(rows.first);
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger le profil.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Récupère tous les membres actifs, triés par nom.
  Future<List<Member>> fetchAll() async {
    try {
      final rows = await SupabaseFetchers.selectAll(
        'v_member_profiles',
        orderBy: 'full_name',
        ascending: true,
      );
      return rows.map(Member.fromJson).toList(growable: false);
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger l\'annuaire.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Récupère le nombre total de membres sur la plateforme.
  ///
  /// Utilise le COUNT exact PostgREST. Retourne 0 en cas d'erreur
  /// pour ne pas bloquer l'affichage du header.
  Future<int> fetchTotalCount() async {
    try {
      final data = await SupabaseFetchers.client
          .from('members')
          .select('id')
          .limit(0)
          .count(CountOption.exact);
      return (data as dynamic).count as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Récupère les clusters géographiques (World Map).
  Future<List<MemberCluster>> fetchClusters() async {
    try {
      final rows = await SupabaseFetchers.selectAll(
        'member_clusters',
        orderBy: 'count',
        ascending: false,
      );
      return rows.map(MemberCluster.fromJson).toList(growable: false);
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger la carte des membres.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Récupère le membre correspondant à l'utilisateur Supabase courant.
  ///
  /// Déclenche le trigger `on_auth_user_created` qui insère automatiquement
  /// une ligne dans `public.members` à l'inscription. La ligne est alors
  /// remontée ici via `id = auth.uid()`.
  ///
  /// Retourne `null` si l'utilisateur n'est pas authentifié ou si la ligne
  /// n'existe pas encore (à l'écran de bienvenue / pending email confirm).
  Future<Member?> fetchCurrent() async {
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) return null;

    try {
      final rows = await SupabaseFetchers.selectAll(
        'v_member_profiles',
        limit: 1,
        eq: {'user_id': authUser.id},
      );
      if (rows.isEmpty) return null;
      return Member.fromJson(rows.first);
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger votre profil.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Nombre d'abonnés (followers) d'un membre.
  Future<int> fetchFollowerCount(String memberId) async {
    try {
      final rows = await Supabase.instance.client
          .from('member_follows')
          .select('id')
          .eq('following_id', memberId);
      return rows.length;
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger le nombre d\'abonnés.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Nombre d'abonnements (following) d'un membre.
  Future<int> fetchFollowingCount(String memberId) async {
    try {
      final rows = await Supabase.instance.client
          .from('member_follows')
          .select('id')
          .eq('follower_id', memberId);
      return rows.length;
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger le nombre d\'abonnements.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Vérifie si l'utilisateur courant suit déjà un membre.
  Future<bool> fetchIsFollowing(String memberId) async {
    try {
      final authUser = Supabase.instance.client.auth.currentUser;
      if (authUser == null) return false;

      final currentMember = await fetchCurrent();
      if (currentMember == null) return false;

      final rows = await Supabase.instance.client
          .from('member_follows')
          .select('id')
          .eq('follower_id', currentMember.id)
          .eq('following_id', memberId);
      return rows.isNotEmpty;
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de vérifier l\'abonnement.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Suivre un membre.
  Future<void> followMember(String memberId) async {
    try {
      final authUser = Supabase.instance.client.auth.currentUser;
      if (authUser == null) {
        throw const AuthException('Vous devez être connecté pour suivre un membre.');
      }

      final currentMember = await fetchCurrent();
      if (currentMember == null) {
        throw const AuthException('Profil introuvable.');
      }

      await Supabase.instance.client.from('member_follows').insert({
        'follower_id': currentMember.id,
        'following_id': memberId,
      });
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de suivre ce membre.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Ne plus suivre un membre.
  Future<void> unfollowMember(String memberId) async {
    try {
      final authUser = Supabase.instance.client.auth.currentUser;
      if (authUser == null) {
        throw const AuthException('Vous devez être connecté pour vous désabonner.');
      }

      final currentMember = await fetchCurrent();
      if (currentMember == null) {
        throw const AuthException('Profil introuvable.');
      }

      await Supabase.instance.client
          .from('member_follows')
          .delete()
          .eq('follower_id', currentMember.id)
          .eq('following_id', memberId);
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de vous désabonner.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Récupère les membres appartenant à un chapitre.
  ///
  /// Utilise `v_member_profiles` (qui inclut `chapter_id` depuis la
  /// migration 017) pour bénéficier du flatten des skills.
  Future<List<Member>> fetchByChapter(String chapterId) async {
    try {
      final rows = await SupabaseFetchers.selectAll(
        'v_member_profiles',
        eq: {'chapter_id': chapterId},
        orderBy: 'full_name',
        ascending: true,
      );
      return rows.map(Member.fromJson).toList(growable: false);
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger les membres du chapitre.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Récupère la liste des abonnés (followers) d'un membre.
  ///
  /// Approche en deux étapes : 1) récupère les follower_ids depuis
  /// `member_follows`, 2) charge les profils complets via `v_member_profiles`.
  Future<List<Member>> fetchFollowers(String memberId) async {
    try {
      // Étape 1 : récupérer les IDs des abonnés
      final followData = await Supabase.instance.client
          .from('member_follows')
          .select('follower_id')
          .eq('following_id', memberId)
          .order('created_at', ascending: false);

      final followRows =
          (followData as List<dynamic>).cast<Map<String, dynamic>>();
      final followerIds =
          followRows.map((r) => r['follower_id'] as String).toList();

      if (followerIds.isEmpty) return [];

      // Étape 2 : charger les profils via la vue (or filter PostgREST)
      final conditions =
          followerIds.map((id) => 'id.eq.$id').join(',');
      final data = await Supabase.instance.client
          .from('v_member_profiles')
          .select('*')
          .or(conditions);

      final rows = (data as List<dynamic>).cast<Map<String, dynamic>>();
      final members = rows.map(Member.fromJson).toList();

      // Ré-ordonner selon l'ordre d'origine (plus récent d'abord)
      final memberMap = {for (final m in members) m.id: m};
      return followerIds
          .map((id) => memberMap[id])
          .whereType<Member>()
          .toList(growable: false);
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger les abonnés.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Récupère la liste des abonnements (following) d'un membre.
  ///
  /// Approche en deux étapes : 1) récupère les following_ids depuis
  /// `member_follows`, 2) charge les profils complets via `v_member_profiles`.
  Future<List<Member>> fetchFollowing(String memberId) async {
    try {
      // Étape 1 : récupérer les IDs des abonnements
      final followData = await Supabase.instance.client
          .from('member_follows')
          .select('following_id')
          .eq('follower_id', memberId)
          .order('created_at', ascending: false);

      final followRows =
          (followData as List<dynamic>).cast<Map<String, dynamic>>();
      final followingIds =
          followRows.map((r) => r['following_id'] as String).toList();

      if (followingIds.isEmpty) return [];

      // Étape 2 : charger les profils via la vue (or filter PostgREST)
      final conditions =
          followingIds.map((id) => 'id.eq.$id').join(',');
      final data = await Supabase.instance.client
          .from('v_member_profiles')
          .select('*')
          .or(conditions);

      final rows = (data as List<dynamic>).cast<Map<String, dynamic>>();
      final members = rows.map(Member.fromJson).toList();

      // Ré-ordonner selon l'ordre d'origine (plus récent d'abord)
      final memberMap = {for (final m in members) m.id: m};
      return followingIds
          .map((id) => memberMap[id])
          .whereType<Member>()
          .toList(growable: false);
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger les abonnements.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Upload une cover vers Supabase Storage et met à jour `members.cover_url`.
  ///
  /// Supprime l'ancienne cover du bucket après avoir uploadé la nouvelle.
  /// Retourne l'URL publique de la cover uploadée.
  Future<String> updateCover(File imageFile) async {
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) {
      throw const AuthException('Vous devez être connecté.');
    }

    try {
      final member = await fetchCurrent();
      if (member == null) {
        throw const AuthException('Profil introuvable.');
      }

      final extension = imageFile.path.split('.').last;
      final fileName =
          '${authUser.id}_${DateTime.now().millisecondsSinceEpoch}.$extension';

      // Upload vers Supabase Storage
      await Supabase.instance.client.storage
          .from('covers')
          .upload(fileName, imageFile);

      // Récupérer l'URL publique
      final url = Supabase.instance.client.storage
          .from('covers')
          .getPublicUrl(fileName);

      // Mettre à jour la table members
      await Supabase.instance.client
          .from('members')
          .update({'cover_url': url})
          .eq('id', member.id);

      // Supprimer l'ancienne cover (après succès de l'upload, silencieux)
      await _deleteOldFile(member.coverUrl, 'covers');

      return url;
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de mettre à jour la photo de couverture.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Upload un avatar vers Supabase Storage et met à jour `members.avatar_url`.
  ///
  /// Supprime l'ancien avatar du bucket après avoir uploadé le nouveau.
  /// Retourne l'URL publique de l'avatar uploadé.
  Future<String> updateAvatar(File imageFile) async {
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) {
      throw const AuthException('Vous devez être connecté.');
    }

    try {
      final member = await fetchCurrent();
      if (member == null) {
        throw const AuthException('Profil introuvable.');
      }

      final extension = imageFile.path.split('.').last;
      final fileName = '${authUser.id}_${DateTime.now().millisecondsSinceEpoch}.$extension';

      // Upload vers Supabase Storage
      await Supabase.instance.client.storage
          .from('avatars')
          .upload(fileName, imageFile);

      // Récupérer l'URL publique
      final url = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(fileName);

      // Mettre à jour la table members
      await Supabase.instance.client
          .from('members')
          .update({'avatar_url': url})
          .eq('id', member.id);

      // Supprimer l'ancien avatar (après succès de l'upload, silencieux)
      await _deleteOldFile(member.avatarUrl, 'avatars');

      return url;
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de mettre à jour la photo de profil.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Extrait le nom de fichier d'une URL de storage Supabase et le supprime.
  ///
  /// Silencieux en cas d'erreur : on ne bloque pas l'upload si la suppression
  /// échoue (fichier déjà supprimé, permissions, etc.).
  Future<void> _deleteOldFile(String? url, String bucket) async {
    if (url == null || url.isEmpty) return;

    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      // Les URLs Supabase storage ont la forme :
      // /storage/v1/object/public/{bucket}/{fileName}
      final bucketIndex = segments.indexOf(bucket);
      if (bucketIndex != -1 && bucketIndex + 1 < segments.length) {
        final fileName = segments.sublist(bucketIndex + 1).join('/');
        await Supabase.instance.client.storage
            .from(bucket)
            .remove([fileName]);
      }
    } catch (_) {
      // Silencieux : l'ancien fichier reste orphelin, mais l'upload continue.
    }
  }
}
