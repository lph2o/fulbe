/// Modèles Member et MemberCluster (utilisés par Directory et World Map).
///
/// Source de vérité : tables Supabase `members` et `member_clusters`.
library;

import 'package:meta/meta.dart';

import '../parsers.dart';

/// Membre de la communauté (annuaire professionnel).
@immutable
class Member {
  const Member({
    required this.id,
    required this.name,
    required this.profession,
    required this.city,
    required this.country,
    this.avatarUrl,
    this.coverUrl,
    this.initials,
    this.isVerified = false,
    this.skills = const [],
    this.linkedIn,
    this.bio,
    this.createdAt,
  });

  final String id;
  final String name;
  final String profession;
  final String city;
  final String country;
  final String? avatarUrl;
  final String? coverUrl;
  final String? initials;
  final bool isVerified;
  final List<String> skills;
  final String? linkedIn;
  final String? bio;
  final DateTime? createdAt;

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: Parsers.string(json, 'id', fallback: Parsers.string(json, 'member_id')),
      name: Parsers.string(json, 'name', fallback: Parsers.string(json, 'full_name')),
      profession: Parsers.string(json, 'profession'),
      city: Parsers.string(json, 'city'),
      country: Parsers.string(json, 'country'),
      avatarUrl: Parsers.nullableString(json, 'avatar_url') ??
          Parsers.nullableString(json, 'avatarUrl'),
      coverUrl: Parsers.nullableString(json, 'cover_url') ??
          Parsers.nullableString(json, 'coverUrl'),
      initials: Parsers.nullableString(json, 'initials'),
      isVerified: Parsers.boolean(json, 'is_verified', fallback: Parsers.boolean(json, 'isVerified')),
      skills: Parsers.stringList(json, 'skills'),
      linkedIn: Parsers.nullableString(json, 'linkedin') ??
          Parsers.nullableString(json, 'linkedIn'),
      bio: Parsers.nullableString(json, 'bio'),
      createdAt: Parsers.nullableDateTime(json, 'created_at') ??
          Parsers.nullableDateTime(json, 'createdAt'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'profession': profession,
        'city': city,
        'country': country,
        'avatar_url': avatarUrl,
        'cover_url': coverUrl,
        'initials': initials,
        'is_verified': isVerified,
        'skills': skills,
        'linkedin': linkedIn,
        'bio': bio,
        'created_at': createdAt?.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Member &&
          other.id == id &&
          other.name == name &&
          other.profession == profession &&
          other.city == city &&
          other.country == country &&
          other.avatarUrl == avatarUrl &&
          other.coverUrl == coverUrl &&
          other.initials == initials &&
          other.isVerified == isVerified &&
          listEquals(other.skills, skills) &&
          other.linkedIn == linkedIn &&
          other.bio == bio &&
          other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        profession,
        city,
        country,
        avatarUrl,
        coverUrl,
        initials,
        isVerified,
        Object.hashAll(skills),
        linkedIn,
        bio,
        createdAt,
      );
}

/// Cluster géographique affiché sur la World Map.
@immutable
class MemberCluster {
  const MemberCluster({
    required this.id,
    required this.name,
    required this.country,
    required this.count,
    required this.latPercent,
    required this.lngPercent,
  });

  final String id;
  final String name;
  final String country;
  final int count;
  final double latPercent; // 0..1 de la hauteur de la map
  final double lngPercent; // 0..1 de la largeur de la map

  factory MemberCluster.fromJson(Map<String, dynamic> json) {
    return MemberCluster(
      id: Parsers.string(json, 'id'),
      name: Parsers.string(json, 'name'),
      country: Parsers.string(json, 'country'),
      count: Parsers.integer(json, 'count'),
      latPercent: Parsers.doubleValue(json, 'lat_pct',
          fallback: Parsers.doubleValue(json, 'latPercent')),
      lngPercent: Parsers.doubleValue(json, 'lng_pct',
          fallback: Parsers.doubleValue(json, 'lngPercent')),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'country': country,
        'count': count,
        'lat_pct': latPercent,
        'lng_pct': lngPercent,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemberCluster &&
          other.id == id &&
          other.name == name &&
          other.country == country &&
          other.count == count &&
          other.latPercent == latPercent &&
          other.lngPercent == lngPercent;

  @override
  int get hashCode =>
      Object.hash(id, name, country, count, latPercent, lngPercent);
}

/// Helper local (équivalent à `listEquals` de `package:flutter/foundation`).
bool listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
