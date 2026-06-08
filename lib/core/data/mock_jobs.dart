/// Mock job listings for the Job Board screen.
class Job {
  final String id;
  final String title;
  final String company;
  final String? companyLogoUrl;
  final String? companyInitials;
  final String location;
  final String type; // Full-time, Contract, Freelance
  final String domain;
  final String postedAgo;
  final String? badge;
  final String? badgeType; // 'alumni', 'partner', 'student'

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
}

abstract class MockJobs {
  static const List<Job> all = [
    Job(
      id: 'j1',
      title: 'Senior Frontend Engineer',
      company: 'TechNova Solutions',
      companyInitials: 'TN',
      location: 'Dakar, Sénégal (Hybride)',
      type: 'Full-time',
      domain: 'Tech',
      postedAgo: 'Il y a 2 jours',
      badge: 'Alumni Présent',
      badgeType: 'alumni',
    ),
    Job(
      id: 'j2',
      title: 'Analyste Données Agricoles',
      company: 'Sahel Agri-Tech',
      companyInitials: 'SA',
      location: 'Bamako, Mali (Sur site)',
      type: 'Contract',
      domain: 'Agriculture',
      postedAgo: 'Il y a 5 jours',
      badge: 'Partenaire Communautaire',
      badgeType: 'partner',
    ),
    Job(
      id: 'j3',
      title: 'Consultant Santé Publique',
      company: 'Global Health Initiative',
      companyInitials: 'GH',
      location: 'Remote (Global)',
      type: 'Mission Freelance',
      domain: 'Santé',
      postedAgo: 'Il y a 1 semaine',
      badge: null,
      badgeType: null,
    ),
    Job(
      id: 'j4',
      title: 'Stage Auditeur Financier',
      company: 'Fulani Network Finance',
      companyInitials: 'FN',
      location: 'Conakry, Guinée (Hybride)',
      type: 'Internship',
      domain: 'Finance',
      postedAgo: "Aujourd'hui",
      badge: 'Pour Étudiants',
      badgeType: 'student',
    ),
    Job(
      id: 'j5',
      title: 'Product Designer UX/UI',
      company: 'AfriStart',
      companyInitials: 'AS',
      location: 'Paris, France (Remote)',
      type: 'Full-time',
      domain: 'Design',
      postedAgo: 'Il y a 3 jours',
      badge: null,
      badgeType: null,
    ),
  ];

  static const List<String> roleFilters = [
    'Tous',
    'Full-time',
    'Internships',
    'Freelance',
  ];
  static const List<String> countries = [
    'Tous les pays',
    'Sénégal',
    'France',
    'Guinée',
    'Mali',
    'Italie',
  ];
  static const List<String> domains = [
    'Tous domaines',
    'Tech',
    'Santé',
    'Finance',
    'Agriculture',
    'Design',
  ];
}

/// Mock transaction data for finances screen
class Transaction {
  final String id;
  final String label;
  final String date;
  final String method;
  final double amount;
  final String icon;

  const Transaction({
    required this.id,
    required this.label,
    required this.date,
    required this.method,
    required this.amount,
    required this.icon,
  });
}

abstract class MockFinances {
  static const double globalBalance = 1250.0;
  static const String nextDueDate = '15 Oct 2024';
  static const String nextDueLabel = 'Fonds Communautaire';
  static const double nextDueAmount = 50.0;

  static const List<Transaction> transactions = [
    Transaction(
      id: 't1',
      label: 'Donation Projet Puits',
      date: '10 Sept 2024 • Carte Bancaire',
      method: 'Carte Bancaire',
      amount: -25.0,
      icon: 'water_drop',
    ),
    Transaction(
      id: 't2',
      label: 'Abonnement Annuel',
      date: '01 Jan 2024 • Prélèvement',
      method: 'Prélèvement',
      amount: -100.0,
      icon: 'workspace_premium',
    ),
    Transaction(
      id: 't3',
      label: 'Donation Bourses',
      date: '15 Déc 2023 • Mobile Money',
      method: 'Mobile Money',
      amount: -50.0,
      icon: 'school',
    ),
    Transaction(
      id: 't4',
      label: 'Cotisation Mensuelle',
      date: '01 Nov 2023 • Prélèvement',
      method: 'Prélèvement',
      amount: -20.0,
      icon: 'groups',
    ),
  ];

  static const List<double> chartData = [
    20.0, 35.0, 25.0, 100.0, 50.0, 30.0, 45.0,
  ];
  static const List<String> chartMonths = [
    'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc', 'Jan',
  ];
}
