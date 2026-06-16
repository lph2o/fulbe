// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/data/models/member.dart' show Member;
import '../../core/data/providers/data_providers.dart';
import '../../core/errors/app_exception.dart';
import '../../core/navigation/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/post_card.dart' show PostCard;

// ─────────────────────────────────────────────────────────────────────────────
// Shared widget helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget _sectionHeader(String title,
    {String? action, VoidCallback? onAction}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(
        AppSpacing.marginMobile, AppSpacing.stackMd,
        AppSpacing.marginMobile, AppSpacing.stackSm),
    child: Row(
      children: [
        Text(
          title,
          style: AppTextStyles.headlineLgMobile.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const Spacer(),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              action,
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
      ],
    ),
  );
}

// ── Header helpers ─────────────────────────────────────────────────────────

String _greeting(String? name) {
  final hour = DateTime.now().hour;
  final timeGreeting = hour < 17 ? 'Bonjour' : 'Bonsoir';
  if (name != null && name.isNotEmpty) {
    final firstName = name.split(' ').first;
    return '$timeGreeting, $firstName 👋';
  }
  return '$timeGreeting 👋';
}

String _formatCount(int count) {
  if (count == 0) return 'Fulɓe dans le monde';
  final chars = count.toString().split('').reversed.toList();
  final buf = StringBuffer();
  for (var i = 0; i < chars.length; i++) {
    if (i > 0 && i % 3 == 0) buf.write(' ');
    buf.write(chars[i]);
  }
  final formatted = buf.toString().split('').reversed.join();
  return '$formatted+ Fulɓe dans le monde';
}

/// Formatte un entier avec separateur de milliers (espace insécable).
/// "27534" → "27 534"
String _formatNumber(int count) {
  if (count == 0) return '—';
  final chars = count.toString().split('').reversed.toList();
  final buf = StringBuffer();
  for (var i = 0; i < chars.length; i++) {
    if (i > 0 && i % 3 == 0) buf.write(' ');
    buf.write(chars[i]);
  }
  return buf.toString().split('').reversed.join();
}

Widget _headerInitials(Member? member) {
  final letter = (member?.name ?? '?')[0].toUpperCase();
  return Container(
    color: AppColors.secondary,
    child: Center(
      child: Text(
        letter,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    ),
  );
}

/// Avatars initials pour la section professionnels (taille et couleurs adaptees).
Widget _memberInitials(Member member, Color textColor, Color bgColor) {
  final letter = (member.name)[0].toUpperCase();
  return Container(
    color: bgColor,
    child: Center(
      child: Text(
        letter,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// HomeScreen — Premium redesign
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(currentMemberProvider).valueOrNull;
    final asyncPosts = ref.watch(postsProvider);                final posts = asyncPosts.valueOrNull ?? const [];
    final imagePosts = posts.where((p) => p.imageUrls.isNotEmpty).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(postsProvider);
          ref.invalidate(eventsProvider);
          await Future.wait([
            ref.read(postsProvider.future),
            ref.read(eventsProvider.future),
          ]);
        },
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: AppSpacing.stackLg),
          children: [
            // ── 1. Premium Header ──────────────────────────
            _PremiumHeader(
              member: member,
              memberCount: ref.watch(totalMemberCountProvider).whenOrNull(
                    data: (count) => _formatCount(count),
                  ),
            ),
            // ── 2. Hero Card ───────────────────────────────
            _HeroCard(
              memberCount: ref.watch(totalMemberCountProvider).valueOrNull ?? 0,
            ),
            // ── 3. Quick Actions Grid ──────────────────────
            _QuickActionsGrid(),
            // ── 4. Post Composer ───────────────────────────
            _PostComposer(member: member),
            // ── 5. Feed Section — horizontal scrollable ──────
            _sectionHeader(
              "Fil d'actualité",
              action: 'Voir tout',
              onAction: () => Navigator.pushNamed(context, AppRoutes.feed),
            ),
            asyncPosts.when(
              data: (_) {
                if (imagePosts.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.marginMobile,
                      vertical: AppSpacing.stackLg,
                    ),
                    child: Text(
                      'Aucun post avec image pour le moment.',
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  );
                }
                return SizedBox(
                  height: 500,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(
                      left: AppSpacing.marginMobile,
                      right: AppSpacing.marginMobile,
                      bottom: AppSpacing.stackMd,
                    ),
                    itemCount: imagePosts.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final post = imagePosts[i];
                      return SizedBox(
                        width: 300,
                        child: PostCard(post: post, compact: true),
                      );
                    },
                  ),
                );
              },
              loading: () => const _PostsSkeleton(),
              error: (e, _) => _PostsError(
                message: e is AppException
                    ? e.message
                    : 'Impossible de charger le fil d\'actualité.',
                onRetry: () => ref.invalidate(postsProvider),
              ),
            ),
            // ── 6. Events Section ──────────────────────────
            _EventsSection(),
            // ── 7. Professionals Section ────────────────────
            _ProfessionalsSection(),
            // ── 8. Heritage Section ─────────────────────────
            _HeritageSection(),
          ],
        ),
      ),
    );
  }
}

