import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/models/book.dart';
import '../../core/data/providers/data_providers.dart';
import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../../shared/widgets/fc_card.dart';
import '../../shared/widgets/fc_chip.dart';
import '../../shared/widgets/fc_search_bar.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _selectedCategory = 0;
  static const _categories = [
    'Tous',
    'Livres Pulaar',
    'Dictionnaires',
    'Histoire',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(showBack: true),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          // Header
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
                  'Bibliothèque',
                  style: AppTextStyles.headlineLg
                      .copyWith(color: AppColors.onSurface, fontSize: 28),
                ),
                const SizedBox(height: 2),
                Text(
                  'Explorez la richesse culturelle Peule.',
                  style: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.stackMd),
                const FcSearchBar(
                  placeholder: 'Rechercher livres, dictionnaires...',
                ),
                const SizedBox(height: AppSpacing.stackMd),
              ],
            ),
          ),

          // Filters
          FcChipRow(
            labels: _categories,
            onSelectionChanged: (i) =>
                setState(() => _selectedCategory = i),
          ),
          const SizedBox(height: AppSpacing.stackLg),

          // ── Hero "Livre du Mois" ───────────────────────────────
          const Padding(
            padding:
                EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
            child: _HeroBookCard(),
          ),
          const SizedBox(height: AppSpacing.stackLg),

          // ── Recently Added ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.marginMobile,
              right: AppSpacing.marginMobile,
              bottom: AppSpacing.stackMd,
            ),
            child: Text(
              'Récemment Ajoutés',
              style: AppTextStyles.headlineLgMobile
                  .copyWith(color: AppColors.onSurface, fontSize: 18),
            ),
          ),

          _HorizontalBookRow(selectedCategoryIndex: _selectedCategory),
          const SizedBox(height: AppSpacing.stackLg),

          // ── Document Inline Preview ─────────────────────────────
          const Padding(
            padding:
                EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
            child: _DocumentPreviewCard(),
          ),
          const SizedBox(height: AppSpacing.stackMd),

          // ── Audio version card ────────────────────────────────────
          const Padding(
            padding:
                EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
            child: _AudioCard(),
          ),
        ],
      ),
    );
  }
}

class _HeroBookCard extends StatelessWidget {
  const _HeroBookCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative pattern
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              child: Opacity(
                opacity: 0.05,
                child: CustomPaint(painter: _DiagonalPatternPainter()),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.stackLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    'LIVRE DU MOIS',
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.onSecondaryContainer,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.stackMd),

                Text(
                  'Tierno Bokar,\nle Sage de Bandiagara',
                  style: AppTextStyles.headlineLgMobile.copyWith(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.stackSm),

                Text(
                  'par Amadou Hampâté Bâ',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.primaryFixedDim,
                  ),
                ),
                const SizedBox(height: AppSpacing.stackSm),

                Text(
                  'Une biographie spirituelle du grand maître soufi de la tradition Peule.',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.primaryFixedDim,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: AppSpacing.stackLg),

                // Progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progression de lecture',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.primaryFixedDim,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 0.32,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.secondaryContainer,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Page 108 / 340 — 32%',
                      style: AppTextStyles.labelSm
                          .copyWith(color: AppColors.primaryFixedDim),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.stackMd),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(PhosphorIcons.books, size: 16),
                        label: const Text('Continuer la lecture'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryContainer,
                          foregroundColor: AppColors.onSecondaryContainer,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          textStyle: AppTextStyles.labelMd.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.stackSm),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Icon(
                        PhosphorIcons.bookmarkSimple,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HorizontalBookRow extends ConsumerWidget {
  final int selectedCategoryIndex;
  const _HorizontalBookRow({required this.selectedCategoryIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBooks = ref.watch(booksProvider);

    return asyncBooks.when(
      data: (books) {
        final filtered = selectedCategoryIndex == 0
            ? books
            : books
                .where((b) => b.categoryIndex == selectedCategoryIndex)
                .toList(growable: false);

        if (filtered.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile),
            child: Text(
              'Aucun livre dans cette catégorie.',
              style: AppTextStyles.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
          );
        }

        return SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
            itemCount: filtered.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppSpacing.stackMd),
            itemBuilder: (_, i) => _BookCover(book: filtered[i]),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 180,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.stackLg),
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      ),
      error: (e, _) => SizedBox(
        height: 180,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
            child: Text(
              e is AppException
                  ? e.message
                  : 'Impossible de charger les livres.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }
}

class _BookCover extends StatelessWidget {
  final Book book;
  const _BookCover({required this.book});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: SizedBox(
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 120,
              height: 140,
              decoration: BoxDecoration(
                color: book.color,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: book.color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(book.emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      book.title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelSm.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              book.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSm
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentPreviewCard extends StatelessWidget {
  const _DocumentPreviewCard();

  @override
  Widget build(BuildContext context) {
    return FcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  PhosphorIcons.fileText,
                  color: AppColors.primaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grammaire Pratique du Pulaar',
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'PDF • 340 pages • Chapitre 3',
                      style: AppTextStyles.labelSm
                          .copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Text(
                'P.12/340',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.primaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.035,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          ...List.generate(
            3,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(4),
                ),
                width: i == 2 ? 200 : double.infinity,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(PhosphorIcons.arrowSquareOut, size: 14),
                  label: const Text('Ouvrir le document'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    textStyle: AppTextStyles.labelSm,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AudioCard extends StatefulWidget {
  const _AudioCard();

  @override
  State<_AudioCard> createState() => _AudioCardState();
}

class _AudioCardState extends State<_AudioCard> {
  bool _isPlaying = false;
  double _progress = 0.28;

  @override
  Widget build(BuildContext context) {
    return FcCard(
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _isPlaying = !_isPlaying),
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? PhosphorIcons.pauseFill : PhosphorIcons.playFill,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        '🎧 Version Audio',
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Tierno Bokar — Chapitre 3',
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Slider(
                  value: _progress,
                  onChanged: (v) => setState(() => _progress = v),
                  activeColor: AppColors.primaryContainer,
                  inactiveColor: AppColors.outlineVariant,
                  thumbColor: AppColors.primaryContainer,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '12:45',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '45:32',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagonalPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (double i = -size.height; i < size.width + size.height; i += 20) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
