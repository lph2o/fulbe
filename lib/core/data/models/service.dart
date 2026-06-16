/// Modèle de service marketplace.
///
/// Source de vérité : table Supabase `marketplace_services`.
library;

import 'package:meta/meta.dart';

import '../parsers.dart';

/// Service proposé par un membre de la communauté.
@immutable
class MarketService {
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
    this.providerId,
  });

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

  /// ID du membre fournisseur de ce service.
  final String? providerId;

  factory MarketService.fromJson(Map<String, dynamic> json) {
    return MarketService(
      id: Parsers.string(json, 'id', fallback: Parsers.string(json, 'service_id')),
      category: Parsers.string(json, 'category'),
      categoryIcon: Parsers.string(json, 'category_icon', fallback: Parsers.string(json, 'categoryIcon')),
      title: Parsers.string(json, 'title'),
      description: Parsers.string(json, 'description'),
      rating: Parsers.doubleValue(json, 'rating'),
      reviewCount: Parsers.integer(json, 'review_count', fallback: Parsers.integer(json, 'reviewCount')),
      price: Parsers.string(json, 'price'),
      priceLabel: Parsers.string(json, 'price_label', fallback: Parsers.string(json, 'priceLabel')),
      ctaLabel: Parsers.string(json, 'cta_label', fallback: Parsers.string(json, 'ctaLabel')),
      imageUrl: Parsers.nullableString(json, 'image_url') ?? Parsers.nullableString(json, 'imageUrl'),
      providerId: Parsers.nullableString(json, 'provider_id') ??
          Parsers.nullableString(json, 'providerId'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'category_icon': categoryIcon,
        'title': title,
        'description': description,
        'rating': rating,
        'review_count': reviewCount,
        'price': price,
        'price_label': priceLabel,
        'cta_label': ctaLabel,
        'image_url': imageUrl,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarketService &&
          other.id == id &&
          other.title == title &&
          other.rating == rating;

  @override
  int get hashCode => Object.hash(id, title, rating);
}
