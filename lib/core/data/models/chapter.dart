/// Modèle de chapitre (branche locale d'une organisation).
///
/// Exemples : "Dental Fulbe Vicenza", "CFF Île-de-France".
/// Source de vérité : table Supabase `chapters`.
///
/// [organizationName] et [organizationCountry] sont peuplés quand le repository
/// fait un `join` sur `organizations` — ils ne sont pas persistés en DB.
library;

import 'package:meta/meta.dart';

import '../parsers.dart';

/// Branche locale d'une organisation, identifiée par (organization_id, city).
@immutable
class Chapter {
  const Chapter({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.city,
    this.description,
    this.status = 'active',
    required this.createdAt,
    this.organizationName,
    this.organizationCountry,
  });

  final String id;
  final String organizationId;
  final String name;
  final String city;
  final String? description;

  /// `'active'` ou `'pending'`.
  final String status;

  final DateTime createdAt;

  /// Nom de l'organisation parente (hydraté via join).
  final String? organizationName;

  /// Pays de l'organisation parente (hydraté via join, pour le filtrage).
  final String? organizationCountry;

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';

  factory Chapter.fromJson(Map<String, dynamic> json) {
    // Support d'un join `organization(*)` PostgREST.
    final org = json['organization'] is Map<String, dynamic>
        ? json['organization'] as Map<String, dynamic>
        : null;

    return Chapter(
      id: Parsers.string(json, 'id'),
      organizationId: Parsers.string(json, 'organization_id'),
      name: Parsers.string(json, 'name'),
      city: Parsers.string(json, 'city'),
      description: Parsers.nullableString(json, 'description'),
      status: Parsers.string(json, 'status', fallback: 'active'),
      createdAt: Parsers.dateTime(json, 'created_at'),
      organizationName:
          org != null ? Parsers.string(org, 'name') : null,
      organizationCountry:
          org != null ? Parsers.string(org, 'country') : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'organization_id': organizationId,
        'name': name,
        'city': city,
        'description': description,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Chapter &&
          other.id == id &&
          other.organizationId == organizationId &&
          other.name == name &&
          other.city == city;

  @override
  int get hashCode => Object.hash(id, organizationId, name, city);
}
