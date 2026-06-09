/// Model representing a community event in Fulɓe Connect.
class Event {
  final String id;
  final String title;
  final DateTime date;
  final String location;
  final String category; // e.g. Conférence, Festival, Webinaire, Réunion
  final String description;
  final String imageUrl;
  final int attendeeCount;
  final bool isRsvped;

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
  });

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
    );
  }
}

abstract class MockEvents {
  static final List<Event> all = [
    Event(
      id: 'e1',
      title: 'Conférence Annuelle de la Diaspora Fulɓe',
      date: DateTime(2026, 07, 15, 14, 0),
      location: 'Maison de la Mutualité, Paris, France',
      category: 'Conférence',
      description: 'Un rassemblement de leaders d\'opinion, d\'entrepreneurs et d\'universitaires pour discuter du rôle de la diaspora dans le codéveloppement économique et culturel.',
      imageUrl: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=600&fit=crop&q=80',
      attendeeCount: 342,
    ),
    Event(
      id: 'e2',
      title: 'Grand Festival de la Culture Peule (Fouta Toro)',
      date: DateTime(2026, 08, 05, 10, 0),
      location: 'Podor, Région de Saint-Louis, Sénégal',
      category: 'Festival',
      description: 'Célébration annuelle de la musique, de la danse, de la poésie et de l\'artisanat traditionnel Peul le long du fleuve Sénégal. Invités d\'honneur de toute la sous-région.',
      imageUrl: 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=600&fit=crop&q=80',
      attendeeCount: 1250,
    ),
    Event(
      id: 'e3',
      title: 'Webinaire : Clés de la réussite dans l\'Agro-Tech',
      date: DateTime(2026, 06, 28, 18, 30),
      location: 'Virtuel (Lien Zoom fourni à l\'inscription)',
      category: 'Webinaire',
      description: 'Découvrez comment les technologies modernes peuvent améliorer la productivité pastorale et agricole. Présenté par des experts du domaine.',
      imageUrl: 'https://images.unsplash.com/photo-1530595467537-0b5996c41f2d?w=600&fit=crop&q=80',
      attendeeCount: 95,
    ),
    Event(
      id: 'e4',
      title: 'Rencontre Réseau & Networking Local',
      date: DateTime(2026, 06, 20, 19, 0),
      location: 'Espace Rive Gauche, Bruxelles, Belgique',
      category: 'Réunion',
      description: 'Une soirée informelle de réseautage pour faire connaissance avec les nouveaux professionnels arrivés dans la région de Bruxelles.',
      imageUrl: 'https://images.unsplash.com/photo-1511578314322-379afb476865?w=600&fit=crop&q=80',
      attendeeCount: 45,
    ),
    Event(
      id: 'e5',
      title: 'Atelier de Poésie et Littérature Pulaar',
      date: DateTime(2026, 07, 02, 15, 0),
      location: 'Bibliothèque Nationale, Conakry, Guinée',
      category: 'Réunion',
      description: 'Une séance de lecture collective de poèmes traditionnels et modernes Pulaar, suivie d\'un atelier d\'écriture créative ouvert à tous.',
      imageUrl: 'https://images.unsplash.com/photo-1506880018603-83d5b814b5a6?w=600&fit=crop&q=80',
      attendeeCount: 30,
    ),
  ];
}
