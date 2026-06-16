// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/models/service.dart';
import '../../core/data/providers/data_providers.dart';
import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../../shared/widgets/fc_card.dart';
import '../../shared/widgets/fc_chip.dart';
import '../../shared/widgets/fc_search_bar.dart';
import '../../core/navigation/app_router.dart';
import '../../shared/helpers/contact_helper.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  int _selectedCategory = 0;

  static const _categories = [
    'Tous',
    'Traduction',
    'Dév Web',
    'Transport',
    'Immobilier',
  ];

  List<MarketService> _filter(List<MarketService> services) {
    if (_selectedCategory == 0) return services;
    final cat = _categories[_selectedCategory];
    return services.where((s) => s.category == cat).toList();
  }

  @override
  Widget build(BuildContext context) {
    final asyncServices = ref.watch(servicesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(showBack: true),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.of(context)
              .pushNamed(AppRoutes.createService);
          if (created == true && mounted) {
            ref.invalidate(servicesProvider);
          }
        },
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(PhosphorIcons.plus, size: 24),
      ),
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
                Text(
                  'Marketplace',
                  style: AppTextStyles.headlineLg
                      .copyWith(color: AppColors.onSurface, fontSize: 28),
                ),
                const SizedBox(height: 2),
                Text(
                  'Trouvez des services au sein de la communauté.',
                  style: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.stackMd),
                const FcSearchBar(
                  placeholder: 'Rechercher un service...',
                  showFilterButton: true,
                ),
                const SizedBox(height: AppSpacing.stackMd),
              ],
            ),
          ),
          FcChipRow(
            labels: _categories,
            onSelectionChanged: (i) => setState(() => _selectedCategory = i),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Expanded(
            child: asyncServices.when(
              data: (services) {
                final filtered = _filter(services);
                if (filtered.isEmpty) return const _EmptyState();
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(servicesProvider);
                    await ref.read(servicesProvider.future);
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(
                      left: AppSpacing.marginMobile,
                      right: AppSpacing.marginMobile,
                      bottom: AppSpacing.bottomNavHeight + AppSpacing.stackMd,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.stackMd),
                    itemBuilder: (_, i) => _ServiceCard(service: filtered[i]),
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.stackLg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(strokeWidth: 2.4),
                      SizedBox(height: AppSpacing.stackMd),
                      Text('Chargement des services...',
                          style: TextStyle(color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
              error: (e, _) => _ErrorView(
                message: e is AppException
                    ? e.message
                    : 'Impossible de charger les services.',
                onRetry: () => ref.invalidate(servicesProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(PhosphorIcons.storefront,
              size: 64, color: AppColors.outlineVariant),
          const SizedBox(height: AppSpacing.stackMd),
          Text('Aucun service dans cette catégorie.',
              style: AppTextStyles.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.stackLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(PhosphorIcons.cloudSlash,
                size: 56, color: AppColors.outlineVariant),
            const SizedBox(height: AppSpacing.stackMd),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd
                    .copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.stackMd),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(PhosphorIcons.arrowsClockwise, size: 18),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends ConsumerStatefulWidget {
  final MarketService service;
  const _ServiceCard({required this.service});

  @override
  ConsumerState<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends ConsumerState<_ServiceCard> {
  bool _isContacting = false;

  Future<void> _contactProvider() async {
    final service = widget.service;
    if (service.providerId == null) return;
    if (_isContacting) return;
    setState(() => _isContacting = true);
    await ContactHelper.navigateToConversation(context, ref, service.providerId!);
    if (mounted) setState(() => _isContacting = false);
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
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
                  top: Radius.circular(AppSpacing.radiusLg),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 8,
                  child: service.imageUrl != null
                      ? Image.network(
                          service.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: AppColors.surfaceContainerHigh),
                        )
                      : Container(color: AppColors.surfaceContainerHigh),
                ),
              ),
              // Category chip
              Positioned(
                top: AppSpacing.stackMd,
                left: AppSpacing.stackMd,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(PhosphorIcons.tagSimple,
                          size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        service.category,
                        style: AppTextStyles.labelSm.copyWith(color: Colors.white),
                      ),
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
                Text(
                  service.title,
                  style: AppTextStyles.headlineLgMobile.copyWith(
                    color: AppColors.onSurface,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: AppSpacing.unit),
                Text(
                  service.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 14,
                  ),
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
                                ? PhosphorIcons.star
                                : PhosphorIcons.starFill,
                            size: 14,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${service.rating} (${service.reviewCount} avis)',
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          service.priceLabel,
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          service.price,
                          style: AppTextStyles.labelMd.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackMd),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isContacting ? null : _contactProvider,
                    icon: service.ctaLabel.contains('devis')
                        ? const Icon(PhosphorIcons.envelope, size: 16)
                        : const Icon(PhosphorIcons.arrowRight, size: 16),
                    label: Text(service.ctaLabel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
