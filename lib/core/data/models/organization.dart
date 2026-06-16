/// Modèle d'organisation (association parente d'un pays).
///
/// Exemples : "Dental Fulbe Italia", "Confédération Fulɓe France".
/// Source de vérité : table Supabase `organizations`.
library;

import 'package:meta/meta.dart';

import '../parsers.dart';

/// Association parente couvrant un pays.
@immutable
class Organization {
  const Organization({
    required this.id,
    required this.name,
    required this.country,
    this.description,
    this.status = 'active',
    required this.createdAt,
  });

  final String id;
  final String name;
  final String country;
  final String? description;

  /// `'active'` (visible publiquement) ou `'pending'` (modération admin).
  final String status;

  final DateTime createdAt;

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: Parsers.string(json, 'id'),
      name: Parsers.string(json, 'name'),
      country: Parsers.string(json, 'country'),
      description: Parsers.nullableString(json, 'description'),
      status: Parsers.string(json, 'status', fallback: 'active'),
      createdAt: Parsers.dateTime(json, 'created_at'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'country': country,
        'description': description,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Organization && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}
