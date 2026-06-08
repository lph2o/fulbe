import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/data/mock_jobs.dart';
import '../../shared/widgets/fc_card.dart';

class FinancesScreen extends StatelessWidget {
  const FinancesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.95),
        elevation: 0.5,
        centerTitle: true,
        leading: const Padding(
          padding: EdgeInsets.only(left: AppSpacing.marginMobile),
          child: CircleAvatar(
            backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=150&h=150&fit=crop&q=80'),
            radius: 20,
          ),
        ),
        title: Text('Fulɓe Connect',
            style: AppTextStyles.headlineLgMobile
                .copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: AppColors.onSurfaceVariant),
            onPressed: () {},
            padding: const EdgeInsets.only(right: AppSpacing.marginMobile),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.marginMobile, AppSpacing.stackMd,
                AppSpacing.marginMobile, AppSpacing.stackLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mes Finances',
                    style: AppTextStyles.headlineLg
                        .copyWith(color: AppColors.onSurface, fontSize: 28)),
                const SizedBox(height: 2),
                Text('Gérez vos cotisations et contributions.',
                    style: AppTextStyles.bodyMd
                        .copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          // ── Hero Balance Card ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile),
            child: _BalanceHeroCard(),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          // ── Next Due ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile),
            child: _NextDueCard(),
          ),
          const SizedBox(height: AppSpacing.stackLg),
          // ── Community Projects ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile),
            child: Text('Projets Communautaires',
                style: AppTextStyles.headlineLgMobile
                    .copyWith(color: AppColors.onSurface, fontSize: 18)),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          const Padding(
            padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile),
            child: Column(
              children: [
                _ProjectCard(
                  icon: Icons.water_drop_outlined,
                  color: AppColors.tertiaryContainer,
                  title: 'Projet Eau Potable',
                  location: 'Région de Ziguinchor, SN',
                  progress: 0.75,
                  current: 375000,
                  target: 500000,
                  currency: 'FCFA',
                ),
                SizedBox(height: AppSpacing.stackMd),
                _ProjectCard(
                  icon: Icons.school_outlined,
                  color: AppColors.secondaryContainer,
                  title: 'Bourses Universitaires',
                  location: 'Diaspora mondiale',
                  progress: 0.40,
                  current: 200000,
                  target: 500000,
                  currency: 'FCFA',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.stackLg),
          // ── Chart ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile),
            child: Text('Tendances des 7 derniers mois',
                style: AppTextStyles.headlineLgMobile
                    .copyWith(color: AppColors.onSurface, fontSize: 18)),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile),
            child: FcCard(child: _BarChart()),
          ),
          const SizedBox(height: AppSpacing.stackLg),
          // ── Transaction History ────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile),
            child: Text('Historique des Transactions',
                style: AppTextStyles.headlineLgMobile
                    .copyWith(color: AppColors.onSurface, fontSize: 18)),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile),
            child: FcCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: MockFinances.transactions
                    .asMap()
                    .entries
                    .map((e) => Column(
                          children: [
                            _TransactionRow(tx: e.value),
                            if (e.key < MockFinances.transactions.length - 1)
                              Divider(
                                  height: 0,
                                  color: AppColors.outlineVariant
                                      .withValues(alpha: 0.5)),
                          ],
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Balance Hero ─────────────────────────────────────────────────────────────

class _BalanceHeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              child: Opacity(
                opacity: 0.06,
                child: CustomPaint(painter: _GridDotPainter()),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.stackLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('SOLDE GLOBAL',
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.primaryFixedDim,
                          letterSpacing: 2,
                        )),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Color(0xFF86AF99), size: 12),
                          const SizedBox(width: 4),
                          Text('Abonnement Actif',
                              style: AppTextStyles.labelSm.copyWith(
                                  color: AppColors.primaryFixedDim)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackMd),
                Text(
                  '1 250 FCFA',
                  style: AppTextStyles.displayLg.copyWith(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Mis à jour aujourd\'hui',
                    style: AppTextStyles.labelSm
                        .copyWith(color: AppColors.primaryFixedDim)),
                const SizedBox(height: AppSpacing.stackLg),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Payer maintenant'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryContainer,
                          foregroundColor: AppColors.onSecondaryContainer,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          textStyle: AppTextStyles.labelMd
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.stackSm),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Icon(Icons.history,
                          color: Colors.white, size: 20),
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

class _NextDueCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FcCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Icon(Icons.schedule,
                color: AppColors.secondary, size: 22),
          ),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prochaine Échéance',
                    style: AppTextStyles.labelSm
                        .copyWith(color: AppColors.onSurfaceVariant)),
                Text(MockFinances.nextDueLabel,
                    style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700)),
                Text('15 Oct 2024',
                    style: AppTextStyles.labelSm
                        .copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('50 FCFA',
                  style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 18)),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('Payer →',
                    style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.primaryContainer,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Project Card ─────────────────────────────────────────────────────────────

class _ProjectCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String location;
  final double progress;
  final int current;
  final int target;
  final String currency;

  const _ProjectCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.location,
    required this.progress,
    required this.current,
    required this.target,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return FcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, size: 20,
                    color: AppColors.onSecondaryContainer),
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTextStyles.labelMd.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w700)),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 11, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 2),
                        Text(location,
                            style: AppTextStyles.labelSm
                                .copyWith(color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ),
              Text('$pct%',
                  style: AppTextStyles.headlineLgMobile.copyWith(
                      color: AppColors.primaryContainer,
                      fontWeight: FontWeight.w800,
                      fontSize: 22)),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.primaryContainer),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$current $currency collectés',
                  style: AppTextStyles.labelSm
                      .copyWith(color: AppColors.onSurfaceVariant)),
              Text('Objectif : $target $currency',
                  style: AppTextStyles.labelSm
                      .copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Bar Chart ─────────────────────────────────────────────────────────────────

class _BarChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final maxVal = MockFinances.chartData
        .reduce((a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Paiements mensuels (FCFA)',
            style: AppTextStyles.labelSm
                .copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: AppSpacing.stackLg),
        SizedBox(
          height: 100,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: MockFinances.chartData.asMap().entries.map((e) {
              final ratio = e.value / maxVal;
              final isMax = e.value == maxVal;
              return Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isMax)
                        Text(
                          '${e.value.round()}',
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.primaryContainer,
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                          ),
                        ),
                      const SizedBox(height: 2),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        height: 90 * ratio,
                        decoration: BoxDecoration(
                          // Fix: use primary-container color (not tertiary blue)
                          color: isMax
                              ? AppColors.primaryContainer
                              : AppColors.primaryFixed,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: MockFinances.chartMonths.map((m) {
            return Expanded(
              child: Text(m,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 9,
                  )),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Transaction Row ───────────────────────────────────────────────────────────

class _TransactionRow extends StatelessWidget {
  final Transaction tx;
  const _TransactionRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Icon(Icons.remove,
                size: 20, color: AppColors.error),
          ),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.label,
                    style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600)),
                Text(tx.date,
                    style: AppTextStyles.labelSm
                        .copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          Text(
            '${tx.amount < 0 ? '-' : '+'}${tx.amount.abs().round()} FCFA',
            style: AppTextStyles.labelMd.copyWith(
              color: tx.amount < 0 ? AppColors.error : AppColors.primaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GridDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    const spacing = 24.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