// ── Premium Header ──────────────────────────────────────────────────────────

class _PremiumHeader extends StatelessWidget {
  final Member? member;
  final String? memberCount;
  const _PremiumHeader({required this.member, this.memberCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        left: AppSpacing.marginMobile,
        right: AppSpacing.marginMobile,
        bottom: 8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
      ),
      child: Row(
        children: [
          // Logo
          Image.asset(
            AppConstants.logoAsset,
            width: 32,
            height: 32,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'FC',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Fulɓe / Connect on 2 lines
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Fulɓe',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              Text(
                'Connect',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Greeting — between brand and bell
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _greeting(member?.name),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                memberCount ?? 'Fulɓe dans le monde',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9,
                  fontWeight: FontWeight.w400,
                  color: Color(0xBFFFFFFF),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Notification bell
          _StatusIcon(
            icon: PhosphorIcons.bell,
            showDot: true,
            dotColor: AppColors.secondary,
            onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
          ),
          const SizedBox(width: 10),
          // Avatar — real photo with initials fallback
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4), width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: member?.avatarUrl != null
                  ? Image.network(
                      member!.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _headerInitials(member),
                    )
                  : _headerInitials(member),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final IconData icon;
  final bool showDot;
  final Color dotColor;
  final VoidCallback? onTap;
  const _StatusIcon({
    required this.icon,
    this.showDot = false,
    this.dotColor = AppColors.secondary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          if (showDot)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Hero Card ───────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final int memberCount;
  const _HeroCard({required this.memberCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.marginMobile, 12, AppSpacing.marginMobile, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Decorative circles
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -10,
            left: 40,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label
              const Text(
                'COMMUNAUTÉ MONDIALE',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: Color(0xFFA5D0B9),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Fulɓe Around The World',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              // Stats grid 2 rows × 2 columns
              Column(
                children: [
                  // Row 1: membres + pays (gold)
                  Row(
                    children: [
                      Expanded(
                        child: _HeroStat(
                          value: _formatNumber(memberCount),
                          label: 'membres',
                          isGold: true,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _HeroStat(
                          value: '43',
                          label: 'pays',
                          isGold: true,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  // Row 2: professionnels + entrepreneurs (white)
                  Row(
                    children: [
                      Expanded(
                        child: _HeroStat(
                          value: '8 742',
                          label: 'professionnels',
                          isGold: false,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _HeroStat(
                          value: '2 113',
                          label: 'entrepreneurs',
                          isGold: false,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // CTA button
              GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.directory),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: const Text(
                      'Explorer la communauté  →',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
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

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;
  final bool isGold;
  const _HeroStat({
    required this.value,
    required this.label,
    required this.isGold,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isGold ? AppColors.secondary : Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Actions Grid ──────────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  static const _actions = [
    _QuickAction(
      icon: PhosphorIcons.user,
      label: 'Trouver un pro',
      iconBg: Color(0xFFE8F5EE),
      iconColor: AppColors.primary,
      route: AppRoutes.directory,
    ),
    _QuickAction(
      icon: PhosphorIcons.briefcase,
      label: 'Chercher emploi',
      iconBg: Color(0xFFFBF5E8),
      iconColor: AppColors.secondary,
      route: AppRoutes.jobs,
    ),
    _QuickAction(
      icon: PhosphorIcons.megaphone,
      label: 'Publier annonce',
      iconBg: Color(0xFFE8F0FB),
      iconColor: AppColors.tertiary,
      route: AppRoutes.events,
    ),
    _QuickAction(
      icon: PhosphorIcons.books,
      label: 'Bibliothèque',
      iconBg: AppColors.purpleFixed,
      iconColor: AppColors.purple,
      route: AppRoutes.library,
    ),
    _QuickAction(
      icon: PhosphorIcons.chatsCircle,
      label: 'Discussion',
      iconBg: AppColors.purpleFixedDim,
      iconColor: AppColors.purple,
      route: AppRoutes.messages,
    ),
    _QuickAction(
      icon: PhosphorIcons.storefront,
      label: 'Marketplace',
      iconBg: AppColors.goldFixed,
      iconColor: AppColors.secondary,
      route: AppRoutes.marketplace,
    ),
    _QuickAction(
      icon: PhosphorIcons.currencyDollar,
      label: 'Finances',
      iconBg: AppColors.greenFixed,
      iconColor: AppColors.primary,
      route: AppRoutes.finances,
    ),
    _QuickAction(
      icon: PhosphorIcons.graduationCap,
      label: 'Apprentissage',
      iconBg: AppColors.blueFixed,
      iconColor: AppColors.tertiary,
      route: AppRoutes.learn,
    ),
    _QuickAction(
      icon: PhosphorIcons.globe,
      label: 'Carte du Monde',
      iconBg: AppColors.tealFixed,
      iconColor: AppColors.teal,
      route: AppRoutes.map,
    ),
    _QuickAction(
      icon: PhosphorIcons.usersThree,
      label: 'Communautés',
      iconBg: AppColors.purpleFixed,
      iconColor: AppColors.purple,
      route: AppRoutes.communities,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Stack(
        children: [
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.marginMobile),
              itemCount: _actions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final action = _actions[i];
                return SizedBox(
                  width: 90,
                  child: GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, action.route),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.black.withValues(alpha: 0.07),
                            width: 0.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 24,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: action.iconBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(action.icon,
                                size: 16, color: action.iconColor),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            action.label,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Right-edge scroll hint: gradient fade + chevron
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: 36,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.background.withValues(alpha: 0),
                      AppColors.background.withValues(alpha: 0.85),
                      AppColors.background,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      PhosphorIcons.caretRight,
                      size: 14,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color iconBg;
  final Color iconColor;
  final String route;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.iconBg,
    required this.iconColor,
    required this.route,
  });
}

// ── Post Composer ───────────────────────────────────────────────────────────

class _PostComposer extends ConsumerWidget {
  final Member? member;
  const _PostComposer({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.marginMobile),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Colors.black.withValues(alpha: 0.07), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Input row
          GestureDetector(
            onTap: () async {
              final created = await Navigator.pushNamed(
                  context, AppRoutes.createPost);
              if (created == true && context.mounted) {
                ref.invalidate(postsProvider);
              }
            },
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.secondary,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: member?.avatarUrl != null
                      ? Image.network(
                          member!.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _headerInitials(member),
                        )
                      : _headerInitials(member),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: const Text(
                      'Partage quelque chose avec la communauté...',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Divider
          Container(
            height: 0.5,
            color: const Color(0xFFF0F0F0),
          ),
          const SizedBox(height: 10),
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ComposerAction(
                icon: PhosphorIcons.image,
                label: 'Photo',
                color: AppColors.primary,
                onTap: () async {
                  final created = await Navigator.pushNamed(
                      context, AppRoutes.createPost);
                  if (created == true && context.mounted) {
                    ref.invalidate(postsProvider);
                  }
                },
              ),
              _ComposerAction(
                icon: PhosphorIcons.videoCamera,
                label: 'Vidéo',
                color: AppColors.tertiary,
                onTap: () async {
                  final created = await Navigator.pushNamed(
                      context, AppRoutes.createPost);
                  if (created == true && context.mounted) {
                    ref.invalidate(postsProvider);
                  }
                },
              ),
              _ComposerAction(
                icon: PhosphorIcons.calendar,
                label: 'Événement',
                color: AppColors.secondary,
                onTap: () async {
                  final created = await Navigator.pushNamed(
                      context, AppRoutes.createPost);
                  if (created == true && context.mounted) {
                    ref.invalidate(postsProvider);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComposerAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _ComposerAction({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Events Section ──────────────────────────────────────────────────────────

class _EventsSection extends ConsumerWidget {
  const _EventsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider).valueOrNull ?? [];

    if (events.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'Événements à venir',
          action: 'Voir tout',
          onAction: () => Navigator.pushNamed(context, AppRoutes.events),
        ),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile),
            itemCount: (events.length).clamp(0, 5),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final e = events[i];
              final color = _categoryColor(e.category);
              return SizedBox(
                width: 160,
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(
                      context, AppRoutes.events),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.black.withValues(alpha: 0.07),
                          width: 0.5),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 24,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          height: 72,
                          color: color,
                          child: Center(
                            child: Icon(
                              _eventIcon(e.category),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(PhosphorIcons.mapPin,
                                      size: 10,
                                      color: AppColors.onSurfaceVariant),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Text(
                                      e.location,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _categoryColor(String category) {
    final c = category.toLowerCase();
    if (c.contains('conf') || c.contains('rencontre')) return AppColors.primary;
    if (c.contains('festival') || c.contains('culturel')) return AppColors.secondary;
    if (c.contains('webinaire') || c.contains('tech')) return AppColors.tertiary;
    return AppColors.primary;
  }

  IconData _eventIcon(String category) {
    final c = category.toLowerCase();
    if (c.contains('conf') || c.contains('rencontre')) return PhosphorIcons.users;
    if (c.contains('festival') || c.contains('culturel')) return PhosphorIcons.musicNotes;
    if (c.contains('webinaire') || c.contains('tech')) return PhosphorIcons.monitorPlay;
    return PhosphorIcons.calendar;
  }
}

// ── Professionals Section ───────────────────────────────────────────────────

class _ProfessionalsSection extends ConsumerWidget {
  const _ProfessionalsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(membersProvider).valueOrNull ?? [];

    if (members.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'Professionnels de la semaine',
          action: 'Voir tout',
          onAction: () =>
              Navigator.pushNamed(context, AppRoutes.directory),
        ),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile),
            itemCount: (members.length).clamp(0, 6),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final m = members[i];
              final pastels = [
                const Color(0xFFE8F5EE),
                const Color(0xFFFBF5E8),
                const Color(0xFFE8F0FB),
              ];
              final pastel = pastels[i % pastels.length];
              final accentColors = [
                AppColors.primary,
                AppColors.secondary,
                AppColors.tertiary,
              ];
              final accent = accentColors[i % accentColors.length];

              return SizedBox(
                width: 90,
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(
                      context, AppRoutes.publicProfile,
                      arguments: m.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.black.withValues(alpha: 0.07),
                          width: 0.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 24,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: m.avatarUrl != null
                              ? Image.network(
                                  m.avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _memberInitials(m, accent, pastel),
                                )
                              : _memberInitials(m, accent, pastel),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          m.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          m.profession,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 9,
                            fontWeight: FontWeight.w400,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        if (m.isVerified) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: pastel,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(PhosphorIcons.sealCheck,
                                    size: 8, color: accent),
                                const SizedBox(width: 2),
                                Text(
                                  'Pro',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                    ],
                  ),
                ),
              ),
            );
            },
          ),
        ),
      ],
    );
  }
}

// ── Heritage Section ────────────────────────────────────────────────────────

class _HeritageSection extends StatelessWidget {
  const _HeritageSection();

  static const _items = [
    _HeritageItem(
      title: 'Littérature peule',
      type: 'Livre · 12 min',
      color: Color(0xFF1A1A1A),
      icon: PhosphorIcons.book,
      iconColor: AppColors.secondary,
    ),
    _HeritageItem(
      title: 'Podcast Fulɓe',
      type: 'Podcast · 45 min',
      color: AppColors.primary,
      icon: PhosphorIcons.microphone,
      iconColor: Colors.white,
    ),
    _HeritageItem(
      title: 'Poésie Fulfulde',
      type: 'Poème · 5 min',
      color: AppColors.secondary,
      icon: PhosphorIcons.feather,
      iconColor: Colors.white,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'Patrimoine Fulɓe',
          action: 'Voir tout',
          onAction: () => Navigator.pushNamed(context, AppRoutes.library),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final item = _items[i];
              return SizedBox(
                width: 130,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.black.withValues(alpha: 0.07),
                        width: 0.5),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 24,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 52,
                        color: item.color,
                        child: Center(
                          child: Icon(item.icon,
                              color: item.iconColor, size: 24),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.type,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 9,
                                fontWeight: FontWeight.w400,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HeritageItem {
  final String title;
  final String type;
  final Color color;
  final IconData icon;
  final Color iconColor;
  const _HeritageItem({
    required this.title,
    required this.type,
    required this.color,
    required this.icon,
    required this.iconColor,
  });
}

// ── Skeleton & Error ────────────────────────────────────────────────────────

class _PostsSkeleton extends StatelessWidget {
  const _PostsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.stackLg),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
    );
  }
}

class _PostsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _PostsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        children: [
          const Icon(PhosphorIcons.cloudSlash,
              size: 48, color: AppColors.outlineVariant),
          const SizedBox(height: AppSpacing.stackSm),
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
    );
  }
}
