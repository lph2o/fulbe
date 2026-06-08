import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/data/mock_services.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../../shared/widgets/fc_card.dart';
import '../../shared/widgets/fc_chip.dart';
import '../../shared/widgets/fc_search_bar.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  int _selectedCategory = 0;

  List<MarketService> get _filtered {
    if (_selectedCategory == 0) return MockServices.all;
    final cat = MockServices.categories[_selectedCategory];
    return MockServices.all.where((s) => s.category == cat).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.marginMobile,
              AppSpacing.stackMd,
              AppSpacing.marginMobile,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Marketplace',
                    style: AppTextStyles.headlineLg.copyWith(
                        color: AppColors.onSurface, fontSize: 28)),
                const SizedBox(height: 2),
                Text(
                  'Trouvez des services au sein de la communauté.',
                  style: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.stackMd),
                const FcSearchBar(
                    placeholder: 'Rechercher un service...',
                    showFilterButton: true),
                const SizedBox(height: AppSpacing.stackMd),
              ],
            ),
          ),
          FcChipRow(
            labels: MockServices.categories,
            onSelectionChanged: (i) =>
                setState(() => _selectedCategory = i),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(
                left: AppSpacing.marginMobile,
                right: AppSpacing.marginMobile,
                bottom: AppSpacing.bottomNavHeight + AppSpacing.stackMd,
              ),
              itemCount: _filtered.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.stackMd),
              itemBuilder: (_, i) =>
                  _ServiceCard(service: _filtered[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final MarketService service;
  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return FcCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero image
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusLg)),
                child: AspectRatio(
                  aspectRatio: 16 / 8,
                  child: service.imageUrl != null
                      ? Image.network(service.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                                color: AppColors.surfaceContainerHigh,
                              ))
                      : Container(color: AppColors.surfaceContainerHigh),
                ),
              ),
              // Category chip
              Positioned(
                top: AppSpacing.stackMd,
                left: AppSpacing.stackMd,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.label_outline,
                          size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(service.category,
                          style: AppTextStyles.labelSm
                              .copyWith(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.stackMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.title,
                    style: AppTextStyles.headlineLgMobile.copyWith(
                        color: AppColors.onSurface, fontSize: 17)),
                const SizedBox(height: AppSpacing.unit),
                Text(
                  service.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.onSurfaceVariant, fontSize: 14),
                ),
                const SizedBox(height: AppSpacing.stackMd),
                Row(
                  children: [
                    // Stars
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < service.rating.round()
                                ? Icons.star
                                : Icons.star_border,
                            size: 14,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${service.rating} (${service.reviewCount} avis)',
                          style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(service.priceLabel,
                            style: AppTextStyles.labelSm.copyWith(
                                color: AppColors.onSurfaceVariant)),
                        Text(service.price,
                            style: AppTextStyles.labelMd.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            )),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackMd),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: service.ctaLabel.contains('devis')
                        ? const Icon(Icons.mail_outline, size: 16)
                        : const Icon(Icons.arrow_forward, size: 16),
                    label: Text(service.ctaLabel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      textStyle: AppTextStyles.labelMd
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
