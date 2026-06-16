import '../../errors/app_exception.dart';
import '../models/book.dart';
import '../supabase_fetchers.dart';

/// Repository d'accès à la bibliothèque culturelle (livres).
class LibraryRepository {
  const LibraryRepository();

  /// Récupère tous les livres, triés par date d'ajout décroissante.
  Future<List<Book>> fetchAll() async {
    try {
      final rows = await SupabaseFetchers.selectAll(
        'books',
        orderBy: 'created_at',
        ascending: false,
      );
      return rows.map(Book.fromJson).toList(growable: false);
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger la bibliothèque.',
        cause: e,
        stackTrace: st,
      );
    }
  }
}
