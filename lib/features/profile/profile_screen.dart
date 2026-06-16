// ignore_for_file: prefer_const_constructors, prefer_const_constructors_in_immutables, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../core/auth/auth_service.dart';
import '../../core/data/providers/data_providers.dart';
import '../../core/logging/app_logger.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/helpers/contact_helper.dart';
import 'profile_body.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ProfileScreen — Profil de l'utilisateur connecté
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerWidget {
  ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(currentMemberProvider);
    final statsAsync = ref.watch(currentMemberStatsProvider);

    // ── Not authenticated ──────────────────────────────────────
    if (!auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 48, color: AppColors.outline),
              SizedBox(height: AppSpacing.stackMd),
              Text(
                'Connectez-vous pour voir votre profil',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Loading ────────────────────────────────────────────────
    if (memberAsync.isLoading || statsAsync.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // ── Error ──────────────────────────────────────────────────
    if (memberAsync.hasError || statsAsync.hasError) {
      final error = memberAsync.error ?? statsAsync.error;
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              SizedBox(height: AppSpacing.stackMd),
              Text(
                'Erreur de chargement du profil',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onBackground,
                ),
              ),
              SizedBox(height: AppSpacing.stackSm),
              Text(
                '$error',
                textAlign: TextAlign.center,
                maxLines: 3,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              SizedBox(height: AppSpacing.stackMd),
              FilledButton.icon(
                onPressed: () {
                  ref.invalidate(currentMemberProvider);
                  ref.invalidate(currentMemberStatsProvider);
                },
                icon: Icon(Icons.refresh, size: 16),
                label: Text('Réessayer'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final member = memberAsync.value;
    final stats = statsAsync.value ?? (followerCount: 0, followingCount: 0);

    // ── Member row not yet created (email pending) ────────────
    if (member == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hourglass_empty, size: 48,
                  color: AppColors.onSurfaceVariant),
              SizedBox(height: AppSpacing.stackMd),
              Text(
                'Profil en cours de création',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onBackground,
                ),
              ),
              SizedBox(height: AppSpacing.stackSm),
              Text(
                'Votre profil sera disponible une fois votre email confirmé.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Posts de l'utilisateur ─────────────────────────────────
    final postsAsync = ref.watch(userPostsProvider(member.id));
    final posts = postsAsync.valueOrNull ?? [];

    // ── Services du membre ─────────────────────────────────────
    final servicesAsync = ref.watch(memberServicesProvider(member.id));
    final memberServices = servicesAsync.valueOrNull ?? [];

    // ── Chapitre du membre ─────────────────────────────────────
    final chapterAsync = ref.watch(currentChapterProvider);
    final chapter = chapterAsync.valueOrNull;

    final email = auth.currentUser?.email;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ProfileBody(
        member: member,
        followerCount: stats.followerCount,
        followingCount: stats.followingCount,
        postCount: posts.length,
        posts: posts,
        memberServices: memberServices,
        chapter: chapter,
        email: email,
        isOwnProfile: true,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PublicProfileScreen — Profil public d'un autre membre
// ─────────────────────────────────────────────────────────────────────────────

class PublicProfileScreen extends ConsumerWidget {
  final String memberId;

  PublicProfileScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(memberProvider(memberId));
    final statsAsync = ref.watch(memberStatsProvider(memberId));
    final isFollowingAsync = ref.watch(isFollowingProvider(memberId));
    final postsAsync = ref.watch(userPostsProvider(memberId));

    // ── Loading ────────────────────────────────────────────────
    if (memberAsync.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // ── Error ──────────────────────────────────────────────────
    if (memberAsync.hasError) {
      return _MemberErrorView(
        memberId: memberId,
        error: memberAsync.error.toString(),
      );
    }

    // ── Member not found ───────────────────────────────────────
    if (memberAsync.value == null) {
      return _MemberNotFoundView();
    }

    final member = memberAsync.value!;
    final stats = statsAsync.valueOrNull ?? (followerCount: 0, followingCount: 0);
    final isFollowing = isFollowingAsync.valueOrNull ?? false;
    final posts = postsAsync.valueOrNull ?? [];

    // ── Services du membre ─────────────────────────────────────
    final servicesAsync = ref.watch(memberServicesProvider(memberId));
    final memberServices = servicesAsync.valueOrNull ?? [];

    // ── Chapitre du membre ─────────────────────────────────────
    final chapterAsync = ref.watch(memberChapterProvider(memberId));
    final chapter = chapterAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ProfileBody(
        member: member,
        followerCount: stats.followerCount,
        followingCount: stats.followingCount,
        postCount: posts.length,
        posts: posts,
        memberServices: memberServices,
        chapter: chapter,
        isOwnProfile: false,
        isFollowing: isFollowing,
        onFollowTap: () => _toggleFollow(ref, member.id, isFollowing),
        onMessageTap: () => _contactMember(context, ref, member.id),
      ),
    );
  }

  Future<void> _contactMember(BuildContext context, WidgetRef ref, String memberId) async {
    await ContactHelper.navigateToConversation(context, ref, memberId);
  }

  Future<void> _toggleFollow(WidgetRef ref, String memberId, bool currentlyFollowing) async {
    try {
      final repo = ref.read(membersRepositoryProvider);
      if (currentlyFollowing) {
        await repo.unfollowMember(memberId);
      } else {
        await repo.followMember(memberId);
      }
      ref.invalidate(isFollowingProvider(memberId));
      ref.invalidate(memberStatsProvider(memberId));
      ref.invalidate(currentMemberStatsProvider);
    } on Exception catch (e) {
      log.error('Follow toggle failed', tag: 'profile', error: e);
      // On ne peut pas utiliser context ici car _toggleFollow pourrait
      // être appelée après disposition. Le log suffit pour le debug.
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MemberNotFoundView — Écran élégant "Membre introuvable"
// ─────────────────────────────────────────────────────────────────────────────

class _MemberNotFoundView extends StatelessWidget {
  const _MemberNotFoundView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIcons.arrowLeft,
              size: 22, color: AppColors.onSurfaceVariant),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // ── Decorative background elements ────────────────────
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryFixed.withValues(alpha: 0.3),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondaryFixed.withValues(alpha: 0.25),
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryFixed.withValues(alpha: 0.15),
              ),
            ),
          ),
          // ── Content ───────────────────────────────────────────
          Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Illustration
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryFixed,
                          AppColors.primaryFixed
                              .withValues(alpha: 0.4),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary
                              .withValues(alpha: 0.12),
                          blurRadius: 32,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      PhosphorIcons.userMinus,
                      size: 52,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Title
                  Text(
                    'Membre introuvable',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Subtitle
                  Container(
                    constraints:
                        const BoxConstraints(maxWidth: 320),
                    child: Text(
                      'Ce profil n\'existe pas ou a été supprimé. Il est possible que le lien soit incorrect ou que le compte ait été désactivé.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        height: 1.55,
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Back button
                  SizedBox(
                    width: 200,
                    height: 46,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(PhosphorIcons.arrowLeft,
                          size: 18),
                      label: const Text(
                        'Retour',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MemberErrorView — Écran élégant "Erreur de chargement"
// ─────────────────────────────────────────────────────────────────────────────

class _MemberErrorView extends ConsumerWidget {
  final String memberId;
  final String error;
  const _MemberErrorView({
    required this.memberId,
    required this.error,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawError = error.isNotEmpty && error != 'null'
        ? error
        : 'Une erreur inattendue est survenue lors du chargement.';
    final displayError = rawError.length > 120
        ? '${rawError.substring(0, 120)}…'
        : rawError;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIcons.arrowLeft,
              size: 22, color: AppColors.onSurfaceVariant),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // ── Decorative background elements ────────────────────
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withValues(alpha: 0.04),
              ),
            ),
          ),
          // ── Content ───────────────────────────────────────────
          Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Illustration
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.error.withValues(alpha: 0.08),
                    ),
                    child: const Icon(
                      PhosphorIcons.cloudSlash,
                      size: 48,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Title
                  Text(
                    'Erreur de chargement',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Error detail
                  Container(
                    constraints:
                        const BoxConstraints(maxWidth: 320),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            AppColors.error.withValues(alpha: 0.12),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      displayError,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        height: 1.4,
                        color: AppColors.error.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Actions
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 42,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              Navigator.of(context).pop(),
                          icon: const Icon(PhosphorIcons.arrowLeft,
                              size: 16),
                          label: const Text(
                            'Retour',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                AppColors.onSurfaceVariant,
                            side: BorderSide(
                              color: AppColors.outlineVariant,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 42,
                        child: FilledButton.icon(
                          onPressed: () {
                            ref.invalidate(
                                memberProvider(memberId));
                            ref.invalidate(
                                memberStatsProvider(memberId));
                          },
                          icon: const Icon(PhosphorIcons.arrowClockwise,
                              size: 16),
                          label: const Text(
                            'Réessayer',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
