import 'package:supabase_flutter/supabase_flutter.dart';

import '../../errors/app_exception.dart';
import '../models/chapter.dart';
import '../models/organization.dart';
import '../supabase_fetchers.dart';

/// Repository d'accès au réseau d'associations (organizations + chapters).
class OrganizationsRepository {
  const OrganizationsRepository();

  /// Récupère toutes les organisations actives, triées par pays puis nom.
  Future<List<Organization>> fetchOrganizations() async {
    try {
      final rows = await SupabaseFetchers.selectAll(
        'organizations',
        orderBy: 'country',
        ascending: true,
      );
      return rows.map(Organization.fromJson).toList(growable: false);
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger les associations.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Récupère tous les chapitres actifs avec le nom de l'organisation parente
  /// (via embed `organization(*)`).
  Future<List<Chapter>> fetchChapters() async {
    try {
      final rows = await Supabase.instance.client
          .from('chapters')
          .select('*, organization:organizations(name, country)')
          .eq('status', 'active')
          .order('city', ascending: true);
      final data = rows as List<dynamic>;
      return data
          .whereType<Map<String, dynamic>>()
          .map(Chapter.fromJson)
          .toList(growable: false);
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger les branches.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Résout le chapitre actif pour un couple (pays, ville).
  ///
  /// Utilisé pour prévisualiser le matching avant l'inscription ou pour
  /// suggérer une branche lors d'un changement de localisation.
  Future<Chapter?> fetchChapterByCity({
    required String country,
    required String city,
  }) async {
    try {
      final rows = await Supabase.instance.client
          .from('chapters')
          .select('*, organization:organizations(name, country)')
          .eq('status', 'active')
          .eq('city', city)
          .limit(20);

      final data = rows as List<dynamic>;
      final matches = data
          .whereType<Map<String, dynamic>>()
          .map(Chapter.fromJson)
          .where((c) => c.organizationCountry == country)
          .toList(growable: false);

      return matches.isEmpty ? null : matches.first;
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de rechercher la branche correspondante.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Récupère le chapitre correspondant à l'utilisateur Supabase courant.
  ///
  /// S'appuie sur `members.chapter_id` (peuplé par le trigger
  /// `match_member_to_chapter` à l'inscription). Renvoie `null` si :
  /// - l'utilisateur n'est pas authentifié,
  /// - sa ligne `members` n'a pas encore de `chapter_id` (pays/ville non matchés).
  Future<Chapter?> fetchCurrentChapter() async {
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) return null;

    try {
      // Étape 1 : récupère le chapter_id de la ligne members
      final memberRows = await SupabaseFetchers.selectAll(
        'members',
        columns: 'chapter_id',
        limit: 1,
        eq: {'user_id': authUser.id},
      );
      if (memberRows.isEmpty) return null;

      final chapterId = memberRows.first['chapter_id'] as String?;
      if (chapterId == null) return null;

      // Étape 2 : récupère le chapitre avec son organisation parente
      final chapterRows = await Supabase.instance.client
          .from('chapters')
          .select('*, organization:organizations(name, country)')
          .eq('id', chapterId)
          .limit(1);

      final chapterData = chapterRows as List<dynamic>;
      if (chapterData.isEmpty) return null;
      return Chapter.fromJson(chapterData.first as Map<String, dynamic>);
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger votre branche.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Récupère le chapitre d'un membre par son ID.
  ///
  /// Utilisé pour les profils publics. S'appuie sur `members.chapter_id`.
  /// Renvoie `null` si le membre n'a pas de chapitre associé.
  Future<Chapter?> fetchChapterByMemberId(String memberId) async {
    try {
      // Étape 1 : récupère le chapter_id de la ligne members
      final memberRows = await SupabaseFetchers.selectAll(
        'members',
        columns: 'chapter_id',
        limit: 1,
        eq: {'id': memberId},
      );
      if (memberRows.isEmpty) return null;

      final chapterId = memberRows.first['chapter_id'] as String?;
      if (chapterId == null) return null;

      // Étape 2 : récupère le chapitre avec son organisation parente
      final chapterRows = await Supabase.instance.client
          .from('chapters')
          .select('*, organization:organizations(name, country)')
          .eq('id', chapterId)
          .limit(1);

      final chapterData = chapterRows as List<dynamic>;
      if (chapterData.isEmpty) return null;
      return Chapter.fromJson(chapterData.first as Map<String, dynamic>);
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger la branche du membre.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Propose une nouvelle association (self-serve) — insérée en `status='pending'`.
  ///
  /// Renvoie l'organization créée (sans son ID auto-généré).
  Future<Organization> proposeOrganization({
    required String name,
    required String country,
    String? description,
  }) async {
    try {
      final rows = await Supabase.instance.client
          .from('organizations')
          .insert({
            'name': name,
            'country': country,
            'description': description,
            'status': 'pending',
          })
          .select()
          .limit(1);

      final data = rows as List<dynamic>;
      if (data.isEmpty) {
        throw const ServerException('Insertion sans retour.');
      }
      return Organization.fromJson(data.first as Map<String, dynamic>);
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de proposer l\'association.',
        cause: e,
        stackTrace: st,
      );
    }
  }
}
