/// Mock member data for the Fulɓe Connect directory and map.
class Member {
  final String id;
  final String name;
  final String profession;
  final String city;
  final String country;
  final String? avatarUrl;
  final String? initials;
  final bool isVerified;
  final List<String> skills;
  final String? linkedIn;

  const Member({
    required this.id,
    required this.name,
    required this.profession,
    required this.city,
    required this.country,
    this.avatarUrl,
    this.initials,
    this.isVerified = false,
    this.skills = const [],
    this.linkedIn,
  });
}

/// Geographic cluster for the world map
class MemberCluster {
  final String id;
  final String name;
  final String country;
  final int count;
  final double latPercent; // 0..1 of map height
  final double lngPercent; // 0..1 of map width

  const MemberCluster({
    required this.id,
    required this.name,
    required this.country,
    required this.count,
    required this.latPercent,
    required this.lngPercent,
  });
}

abstract class MockMembers {
  static const List<Member> all = [
    Member(
      id: 'm1',
      name: 'Amadou Diallo',
      profession: 'Senior Full-Stack Developer',
      city: 'Dakar',
      country: 'Sénégal',
      avatarUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&q=80',
      isVerified: true,
      skills: ['Flutter', 'Node.js', 'React', 'PostgreSQL'],
    ),
    Member(
      id: 'm2',
      name: 'Dr. Aïssatou Sow',
      profession: 'Médecin Généraliste',
      city: 'Paris',
      country: 'France',
      avatarUrl:
          'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=150&h=150&fit=crop&q=80',
      isVerified: true,
      skills: ['Médecine interne', 'Pédiatrie', 'Urgences'],
    ),
    Member(
      id: 'm3',
      name: 'Ibrahima Barry',
      profession: 'Entrepreneur Agricole',
      city: 'Conakry',
      country: 'Guinée',
      initials: 'IB',
      skills: ['Agro-business', 'Irrigation', 'Export'],
    ),
    Member(
      id: 'm4',
      name: 'Fatou Barry',
      profession: 'Tech Entrepreneur',
      city: 'Dakar',
      country: 'Sénégal',
      avatarUrl:
          'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=150&h=150&fit=crop&q=80',
      isVerified: true,
      skills: ['FinTech', 'Gestion de projet', 'Fundraising'],
    ),
    Member(
      id: 'm5',
      name: 'Ousmane Baldé',
      profession: 'Avocat International',
      city: 'Bruxelles',
      country: 'Belgique',
      avatarUrl:
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&q=80',
      isVerified: true,
      skills: ['Droit international', 'Arbitrage', 'Immigration'],
    ),
    Member(
      id: 'm6',
      name: 'Mariama Diallo',
      profession: 'Architecte & Designer',
      city: 'Milan',
      country: 'Italie',
      avatarUrl:
          'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150&h=150&fit=crop&q=80',
      skills: ['Architecture', 'Design intérieur', 'AutoCAD'],
    ),
    Member(
      id: 'm7',
      name: 'Moussa Bah',
      profession: 'Chercheur en Économie',
      city: 'Montréal',
      country: 'Canada',
      initials: 'MB',
      skills: ['Économétrie', 'Développement', 'Recherche'],
    ),
    Member(
      id: 'm8',
      name: 'Aaliyah Sow',
      profession: 'UX Designer & Cultural Liaison',
      city: 'Dakar',
      country: 'Sénégal',
      avatarUrl:
          'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=150&h=150&fit=crop&q=80',
      isVerified: true,
      skills: ['UX Design', 'Pulaar Translation', 'Figma', 'Cultural Research'],
    ),
  ];

  static const List<MemberCluster> clusters = [
    MemberCluster(
      id: 'c1',
      name: 'Dakar & Sénégal',
      country: 'Sénégal',
      count: 142,
      latPercent: 0.545, // West Africa latitude
      lngPercent: 0.395, // West Africa longitude
    ),
    MemberCluster(
      id: 'c2',
      name: 'Conakry & Guinée',
      country: 'Guinée',
      count: 86,
      latPercent: 0.57,
      lngPercent: 0.41,
    ),
    MemberCluster(
      id: 'c3',
      name: 'Paris & Île-de-France',
      country: 'France',
      count: 34,
      latPercent: 0.325,
      lngPercent: 0.485,
    ),
    MemberCluster(
      id: 'c4',
      name: 'Milan & Nord Italie',
      country: 'Italie',
      count: 12,
      latPercent: 0.345,
      lngPercent: 0.505,
    ),
    MemberCluster(
      id: 'c5',
      name: 'Bamako & Mali',
      country: 'Mali',
      count: 58,
      latPercent: 0.52,
      lngPercent: 0.43,
    ),
  ];
}
