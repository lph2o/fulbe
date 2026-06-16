/// Modèle d'événement communautaire.
///
/// Source de vérité : table Supabase `events` (schéma DB défini dans
/// `supabase/migrations/20260609_001_init_schema.sql`).
library;

import 'package:meta/meta.dart';

import '../parsers.dart';

/// Représente un événement de la communauté (conférence, festival, webinaire, etc.).
@immutable
class Event {
  const Event({
    required this.id,
    required this.title,
    required this.date,
    required this.location,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.attendeeCount,
    this.isRsvped = false,
    this.createdBy,
  });

  final String id;
  final String title;
  final DateTime date;
  final String location;
  final String category;
  final String description;
  final String imageUrl;
  final int attendeeCount;
  final bool isRsvped;
  final String? createdBy;

  /// Construit un [Event] depuis une ligne Supabase.
  ///
  /// Accepte les colonnes en snake_case (`image_url`, `attendee_count`, etc.)
  /// ou en camelCase.
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: Parsers.string(json, 'id', fallback: Parsers.string(json, 'event_id')),
      title: Parsers.string(json, 'title'),
      date: Parsers.dateTime(json, 'date',
          fallback: Parsers.nullableDateTime(json, 'start_at') ??
              Parsers.nullableDateTime(json, 'event_date')),
      location: Parsers.string(json, 'location'),
      category: Parsers.string(json, 'category'),
      description: Parsers.string(json, 'description'),
      imageUrl: Parsers.nullableString(json, 'image_url') ?? Parsers.nullableString(json, 'imageUrl') ?? '',
      attendeeCount: Parsers.integer(json, 'attendee_count',
          fallback: Parsers.integer(json, 'attendees')),
      isRsvped: Parsers.boolean(json, 'is_rsvped', fallback: Parsers.boolean(json, 'isRsvped')),
      createdBy: Parsers.nullableString(json, 'created_by') ?? Parsers.nullableString(json, 'createdBy'),
    );
  }

  /// Sérialise pour insertion/update Supabase.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'location': location,
        'category': category,
        'description': description,
        'image_url': imageUrl,
        'attendee_count': attendeeCount,
        'is_rsvped': isRsvped,
        if (createdBy != null) 'created_by': createdBy,
      };

  Event copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? location,
    String? category,
    String? description,
    String? imageUrl,
    int? attendeeCount,
    bool? isRsvped,
    String? createdBy,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      location: location ?? this.location,
      category: category ?? this.category,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      attendeeCount: attendeeCount ?? this.attendeeCount,
      isRsvped: isRsvped ?? this.isRsvped,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Event &&
        other.id == id &&
        other.title == title &&
        other.date == date &&
        other.location == location &&
        other.category == category &&
        other.description == description &&
        other.imageUrl == imageUrl &&
        other.attendeeCount == attendeeCount &&
        other.isRsvped == isRsvped &&
        other.createdBy == createdBy;
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        date,
        location,
        category,
        description,
        imageUrl,
        attendeeCount,
        isRsvped,
        createdBy,
      );

  @override
  String toString() => 'Event(id: $id, title: $title, date: $date)';
}
