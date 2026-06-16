/// Modèle de transaction financière.
///
/// Source de vérité : table Supabase `transactions`.
library;

import 'package:meta/meta.dart';

import '../parsers.dart';

/// Transaction financière (cotisation, donation, abonnement).
@immutable
class Transaction {
  const Transaction({
    required this.id,
    required this.label,
    required this.date,
    required this.method,
    required this.amount,
    required this.icon,
  });

  final String id;
  final String label;
  final String date;
  final String method;
  final double amount; // négatif = débit, positif = crédit
  final String icon;

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: Parsers.string(json, 'id', fallback: Parsers.string(json, 'tx_id')),
      label: Parsers.string(json, 'label'),
      date: Parsers.string(json, 'date'),
      method: Parsers.string(json, 'method'),
      amount: Parsers.doubleValue(json, 'amount'),
      icon: Parsers.string(json, 'icon'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'date': date,
        'method': method,
        'amount': amount,
        'icon': icon,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction &&
          other.id == id &&
          other.label == label &&
          other.amount == amount;

  @override
  int get hashCode => Object.hash(id, label, amount);
}
