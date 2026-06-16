import 'dart:io';

import '../../errors/app_exception.dart';
import '../models/event.dart';
import '../supabase_fetchers.dart';

/// Repository d'accès aux événements.
///
/// Toutes les erreurs sont converties en [AppException] localisées en français
/// pour affichage direct dans l'UI.
class EventsRepository {
  const EventsRepository();

  /// Crée un nouvel événement.
  ///
  /// [imageFile] est optionnel — si fourni, le fichier est uploadé vers
  /// Supabase Storage (bucket `event-images`) et l'URL publique est stockée
  /// dans le champ `image_url`.
  Future<Event> createEvent({
    required String title,
    required DateTime date,
    required String location,
    required String category,
    required String description,
    File? imageFile,
    String? createdByMemberId,
  }) async {
    String imageUrl = '';

    // ── Upload image (si fournie) ────────────────────────────
    if (imageFile != null) {
      try {
        final ext = imageFile.uri.pathSegments.last.contains('.')
            ? imageFile.uri.pathSegments.last.split('.').last
            : 'jpg';
        final fileName =
            '${DateTime.now().microsecondsSinceEpoch}.$ext';
        await SupabaseFetchers.client.storage
            .from('event-images')
            .upload(fileName, imageFile);

        imageUrl = SupabaseFetchers.client.storage
            .from('event-images')
            .getPublicUrl(fileName);
      } catch (_) {
        // Échec de l'upload image → on continue sans image
      }
    }

    // ── Insérer l'événement ──────────────────────────────────
    try {
      final now = DateTime.now().toUtc();
      final inserted = await SupabaseFetchers.client
          .from('events')
          .insert({
            'title': title,
            'date': date.toIso8601String(),
            'location': location,
            'category': category,
            'description': description,
            'image_url': imageUrl,
            'attendee_count': 0,
            if (createdByMemberId != null) 'created_by': createdByMemberId,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .select('id');

      if (inserted.isNotEmpty) {
        final newId = inserted.first['id'] as String;
        final rows = await SupabaseFetchers.selectAll(
          'events',
          eq: {'id': newId},
          limit: 1,
        );
        if (rows.isNotEmpty) return Event.fromJson(rows.first);
      }
      throw const ServerException('Événement créé mais impossible de le recharger.');
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de créer l\'événement.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Récupère tous les événements, triés par date de création (plus récent d'abord).
  Future<List<Event>> fetchAll() async {
    try {
      final rows = await SupabaseFetchers.selectAll(
        'events',
        orderBy: 'created_at',
        ascending: false,
      );
      return rows.map(Event.fromJson).toList(growable: false);
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger les événements.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Récupère l'ensemble des IDs d'événements auxquels l'utilisateur
  /// courant a RSVPé.
  ///
  /// Retourne un set vide si non authentifié ou si la requête échoue
  /// (résilience : ne bloque pas le chargement des événements).
  Future<Set<String>> fetchUserRsvpIds() async {
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
        'event_rsvps',
        columns: 'event_id',
        eq: {'user_id': memberId},
      );

      return rows
          .map((r) => r['event_id'] as String)
          .toSet();
    } catch (_) {
      // Silencieux : le statut RSVP sera simplement absent de l'UI
      return {};
    }
  }

  /// RSVP ou annule le RSVP à un événement.
  ///
  /// Le trigger `tg_event_rsvp_count` (migration 004) met automatiquement
  /// à jour `events.attendee_count`.
  Future<void> toggleRsvp(String eventId, bool isRsvping) async {
    final authUser = SupabaseFetchers.client.auth.currentUser;
    if (authUser == null) return;

    try {
      // Résout members.id
      final memberRows = await SupabaseFetchers.selectAll(
        'members',
        columns: 'id',
        limit: 1,
        eq: {'user_id': authUser.id},
      );
      if (memberRows.isEmpty) return;
      final memberId = memberRows.first['id'] as String;

      if (isRsvping) {
        // INSERT
        await SupabaseFetchers.client
            .from('event_rsvps')
            .insert({'event_id': eventId, 'user_id': memberId});
      } else {
        // DELETE (les filtres .eq() suivent .delete() dans supabase_flutter)
        await SupabaseFetchers.client
            .from('event_rsvps')
            .delete()
            .eq('event_id', eventId)
            .eq('user_id', memberId);
      }
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de modifier votre participation.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Récupère un événement par son ID.
  Future<Event> fetchById(String eventId) async {
    try {
      final rows = await SupabaseFetchers.selectAll(
        'events',
        eq: {'id': eventId},
        limit: 1,
      );
      if (rows.isEmpty) throw const NotFoundException('Événement introuvable.');
      return Event.fromJson(rows.first);
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger l\'événement.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Récupère les événements créés par les membres d'un chapitre.
  ///
  /// Fait un join indirect via `members.chapter_id`.
  Future<List<Event>> fetchByChapter(String chapterId) async {
    try {
      // Étape 1 : récupère les member_ids du chapitre
      final memberRows = await SupabaseFetchers.selectAll(
        'members',
        columns: 'id',
        eq: {'chapter_id': chapterId},
      );
      if (memberRows.isEmpty) return [];
      final memberIds = memberRows.map((r) => r['id'] as String).toList();

      // Étape 2 : récupère les événements créés par ces membres
      final conditions =
          memberIds.map((id) => 'created_by.eq.$id').join(',');
      final data = await SupabaseFetchers.client
          .from('events')
          .select('*')
          .or(conditions)
          .order('created_at', ascending: false)
          .limit(50);

      final rows = (data as List<dynamic>).cast<Map<String, dynamic>>();
      return rows.map(Event.fromJson).toList(growable: false);
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger les événements du chapitre.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Récupère la liste des participants (members) inscrits à un événement.
  Future<List<Map<String, dynamic>>> fetchAttendees(String eventId) async {
    try {
      final data = await SupabaseFetchers.client
          .from('event_rsvps')
          .select('members(id, full_name, profession, city, country, avatar_url, initials)')
          .eq('event_id', eventId)
          .order('created_at', ascending: true);

      final rows = (data as List<dynamic>).cast<Map<String, dynamic>>();
      return rows
          .map((r) => r['members'] as Map<String, dynamic>?)
          .where((m) => m != null)
          .cast<Map<String, dynamic>>()
          .toList(growable: false);
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger les participants.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Récupère les IDs des événements créés par l'utilisateur courant.
  Future<List<String>> fetchMyCreatedEventIds() async {
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

      final rows = await SupabaseFetchers.selectAll(
        'events',
        columns: 'id',
        eq: {'created_by': memberId},
      );
      return rows.map((r) => r['id'] as String).toList();
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger vos événements créés.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Supprime un événement par son ID.
  ///
  /// Seul le créateur peut supprimer (vérifié par RLS côté Supabase).
  Future<void> deleteEvent(String eventId) async {
    try {
      await SupabaseFetchers.client
          .from('events')
          .delete()
          .eq('id', eventId);
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de supprimer l\'événement.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Met à jour un événement existant.
  ///
  /// Seul le créateur peut modifier (vérifié par RLS côté Supabase).
  ///
  /// [imageFile] est optionnel — si fourni, la nouvelle image est uploadée
  /// vers Supabase Storage et remplace l'`image_url` existante.
  ///
  /// [clearImage] — si `true`, supprime l'`image_url` existante (passe à vide).
  /// Ignoré si [imageFile] est fourni (la nouvelle image prend priorité).
  Future<void> updateEvent({
    required String eventId,
    required String title,
    required DateTime date,
    required String location,
    required String category,
    required String description,
    File? imageFile,
    bool clearImage = false,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      final updateData = <String, dynamic>{
        'title': title,
        'date': date.toIso8601String(),
        'location': location,
        'category': category,
        'description': description,
        'updated_at': now.toIso8601String(),
      };

      // ── Upload nouvelle image (si fournie) ──────────────
      if (imageFile != null) {
        try {
          final ext = imageFile.uri.pathSegments.last.contains('.')
              ? imageFile.uri.pathSegments.last.split('.').last
              : 'jpg';
          final fileName =
              '${DateTime.now().microsecondsSinceEpoch}.$ext';
          await SupabaseFetchers.client.storage
              .from('event-images')
              .upload(fileName, imageFile);

          final newImageUrl = SupabaseFetchers.client.storage
              .from('event-images')
              .getPublicUrl(fileName);
          updateData['image_url'] = newImageUrl;
        } catch (_) {
          // Échec de l'upload image → on continue sans changer l'image
        }
      } else if (clearImage) {
        updateData['image_url'] = '';
      }

      await SupabaseFetchers.client
          .from('events')
          .update(updateData)
          .eq('id', eventId);
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de modifier l\'événement.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Récupère les IDs des événements où l'utilisateur courant est inscrit.
  Future<List<String>> fetchMyRsvpEventIds() async {
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

      final rows = await SupabaseFetchers.selectAll(
        'event_rsvps',
        columns: 'event_id',
        eq: {'user_id': memberId},
      );
      return rows.map((r) => r['event_id'] as String).toList();
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger vos inscriptions.',
        cause: e,
        stackTrace: st,
      );
    }
  }
}
