import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Helper générique pour les requêtes Supabase PostgREST.
///
/// Centralise les accès `select` pour éviter la duplication de
/// `Supabase.instance.client.from(...)` dans chaque repository.
///
/// Pour les requêtes complexes (embeds, insert, update), les repositories
/// utilisent directement `Supabase.instance.client`.
class SupabaseFetchers {
  static sb.SupabaseClient get client => sb.Supabase.instance.client;

  /// Effectue un `SELECT` sur [table] et retourne les lignes décodées.
  ///
  /// Paramètres optionnels :
  /// - [columns] : colonnes à sélectionner (défaut: `'*'`)
  /// - [limit] : nombre max de lignes
  /// - [orderBy] : colonne de tri
  /// - [ascending] : sens du tri (défaut: décroissant)
  /// - [eq] : filtres égalité sous forme `{colonne: valeur}`
  static Future<List<Map<String, dynamic>>> selectAll(
    String table, {
    String? columns,
    int? limit,
    String? orderBy,
    bool ascending = false,
    Map<String, dynamic>? eq,
  }) async {
    // Note : on utilise dynamic car la chaîne de builders PostgREST alterne
    // entre PostgrestFilterBuilder (.eq) et PostgrestTransformBuilder (.order, .limit).
    dynamic query = client.from(table).select(columns ?? '*');

    // Filtres d'égalité
    if (eq != null) {
      for (final entry in eq.entries) {
        query = query.eq(entry.key, entry.value);
      }
    }

    // Tri
    if (orderBy != null) {
      query = query.order(orderBy, ascending: ascending);
    }

    // Limite
    if (limit != null) {
      query = query.limit(limit);
    }

    final response = await query;

    final data = response as List<dynamic>;
    return data
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }
}

