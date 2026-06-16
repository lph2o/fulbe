/// Modèle de projet communautaire financé par les cotisations.
///
/// Source de vérité : table Supabase `community_projects`.
library;

import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../parsers.dart';

/// Projet communautaire (ex. eau potable, bourses universitaires).
@immutable
class CommunityProject {
  const CommunityProject({
    required this.id,
    required this.title,
    required this.location,
    required this.icon,
    required this.color,
    required this.currentAmount,
    required this.targetAmount,
    required this.currency,
    required this.active,
  });

  final String id;
  final String title;
  final String location;
  final IconData icon;
  final Color color;
  final double currentAmount;
  final double targetAmount;
  final String currency;
  final bool active;

  /// Pourcentage d'avancement (0.0 – 1.0).
  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  factory CommunityProject.fromJson(Map<String, dynamic> json) {
    // Mappe un nom d'icône string (stocké en DB) vers un IconData Flutter.
    IconData mapIcon(String name) {
      switch (name) {
        case 'water_drop':
          return PhosphorIcons.drop;
        case 'school':
          return PhosphorIcons.graduationCap;
        case 'volunteer_activism':
          return PhosphorIcons.heart;
        case 'groups':
          return PhosphorIcons.users;
        case 'handshake':
          return PhosphorIcons.handshake;
        case 'agriculture':
          return PhosphorIcons.plant;
        case 'health_and_safety':
          return PhosphorIcons.firstAid;
        default:
          return PhosphorIcons.heartFill;
      }
    }

    // Parse une couleur hexadécimale (avec ou sans #).
    Color mapColor(String hex) {
      hex = hex.replaceFirst('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    }

    return CommunityProject(
      id: Parsers.string(json, 'id'),
      title: Parsers.string(json, 'title'),
      location: Parsers.string(json, 'location'),
      icon: mapIcon(Parsers.string(json, 'icon', fallback: 'volunteer_activism')),
      color: mapColor(Parsers.string(json, 'color', fallback: '#1B4332')),
      currentAmount: Parsers.doubleValue(json, 'current_amount'),
      targetAmount: Parsers.doubleValue(json, 'target_amount'),
      currency: Parsers.string(json, 'currency', fallback: 'FCFA'),
      active: Parsers.boolean(json, 'active', fallback: true),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommunityProject && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
