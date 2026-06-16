import '../../errors/app_exception.dart';
import '../models/service.dart';
import '../supabase_fetchers.dart';

/// Repository d'accès aux services marketplace.
class MarketplaceRepository {
  const MarketplaceRepository();

  /// Crée un nouveau service marketplace.
  Future<MarketService> createService({
    required String title,
    required String description,
    required String category,
    required String categoryIcon,
    required String price,
    required String priceLabel,
    String? imageUrl,
    String? providerMemberId,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      final inserted = await SupabaseFetchers.client
          .from('marketplace_services')
          .insert({
            'title': title,
            'description': description,
            'category': category,
            'category_icon': categoryIcon,
            'price': price,
            'price_label': priceLabel,
            'rating': 0.0,
            'review_count': 0,
            'image_url': imageUrl,
            if (providerMemberId != null) 'provider_id': providerMemberId,
            'active': true,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .select('id');

      if (inserted.isNotEmpty) {
        final newId = inserted.first['id'] as String;
        final rows = await SupabaseFetchers.selectAll(
          'marketplace_services',
          eq: {'id': newId},
          limit: 1,
        );
        if (rows.isNotEmpty) return MarketService.fromJson(rows.first);
      }
      throw const ServerException('Service créé mais impossible de le recharger.');
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de créer le service.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Récupère tous les services actifs, triés par note décroissante.
  Future<List<MarketService>> fetchAll() async {
    try {
      final rows = await SupabaseFetchers.selectAll(
        'marketplace_services',
        orderBy: 'rating',
        ascending: false,
      );
      return rows.map(MarketService.fromJson).toList(growable: false);
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger les services.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Récupère les services marketplace proposés par un membre spécifique.
  ///
  /// La table `marketplace_services` possède une FK `provider_id` vers
  /// `members(id)`. Si aucun service n'est trouvé, retourne une liste vide.
  Future<List<MarketService>> fetchByProviderId(String memberId) async {
    try {
      final rows = await SupabaseFetchers.selectAll(
        'marketplace_services',
        eq: {'provider_id': memberId},
        orderBy: 'rating',
        ascending: false,
      );
      return rows.map(MarketService.fromJson).toList(growable: false);
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger les services du membre.',
        cause: e,
        stackTrace: st,
      );
    }
  }
}
