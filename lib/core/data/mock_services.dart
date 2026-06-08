/// Mock services for the Marketplace screen.
class MarketService {
  final String id;
  final String category;
  final String categoryIcon;
  final String title;
  final String description;
  final double rating;
  final int reviewCount;
  final String price;
  final String priceLabel;
  final String ctaLabel;
  final String? imageUrl;

  const MarketService({
    required this.id,
    required this.category,
    required this.categoryIcon,
    required this.title,
    required this.description,
    required this.rating,
    required this.reviewCount,
    required this.price,
    required this.priceLabel,
    required this.ctaLabel,
    this.imageUrl,
  });
}

abstract class MockServices {
  static const List<MarketService> all = [
    MarketService(
      id: 's1',
      category: 'Traduction',
      categoryIcon: 'translate',
      title: 'Traduction Pulaar - Français Professionnelle',
      description:
          'Services de traduction certifiés pour documents administratifs, commerciaux et littéraires. Précision et confidentialité garanties.',
      rating: 4.9,
      reviewCount: 124,
      price: '35k FCFA',
      priceLabel: 'À partir de',
      ctaLabel: 'Réserver',
      imageUrl:
          'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?w=600&q=80',
    ),
    MarketService(
      id: 's2',
      category: 'Dév Web',
      categoryIcon: 'code',
      title: 'Création Site E-commerce Sur Mesure',
      description:
          'Boutiques en ligne performantes, design responsif et intégration de paiements locaux (Mobile Money).',
      rating: 5.0,
      reviewCount: 42,
      price: '250k FCFA',
      priceLabel: 'Forfait',
      ctaLabel: 'Réserver',
      imageUrl:
          'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=600&q=80',
    ),
    MarketService(
      id: 's3',
      category: 'Transport',
      categoryIcon: 'local_shipping',
      title: 'Logistique & Transport Inter-urbain',
      description:
          'Transport sécurisé de marchandises avec suivi GPS en temps réel. Flotte moderne et chauffeurs expérimentés.',
      rating: 4.7,
      reviewCount: 89,
      price: 'Sur devis',
      priceLabel: 'Par trajet',
      ctaLabel: 'Demander devis',
      imageUrl:
          'https://images.unsplash.com/photo-1601584115197-04ecc0da31d7?w=600&q=80',
    ),
    MarketService(
      id: 's4',
      category: 'Immobilier',
      categoryIcon: 'home',
      title: 'Conseil Immobilier Diaspora',
      description:
          'Investissement immobilier au Sénégal et en Guinée pour la diaspora. Accompagnement complet de A à Z.',
      rating: 4.8,
      reviewCount: 56,
      price: '50k FCFA',
      priceLabel: 'Consultation',
      ctaLabel: 'Contacter',
      imageUrl:
          'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=600&q=80',
    ),
  ];

  static const List<String> categories = [
    'Tous',
    'Traduction',
    'Dév Web',
    'Transport',
    'Immobilier',
  ];
}
