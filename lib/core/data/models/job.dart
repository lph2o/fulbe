/// Modèle d'offre d'emploi.
///
/// Source de vérité : table Supabase `jobs`.
library;

import 'package:meta/meta.dart';

import '../parsers.dart';

/// Offre d'emploi publiée dans la communauté.
@immutable
class Job {
  const Job({
    required this.id,
    required this.title,
    required this.company,
    this.companyLogoUrl,
    this.companyInitials,
    required this.location,
    required this.type,
    required this.domain,
    required this.postedAgo,
    this.badge,
    this.badgeType,
  });

  final String id;
  final String title;
  final String company;
  final String? companyLogoUrl;
  final String? companyInitials;
  final String location;
  final String type; // Full-time, Contract, Internship, Mission Freelance
  final String domain;
  final String postedAgo;
  final String? badge;
  final String? badgeType; // 'alumni', 'partner', 'student'

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: Parsers.string(json, 'id', fallback: Parsers.string(json, 'job_id')),
      title: Parsers.string(json, 'title'),
      company: Parsers.string(json, 'company'),
      companyLogoUrl: Parsers.nullableString(json, 'company_logo_url') ??
          Parsers.nullableString(json, 'companyLogoUrl'),
      companyInitials: Parsers.nullableString(json, 'company_initials') ??
          Parsers.nullableString(json, 'companyInitials'),
      location: Parsers.string(json, 'location'),
      type: Parsers.string(json, 'type'),
      domain: Parsers.string(json, 'domain'),
      postedAgo: Parsers.string(json, 'posted_ago', fallback: Parsers.string(json, 'postedAgo')),
      badge: Parsers.nullableString(json, 'badge') ??
          Parsers.nullableString(json, 'badge_label'),
      badgeType: Parsers.nullableString(json, 'badge_type') ??
          Parsers.nullableString(json, 'badgeType'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'company': company,
        'company_logo_url': companyLogoUrl,
        'company_initials': companyInitials,
        'location': location,
        'type': type,
        'domain': domain,
        'posted_ago': postedAgo,
        'badge': badge,
        'badge_type': badgeType,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Job &&
        other.id == id &&
        other.title == title &&
        other.company == company &&
        other.companyLogoUrl == companyLogoUrl &&
        other.companyInitials == companyInitials &&
        other.location == location &&
        other.type == type &&
        other.domain == domain &&
        other.postedAgo == postedAgo &&
        other.badge == badge &&
        other.badgeType == badgeType;
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        company,
        companyLogoUrl,
        companyInitials,
        location,
        type,
        domain,
        postedAgo,
        badge,
        badgeType,
      );
}
