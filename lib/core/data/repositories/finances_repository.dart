import 'package:intl/intl.dart';

import '../../errors/app_exception.dart';
import '../models/community_project.dart';
import '../models/finances_summary.dart';
import '../models/transaction.dart';
import '../parsers.dart';
import '../supabase_fetchers.dart';

/// Repository d'accès aux finances de l'utilisateur courant.
///
/// Utilise la vue [v_user_finances] qui agrège :
///   - solde global (somme des transactions)
///   - abonnement actif (prochaine échéance)
///   - 20 dernières transactions
class FinancesRepository {
  const FinancesRepository();

  /// Récupère un résumé complet des finances de l'utilisateur connecté.
  ///
  /// Les données de graphique mensuel ne sont pas encore dans la vue.
  Future<FinancesSummary> fetchSummary() async {
    try {
      final authUser = SupabaseFetchers.client.auth.currentUser;
      if (authUser == null) {
        throw const NetworkException(
          'Vous devez être connecté pour voir vos finances.',
        );
      }

      final rows = await SupabaseFetchers.selectAll(
        'v_user_finances',
        limit: 1,
        eq: {'user_id': authUser.id},
      );
      if (rows.isEmpty) {
        // Aucune ligne financière — utilisateur récent ou pas de données.
        return _emptySummary();
      }

      final row = rows.first;

      // ── Solde global ────────────────────────────────────────────
      final balance = Parsers.doubleValue(row, 'balance');

      // ── Abonnement (prochaine échéance) ─────────────────────────
      String nextDueDate = '';
      String nextDueLabel = 'Abonnement';
      double nextDueAmount = 0.0;

      if (row['subscription'] is Map<String, dynamic>) {
        final sub = row['subscription'] as Map<String, dynamic>;
        nextDueLabel = Parsers.string(sub, 'plan', fallback: 'Abonnement');
        nextDueAmount = Parsers.doubleValue(sub, 'amount');
        final nextDueAt = Parsers.nullableDateTime(sub, 'next_due_at');
        if (nextDueAt != null) {
          nextDueDate = DateFormat('dd MMM yyyy', 'fr_FR').format(nextDueAt);
        }
      }

      // ── 20 dernières transactions ───────────────────────────────
      List<Transaction> transactions = [];
      if (row['recent_transactions'] is List) {
        transactions = (row['recent_transactions'] as List)
            .whereType<Map<String, dynamic>>()
            .map(Transaction.fromJson)
            .toList(growable: false);
      }

      // ── Graphique mensuel (via v_user_finances_history) ─────────
      final chartData = <double>[];
      final chartMonths = <String>[];

      try {
        final historyRows = await SupabaseFetchers.selectAll(
          'v_user_finances_history',
          limit: 1,
          eq: {'user_id': authUser.id},
        );

        if (historyRows.isNotEmpty) {
          final histRow = historyRows.first;
          if (histRow['monthly_aggregates'] is List) {
            final aggregates =
                histRow['monthly_aggregates'] as List;
            for (final entry in aggregates) {
              if (entry is Map<String, dynamic>) {
                final year = entry['year'] as int? ?? 0;
                final month = entry['month'] as int? ?? 1;
                final amount = Parsers.doubleValue(entry, 'amount');

                // Construit une date au 1er du mois pour le formatage
                final monthDate = DateTime(year, month);
                chartMonths.add(
                  DateFormat('MMM', 'fr_FR').format(monthDate),
                );
                chartData.add(amount);
              }
            }
          }
        }
      } catch (_) {
        // Vue inexistante, migration non appliquée, ou JSON mal formé
        // → on laisse les listes vides, le _BarChart les masque.
      }

      // Fallback : si la vue n'a rien retourné, données vides
      return FinancesSummary(
        globalBalance: balance,
        nextDueDate: nextDueDate,
        nextDueLabel: nextDueLabel,
        nextDueAmount: nextDueAmount,
        chartData: chartData,
        chartMonths: chartMonths,
        transactions: transactions,
      );
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger vos finances.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Résumé vide pour un utilisateur sans données financières.
  FinancesSummary _emptySummary() {
    return const FinancesSummary(
      globalBalance: 0.0,
      nextDueDate: '',
      nextDueLabel: '',
      nextDueAmount: 0.0,
      chartData: [],
      chartMonths: [],
      transactions: [],
    );
  }

  // ── Projets communautaires ─────────────────────────────────────

  /// Récupère tous les projets communautaires actifs, triés par titre.
  Future<List<CommunityProject>> fetchProjects() async {
    try {
      final rows = await SupabaseFetchers.selectAll(
        'community_projects',
        orderBy: 'title',
        ascending: true,
        eq: {'active': true},
      );
      return rows
          .map((r) => CommunityProject.fromJson(r))
          .toList(growable: false);
    } on AppException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Impossible de charger les projets communautaires.',
        cause: e,
        stackTrace: st,
      );
    }
  }
}

