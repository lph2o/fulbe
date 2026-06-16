import '../../errors/app_exception.dart';
import '../models/job.dart';
import '../supabase_fetchers.dart';

/// Repository d'accès aux offres d'emploi.
class JobsRepository {
  const JobsRepository();

  /// Crée une nouvelle offre d'emploi.
  Future<Job> createJob({
    required String title,
    required String company,
    String? companyLogoUrl,
    String? companyInitials,
    required String location,
    required String type,
    required String domain,
    String? badge,
    String? badgeType,
    String? postedByMemberId,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      final inserted = await SupabaseFetchers.client
          .from('jobs')
          .insert({
            'title': title,
            'company': company,
            'company_logo_url': companyLogoUrl,
            'company_initials': companyInitials,
            'location': location,
            'type': type,
            'domain': domain,
            'posted_ago': 'à l\'instant',
            'badge': badge,
            'badge_type': badgeType,
            if (postedByMemberId != null) 'posted_by': postedByMemberId,
            'active': true,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .select('id');

      if (inserted.isNotEmpty) {
        final newId = inserted.first['id'] as String;
        final rows = await SupabaseFetchers.selectAll(
          'jobs',
          eq: {'id': newId},
          limit: 1,
        );
        if (rows.isNotEmpty) return Job.fromJson(rows.first);
      }
      throw const ServerException('Offre créée mais impossible de la recharger.');
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de créer l\'offre d\'emploi.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Récupère toutes les offres, triées par date de publication (récent d'abord).
  Future<List<Job>> fetchAll() async {
    try {
      final rows = await SupabaseFetchers.selectAll(
        'jobs',
        orderBy: 'created_at',
        ascending: false,
      );
      return rows.map(Job.fromJson).toList(growable: false);
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger les offres d\'emploi.',
        cause: e,
        stackTrace: st,
      );
    }
  }
}
