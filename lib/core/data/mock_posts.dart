/// Mock post data for the home feed.
class Post {
  final String id;
  final String authorName;
  final String authorCity;
  final String authorCountry;
  final String? authorAvatarUrl;
  final String content;
  final String? imageUrl;
  final int likesCount;
  final int commentsCount;
  final String timeAgo;

  const Post({
    required this.id,
    required this.authorName,
    required this.authorCity,
    required this.authorCountry,
    this.authorAvatarUrl,
    required this.content,
    this.imageUrl,
    required this.likesCount,
    required this.commentsCount,
    required this.timeAgo,
  });
}

abstract class MockPosts {
  static const List<Post> all = [
    Post(
      id: 'p1',
      authorName: 'Amadou Diallo',
      authorCity: 'Milan',
      authorCountry: 'Italie',
      authorAvatarUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&q=80',
      content:
          'Incroyablement fier de présenter mon dernier projet architectural intégrant des motifs géométriques Peuls traditionnels avec des matériaux durables modernes. Les retours de la communauté sont très positifs. 🏗️✨',
      imageUrl:
          'https://images.unsplash.com/photo-1486325212027-8081e485255e?w=800&q=80',
      likesCount: 124,
      commentsCount: 18,
      timeAgo: 'Il y a 2h',
    ),
    Post(
      id: 'p2',
      authorName: 'Fatou Barry',
      authorCity: 'Dakar',
      authorCountry: 'Sénégal',
      authorAvatarUrl:
          'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=150&h=150&fit=crop&q=80',
      content:
          'Vient de terminer une incroyable table ronde sur l\'entrepreneuriat tech en Afrique francophone. Les talents et l\'innovation dans notre communauté sont vraiment inspirants ! #FulbeTech #Innovation',
      imageUrl: null,
      likesCount: 89,
      commentsCount: 5,
      timeAgo: 'Il y a 5h',
    ),
    Post(
      id: 'p3',
      authorName: 'Dr. Aïssatou Sow',
      authorCity: 'Paris',
      authorCountry: 'France',
      authorAvatarUrl:
          'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=150&h=150&fit=crop&q=80',
      content:
          'Nouvelle publication sur la médecine préventive dans les communautés diasporiques. L\'accès aux soins de santé reste un défi majeur. Travaillons ensemble pour créer des solutions. 🏥💚',
      imageUrl:
          'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=800&q=80',
      likesCount: 203,
      commentsCount: 31,
      timeAgo: 'Il y a 1j',
    ),
  ];
}

/// Announcement card data
class Announcement {
  final String id;
  final String chipLabel;
  final String chipIcon;
  final String title;
  final String description;
  final String ctaLabel;

  const Announcement({
    required this.id,
    required this.chipLabel,
    required this.chipIcon,
    required this.title,
    required this.description,
    required this.ctaLabel,
  });
}

abstract class MockAnnouncements {
  static const List<Announcement> all = [
    Announcement(
      id: 'a1',
      chipLabel: 'Événement à venir',
      chipIcon: 'event',
      title: 'Rencontre Annuelle de la Diaspora',
      description:
          'Rejoignez-nous à Paris pour un weekend d\'échanges culturels, de networking et de célébration.',
      ctaLabel: 'RSVP maintenant',
    ),
    Announcement(
      id: 'a2',
      chipLabel: 'Nouvelle ressource',
      chipIcon: 'school',
      title: 'Cours de Pulaar Niveau 2',
      description:
          'Améliorez vos compétences conversationnelles avec nos nouveaux modules interactifs.',
      ctaLabel: 'Commencer',
    ),
  ];
}
