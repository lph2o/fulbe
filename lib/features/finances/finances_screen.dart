import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/models/community_project.dart';
import '../../core/data/models/transaction.dart';
import '../../core/data/providers/data_providers.dart';
import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../../shared/widgets/fc_card.dart';

class FinancesScreen extends ConsumerWidget {
  const FinancesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSummary = ref.watch(financesSummaryProvider);
    final asyncProjects = ref.watch(projectsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(showBack: true),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(financesSummaryProvider);
          ref.invalidate(projectsProvider);
          await Future.wait([
            ref.read(financesSummaryProvider.future),
            ref.read(projectsProvider.future),
          ]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            // ── Header ────────────────────────────────────────────
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
            // ── Hero Balance Card ──────────────────────────────
            asyncSummary.when(
              data: (summary) => Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.marginMobile),
                child: _BalanceHeroCard(balance: summary.globalBalance),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
                child: _BalanceHeroCard(balance: 0.0),
              ),
              error: (_, __) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
                child: _BalanceHeroCard(balance: 0.0),
              ),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            // ── Next Due ───────────────────────────────────────
            asyncSummary.when(
              data: (summary) => Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.marginMobile),
                child: _NextDueCard(
                  label: summary.nextDueLabel,
                  date: summary.nextDueDate,
                  amount: summary.nextDueAmount,
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            // ── Community Projects ─────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.marginMobile),
              child: Text('Projets Communautaires',
                  style: TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            asyncProjects.when(
              data: (projects) => _ProjectsList(projects: projects),
              loading: () => const _ProjectsLoadingState(),
              error: (e, _) => _ProjectsErrorState(
                message: e is AppException
                    ? e.message
                    : 'Impossible de charger les projets.',
                onRetry: () => ref.invalidate(projectsProvider),
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            // ── Chart ─────────────────────────────────────────
            asyncSummary.when(
              data: (summary) => Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.marginMobile),
                    child: Text('Tendances des 7 derniers mois',
                        style: TextStyle(
                            color: AppColors.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.marginMobile),
                    child: FcCard(
                      child: _BarChart(
                        data: summary.chartData,
                        months: summary.chartMonths,
                      ),
                    ),
                  ),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            // ── Transaction History ──────────────────────────
            asyncSummary.when(
              data: (summary) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.marginMobile),
                    child: Text('Historique des Transactions',
                        style: TextStyle(
                            color: AppColors.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: AppSpacing.stackMd),
                  if (summary.transactions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.marginMobile),
                      child: Text('Aucune transaction pour le moment.',
                          style: TextStyle(color: AppColors.onSurfaceVariant)),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.marginMobile),
                      child: FcCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: summary.transactions
                              .asMap()
                              .entries
                              .map((e) => Column(
                                    children: [
                                      _TransactionRow(tx: e.value),
                                      if (e.key < summary.transactions.length - 1)
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
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.stackLg),
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.stackLg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(PhosphorIcons.cloudSlash,
                          size: 56, color: AppColors.outlineVariant),
                      const SizedBox(height: AppSpacing.stackMd),
                      Text(
                        e is AppException
                            ? e.message
                            : 'Impossible de charger vos finances.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMd
                            .copyWith(color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSpacing.stackMd),
                      FilledButton.tonalIcon(
                        onPressed: () => ref.invalidate(financesSummaryProvider),
                        icon: const Icon(PhosphorIcons.arrowsClockwise, size: 18),
                        label: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Projects List ────────────────────────────────────────────────────────────

class _ProjectsList extends StatelessWidget {
  final List<CommunityProject> projects;
  const _ProjectsList({required this.projects});

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
        child: Text('Aucun projet en cours pour le moment.',
            style: TextStyle(color: AppColors.onSurfaceVariant)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
      child: Column(
        children: projects.map((p) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.stackMd),
            child: _ProjectCard(project: p),
          );
        }).toList(),
      ),
    );
  }
}

class _ProjectsLoadingState extends StatelessWidget {
  const _ProjectsLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
      child: Column(
        children: [
          _ProjectCardSkeleton(),
          SizedBox(height: AppSpacing.stackMd),
          _ProjectCardSkeleton(),
        ],
      ),
    );
  }
}

class _ProjectsErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ProjectsErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
      child: Column(
        children: [
          Text(message,
              style: AppTextStyles.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.stackSm),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(PhosphorIcons.arrowsClockwise, size: 16),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

class _ProjectCardSkeleton extends StatelessWidget {
  const _ProjectCardSkeleton();

  @override
  Widget build(BuildContext context) {
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
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 80,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(4),
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
  final double balance;
  const _BalanceHeroCard({required this.balance});

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
                          const Icon(PhosphorIcons.checkCircleFill,
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
                  '${balance.round()} FCFA',
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
                        icon: const Icon(PhosphorIcons.plus, size: 16),
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
                      child: const Icon(PhosphorIcons.clockCounterClockwise,
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
  final String label;
  final String date;
  final double amount;
  const _NextDueCard({
    required this.label,
    required this.date,
    required this.amount,
  });

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
            child: const Icon(PhosphorIcons.clock,
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
                Text(label,
                    style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700)),
                Text(date,
                    style: AppTextStyles.labelSm
                        .copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${amount.round()} FCFA',
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
  final CommunityProject project;
  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final pct = (project.progress * 100).round();
    final currentInt = project.currentAmount.round();
    final targetInt = project.targetAmount.round();
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
                  color: project.color.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(project.icon, size: 20,
                    color: project.color),
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project.title,
                        style: AppTextStyles.labelMd.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w700)),
                    Row(
                      children: [
                        const Icon(PhosphorIcons.mapPin,
                            size: 11, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 2),
                        Text(project.location,
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
              value: project.progress,
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
              Text('$currentInt ${project.currency} collectés',
                  style: AppTextStyles.labelSm
                      .copyWith(color: AppColors.onSurfaceVariant)),
              Text('Objectif : $targetInt ${project.currency}',
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
  final List<double> data;
  final List<String> months;
  const _BarChart({required this.data, required this.months});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty || months.isEmpty) {
      return const SizedBox.shrink();
    }
    final maxVal = data.reduce((a, b) => a > b ? a : b);
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
            children: data.asMap().entries.map((e) {
              final ratio = maxVal == 0 ? 0.0 : e.value / maxVal;
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
          children: months.map((m) {
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

  IconData get _icon {
    switch (tx.icon) {
      case 'workspace_premium':
        return PhosphorIcons.crownSimple;
      case 'school':
        return PhosphorIcons.graduationCap;
      case 'groups':
        return PhosphorIcons.users;
      case 'water_drop':
        return PhosphorIcons.drop;
      default:
        return tx.amount < 0 ? PhosphorIcons.minus : PhosphorIcons.plus;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDebit = tx.amount < 0;
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
            child: Icon(_icon,
                size: 20,
                color: isDebit ? AppColors.error : AppColors.primaryContainer),
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
                Text('${tx.date} • ${tx.method}',
                    style: AppTextStyles.labelSm
                        .copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          Text(
            '${isDebit ? '-' : '+'}${tx.amount.abs().round()} FCFA',
            style: AppTextStyles.labelMd.copyWith(
              color: isDebit
                  ? AppColors.error
                  : AppColors.primaryContainer,
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
