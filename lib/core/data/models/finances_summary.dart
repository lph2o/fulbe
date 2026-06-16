import 'package:meta/meta.dart';

import 'transaction.dart';

/// Agrégat "Mes Finances" : solde + prochaine échéance + graphique + transactions.
///
/// Les métadonnées statiques (solde, prochain dû, graphique) seront
/// progressivement remplacées par des colonnes de la vue `v_user_finances`.
@immutable
class FinancesSummary {
  const FinancesSummary({
    required this.globalBalance,
    required this.nextDueDate,
    required this.nextDueLabel,
    required this.nextDueAmount,
    required this.chartData,
    required this.chartMonths,
    required this.transactions,
  });

  final double globalBalance;
  final String nextDueDate;
  final String nextDueLabel;
  final double nextDueAmount;
  final List<double> chartData;
  final List<String> chartMonths;
  final List<Transaction> transactions;

  FinancesSummary copyWith({
    double? globalBalance,
    String? nextDueDate,
    String? nextDueLabel,
    double? nextDueAmount,
    List<double>? chartData,
    List<String>? chartMonths,
    List<Transaction>? transactions,
  }) {
    return FinancesSummary(
      globalBalance: globalBalance ?? this.globalBalance,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      nextDueLabel: nextDueLabel ?? this.nextDueLabel,
      nextDueAmount: nextDueAmount ?? this.nextDueAmount,
      chartData: chartData ?? this.chartData,
      chartMonths: chartMonths ?? this.chartMonths,
      transactions: transactions ?? this.transactions,
    );
  }
}
