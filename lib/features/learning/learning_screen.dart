import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/fc_card.dart';

class LearningScreen extends StatelessWidget {
  const LearningScreen({super.key});

  static const _nodes = [
    _LessonNode(id: 1, label: 'AZ', title: 'Alphabet Pulaar',
        state: _NodeState.active, xpGain: 10),
    _LessonNode(id: 2, label: '👋', title: 'Salutations',
        state: _NodeState.locked, xpGain: 15),
    _LessonNode(id: 3, label: '🔢', title: 'Nombres',
        state: _NodeState.locked, xpGain: 20),
    _LessonNode(id: 4, label: '🏠', title: 'Vie quotidienne',
        state: _NodeState.locked, xpGain: 25),
    _LessonNode(id: 5, label: '✅', title: 'Grammaire Basique',
        state: _NodeState.done, xpGain: 30),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.95),
        elevation: 0.5,
        titleSpacing: 0,
        leadingWidth: 60,
        leading: const Padding(
          padding: EdgeInsets.only(left: AppSpacing.marginMobile),
          child: CircleAvatar(
            backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=150&h=150&fit=crop&q=80'),
            radius: 20,
          ),
        ),
        title: Row(
          children: [
            // Streak badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusFull),
                border: Border.all(color: AppColors.secondaryContainer),
              ),
              child: Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text('14 jours',
                      style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.stackSm),
            // Language flag
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusFull),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: const Text('🇬🇳 Pulaar',
                  style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: AppColors.onSurfaceVariant),
            onPressed: () {},
            padding:
                const EdgeInsets.only(right: AppSpacing.marginMobile),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          // ── Stats row ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.marginMobile,
                AppSpacing.stackLg,
                AppSpacing.marginMobile,
                0),
            child: _StatsRow(),
          ),
          const SizedBox(height: AppSpacing.stackLg),
          // ── Unit header ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile),
            child: FcCard(
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: const Icon(Icons.school,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.stackMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Unité 1 : Les Bases',
                            style: AppTextStyles.headlineLgMobile.copyWith(
                                color: AppColors.onSurface, fontSize: 18)),
                        Text(
                            'Maîtrisez l\'alphabet et les expressions essentielles.',
                            style: AppTextStyles.bodyMd.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.stackLg),
          // ── Daily goal progress ────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile),
            child: _DailyGoalCard(),
          ),
          const SizedBox(height: AppSpacing.stackLg),
          // ── Learning path ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(
                left: AppSpacing.marginMobile,
                right: AppSpacing.marginMobile,
                bottom: AppSpacing.stackMd),
            child: Text('Parcours d\'apprentissage',
                style: AppTextStyles.headlineLgMobile
                    .copyWith(color: AppColors.onSurface, fontSize: 18)),
          ),
          const _LearningPath(nodes: _nodes),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final _stats = const [
    _Stat(icon: '🔥', value: '14', label: 'Jours de série'),
    _Stat(icon: '⭐', value: '320', label: 'XP Total'),
    _Stat(icon: '🏆', value: '3', label: 'Leçons finies'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _stats.asMap().entries.map((e) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: e.key == 0 ? 0 : 6,
              right: e.key == 2 ? 0 : 6,
            ),
            child: FcCard(
              child: Column(
                children: [
                  Text(e.value.icon,
                      style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(e.value.value,
                      style: AppTextStyles.headlineLgMobile.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 20)),
                  Text(e.value.label,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelSm
                          .copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Stat {
  final String icon;
  final String value;
  final String label;
  const _Stat({required this.icon, required this.value, required this.label});
}

class _DailyGoalCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('Objectif du jour',
                  style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('2 / 3 leçons',
                  style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.primaryContainer,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: const LinearProgressIndicator(
              value: 2 / 3,
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation(
                  AppColors.secondaryContainer),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 6),
          Text('Encore 1 leçon pour atteindre votre objectif !',
              style: AppTextStyles.labelSm
                  .copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ── Learning Path ─────────────────────────────────────────────────────────────

enum _NodeState { done, active, locked }

class _LessonNode {
  final int id;
  final String label;
  final String title;
  final _NodeState state;
  final int xpGain;
  const _LessonNode(
      {required this.id,
      required this.label,
      required this.title,
      required this.state,
      required this.xpGain});
}

class _LearningPath extends StatelessWidget {
  final List<_LessonNode> nodes;
  const _LearningPath({required this.nodes});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: nodes.asMap().entries.map((e) {
        final isLast = e.key == nodes.length - 1;
        return Column(
          children: [
            _NodeWidget(node: e.value),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: AppColors.outlineVariant,
              ),
          ],
        );
      }).toList(),
    );
  }
}

class _NodeWidget extends StatelessWidget {
  final _LessonNode node;
  const _NodeWidget({required this.node});

  Color get _bgColor {
    switch (node.state) {
      case _NodeState.done:
        return AppColors.primaryFixed;
      case _NodeState.active:
        return AppColors.secondaryContainer;
      case _NodeState.locked:
        return AppColors.surfaceContainerHigh;
    }
  }

  Color get _borderColor {
    switch (node.state) {
      case _NodeState.done:
        return AppColors.primaryContainer;
      case _NodeState.active:
        return AppColors.secondary;
      case _NodeState.locked:
        return AppColors.outlineVariant;
    }
  }

  Color get _textColor {
    switch (node.state) {
      case _NodeState.done:
        return AppColors.primaryContainer;
      case _NodeState.active:
        return AppColors.onSecondaryContainer;
      case _NodeState.locked:
        return AppColors.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.marginMobile),
      child: Row(
        children: [
          // Path connector left spacer
          const SizedBox(width: 48),
          const SizedBox(width: AppSpacing.stackMd),
          // Node circle
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _bgColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: _borderColor, width: 2.5),
                  boxShadow: node.state == _NodeState.active
                      ? [
                          BoxShadow(
                            color: AppColors.secondaryContainer
                                .withValues(alpha: 0.5),
                            blurRadius: 16,
                            spreadRadius: 2,
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: node.state == _NodeState.locked
                      ? const Icon(Icons.lock_outline,
                          color: AppColors.onSurfaceVariant, size: 28)
                      : node.state == _NodeState.done
                          ? const Icon(Icons.check,
                              color: AppColors.primaryContainer, size: 28)
                          : Text(node.label,
                              style: AppTextStyles.headlineLgMobile.copyWith(
                                color: _textColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              )),
                ),
              ),
              // XP tooltip for active node
              if (node.state == _NodeState.active)
                Positioned(
                  top: -28,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text('▶ Start +${node.xpGain} XP',
                          style: AppTextStyles.labelSm.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.stackMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(node.title,
                    style: AppTextStyles.labelMd.copyWith(
                      color: node.state == _NodeState.locked
                          ? AppColors.onSurfaceVariant
                          : AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    )),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      node.state == _NodeState.done
                          ? Icons.check_circle
                          : node.state == _NodeState.active
                              ? Icons.play_circle_outline
                              : Icons.lock_outline,
                      size: 13,
                      color: node.state == _NodeState.done
                          ? AppColors.primaryContainer
                          : node.state == _NodeState.active
                              ? AppColors.secondary
                              : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      node.state == _NodeState.done
                          ? 'Terminé'
                          : node.state == _NodeState.active
                              ? 'En cours'
                              : 'Verrouillé',
                      style: AppTextStyles.labelSm.copyWith(
                        color: node.state == _NodeState.locked
                            ? AppColors.onSurfaceVariant
                            : AppColors.onSurface,
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
