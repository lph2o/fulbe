// ignore_for_file: prefer_const_constructors, prefer_const_constructors_in_immutables, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../core/auth/auth_service.dart';
import '../../core/data/models/chapter.dart';
import '../../core/data/models/member.dart';
import '../../core/data/models/post.dart' show Post;
import '../../core/data/models/service.dart' show MarketService;
import '../../core/errors/app_exception.dart';
import '../../core/logging/app_logger.dart';
import '../../core/navigation/app_router.dart' show AppRoutes;
import '../../core/theme/app_colors.dart';
import '../../shared/helpers/profile_share.dart';
import '../../shared/widgets/post_card.dart' show PostCard;
import 'followers_list_screen.dart' show FollowListMode;

// ── Design tokens unifiés avec le HTML de référence ─────────────────────────
const double _avatarSm = 32;
const double _avatarLg = 96;
const Color _borderColor = Color(0x12000000); // rgba(0,0,0,0.07)

// ─────────────────────────────────────────────────────────────────────────────
// ProfileBody — Redesign Premium 2026 (inspiré du HTML de référence)
// ─────────────────────────────────────────────────────────────────────────────

class ProfileBody extends StatelessWidget {
  final Member member;
  final int followerCount;
  final int followingCount;
  final int postCount;
  final List<Post> posts;
  final List<MarketService> memberServices;
  final String? email;
  final Chapter? chapter;
  final bool isOwnProfile;
  final bool isFollowing;

  /// Callbacks pour les actions publiques
  final VoidCallback? onFollowTap;
  final VoidCallback? onMessageTap;

  ProfileBody({
    super.key,
    required this.member,
    required this.followerCount,
    required this.followingCount,
    required this.postCount,
    required this.posts,
    this.memberServices = const [],
    this.email,
    this.chapter,
    this.isOwnProfile = true,
    this.isFollowing = false,
    this.onFollowTap,
    this.onMessageTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── AppBar intégré ─────────────────────────────────
          _buildTopBar(context),

          // ── Hero : cover + avatar + info ───────────────────
          _ProfileHero(
            member: member,
            chapter: chapter,
            email: email,
            isOwnProfile: isOwnProfile,
            isFollowing: isFollowing,
            followerCount: followerCount,
            followingCount: followingCount,
            onFollowTap: onFollowTap,
            onMessageTap: onMessageTap,
          ),

          const SizedBox(height: 16),

          // ── Sections dans le padding ───────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Stats grid
                _StatsCard(
                  postCount: postCount,
                  followerCount: followerCount,
                  followingCount: followingCount,
                  onFollowersTap: () => _openFollowersList(
                      context, FollowListMode.followers),
                  onFollowingTap: () => _openFollowersList(
                      context, FollowListMode.following),
                ),
                const SizedBox(height: 16),

                // Quick link: Mes événements (own profile only)
                if (isOwnProfile) ...[
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.myEvents),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(PhosphorIcons.calendarCheck, size: 18, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Mes événements',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          Icon(PhosphorIcons.arrowRight, size: 16,
                              color: AppColors.primary.withValues(alpha: 0.6)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Quick link: Mes tickets
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.ticketHistory),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryFixed,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.12),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(PhosphorIcons.ticket, size: 18, color: AppColors.secondary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Mes tickets',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                          Icon(PhosphorIcons.arrowRight, size: 16,
                              color: AppColors.secondary.withValues(alpha: 0.6)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Skills
                if (member.skills.isNotEmpty) ...[
                  _SkillsCard(skills: member.skills),
                  const SizedBox(height: 16),
                ],

                // Market Services (FIX 4)
                // Les services sont affichés uniquement si le membre en propose.
                // TODO: connecter `memberServicesProvider` dans la couche
                // state (profile_screen.dart) une fois que le repository
                // `fetchByProviderId` sera alimenté par les vraies données
                // Supabase de la table `marketplace_services`.
                if (memberServices.isNotEmpty) ...[
                  _ServicesCard(services: memberServices),
                  const SizedBox(height: 16),
                ],

                // Activité récente
                _ActivitySection(posts: posts),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Top bar avec logo + actions ───────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          children: [
            // Back button for public profile
            if (!isOwnProfile)
              IconButton(
                icon: Icon(PhosphorIcons.arrowLeft,
                    color: AppColors.onSurfaceVariant, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            // Logo + app name
            if (isOwnProfile) ...[
              Container(
                width: _avatarSm,
                height: _avatarSm,
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    member.initials ?? 'FC',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Fulɓe Connect',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
            const Spacer(),
            // Notifications
            IconButton(
              icon: Icon(PhosphorIcons.bell,
                  color: AppColors.onSurfaceVariant, size: 20),
              onPressed: () {},
            ),
            // Menu (own profile only)
            if (isOwnProfile)
              PopupMenuButton<String>(
                icon: Icon(PhosphorIcons.dotsThreeVertical,
                    color: AppColors.onSurfaceVariant, size: 20),
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: _borderColor),
                ),
                onSelected: (v) {
                  if (v == 'edit') {
                    Navigator.pushNamed(context, AppRoutes.editProfile);
                  } else if (v == 'share') {
                    ProfileShare.share(
                      memberName: member.name,
                      memberId: member.id,
                    );
                  } else if (v == 'logout') {
                    _confirmLogout(context);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(PhosphorIcons.pencilSimple, size: 18),
                      title: Text('Modifier le profil',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: AppColors.onSurface)),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'share',
                    child: ListTile(
                      leading: Icon(PhosphorIcons.shareNetwork, size: 18),
                      title: Text('Partager le profil',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: AppColors.onSurface)),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'logout',
                    child: ListTile(
                      leading: Icon(PhosphorIcons.signOut, size: 18, color: AppColors.error),
                      title: Text('Déconnexion',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: AppColors.error)),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _openFollowersList(BuildContext context, FollowListMode mode) {
    Navigator.of(context).pushNamed(
      AppRoutes.followersList,
      arguments: (
        memberId: member.id,
        memberName: member.name,
        mode: mode,
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Déconnexion',
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 17,
                fontWeight: FontWeight.w600)),
        content: Text(
          'Êtes-vous sûr de vouloir vous déconnecter ?',
          style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler',
                style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Déconnexion',
                style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await auth.signOut();
      } on AppException catch (e) {
        log.error('Sign-out failed', tag: 'profile', error: e);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
        }
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ProfileHero — Cover + Avatar + Infos + Actions
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHero extends StatelessWidget {
  final Member member;
  final Chapter? chapter;
  final String? email;
  final bool isOwnProfile;
  final bool isFollowing;
  final int followerCount;
  final int followingCount;
  final VoidCallback? onFollowTap;
  final VoidCallback? onMessageTap;

  const _ProfileHero({
    required this.member,
    required this.followerCount,
    required this.followingCount,
    this.chapter,
    this.email,
    this.isOwnProfile = true,
    this.isFollowing = false,
    this.onFollowTap,
    this.onMessageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: _borderColor, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Cover ──────────────────────────────────────────
          _buildCover(context),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar + Action buttons
                _buildAvatarRow(context),

                // Nom + infos + bio
                _buildInfoSection(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCover(BuildContext context) {
    final hasCover = member.coverUrl != null && member.coverUrl!.isNotEmpty;

    return GestureDetector(
      onTap: isOwnProfile
          ? () => Navigator.pushNamed(context, AppRoutes.editProfile)
          : (hasCover ? () => _openCoverViewer(context) : null),
      child: SizedBox(
        height: 140,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Cover image or gradient fallback
            if (member.coverUrl != null && member.coverUrl!.isNotEmpty)
              Hero(
                tag: 'cover_${member.id}',
                child: Image.network(
                  member.coverUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildCoverPlaceholder(),
                ),
              )
            else
              _buildCoverPlaceholder(),

            // Subtle gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.05),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.15),
                  ],
                ),
              ),
            ),

            // Edit button (own profile only)
            if (isOwnProfile)
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIcons.camera,
                          size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Modifier',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openCoverViewer(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        fullscreenDialog: true,
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, animation, __) => _CoverViewer(
          coverUrl: member.coverUrl!,
          heroTag: 'cover_${member.id}',
        ),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      color: AppColors.primary,
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: 40,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarRow(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar
          Container(
            width: _avatarLg,
            height: _avatarLg,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surface, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: _avatarLg / 2,
              backgroundColor: AppColors.secondaryFixed,
              backgroundImage: member.avatarUrl != null
                  ? NetworkImage(member.avatarUrl!)
                  : null,
              child: member.avatarUrl == null
                  ? Text(
                      member.initials ?? 'FC',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    )
                  : null,
            ),
          ),

          const Spacer(),

          // Action buttons
          if (isOwnProfile)
            _buildOwnActions(context)
          else
            _buildPublicActions(context),
        ],
      ),
    );
  }

  Widget _buildOwnActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Share
        SizedBox(
          height: 34,
          child: OutlinedButton(
            onPressed: () {
              ProfileShare.share(
                memberName: member.name,
                memberId: member.id,
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary, width: 1),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIcons.shareNetwork, size: 14),
                const SizedBox(width: 4),
                const Text('Partager'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Edit profile
        SizedBox(
          height: 34,
          child: ElevatedButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.editProfile),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIcons.pencilSimple, size: 14),
                const SizedBox(width: 4),
                const Text('Modifier'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPublicActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Message
        SizedBox(
          height: 34,
          child: OutlinedButton.icon(
            onPressed: onMessageTap,
            icon: Icon(PhosphorIcons.chatCircle, size: 14),
            label: const Text('Message'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary, width: 1),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Follow / Connect
        SizedBox(
          height: 34,
          child: ElevatedButton(
            onPressed: onFollowTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: isFollowing
                  ? AppColors.primaryFixed
                  : AppColors.primary,
              foregroundColor:
                  isFollowing ? AppColors.primary : Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isFollowing ? PhosphorIcons.check : PhosphorIcons.userPlus,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(isFollowing ? 'Abonné' : 'Suivre'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + Verified
          Row(
            children: [
              Text(
                member.name,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              if (member.isVerified) ...[
                const SizedBox(width: 6),
                Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(PhosphorIcons.sealCheckFill,
                      size: 14, color: Colors.white),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            member.profession,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),

          // Chapter badge
          if (chapter != null && chapter!.isActive)
            _ChapterBadge(chapter: chapter!),

          // Meta chips
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              // Location
              _MetaChip(
                icon: PhosphorIcons.mapPin,
                label: '${member.city}, ${member.country.length >= 2 ? member.country.substring(0, 2).toUpperCase() : member.country}',
              ),
              // LinkedIn / Website
              if (member.linkedIn != null && member.linkedIn!.isNotEmpty)
                _MetaChip(
                  icon: PhosphorIcons.link,
                  label: member.linkedIn!.replaceAll(RegExp(r'^https?://(www\.)?'), ''),
                  isLink: true,
                ),
              // Join date
              if (member.createdAt != null)
                _MetaChip(
                  icon: PhosphorIcons.calendarBlank,
                  label: 'Inscrit(e) ${member.createdAt!.year}',
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Bio
          if (member.bio != null && member.bio!.isNotEmpty)
            Text(
              member.bio!,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                height: 1.6,
                color: AppColors.onSurface,
              ),
            ),
        ],
      ),
    );
  }
}

// ── MetaChip ─────────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isLink;

  const _MetaChip({
    required this.icon,
    required this.label,
    this.isLink = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: isLink ? AppColors.tertiary : AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StatsCard — Posts / Followers / Following
// ─────────────────────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final int postCount;
  final int followerCount;
  final int followingCount;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;

  const _StatsCard({
    required this.postCount,
    required this.followerCount,
    required this.followingCount,
    this.onFollowersTap,
    this.onFollowingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor, width: 0.5),
      ),
      child: Row(
        children: [
          _statItem(PhosphorIcons.article, _formatCount(postCount), 'Publications'),
          _statDivider(),
          _statItem(PhosphorIcons.usersThree, _formatCount(followerCount), 'Abonnés',
              onTap: onFollowersTap),
          _statDivider(),
          _statItem(PhosphorIcons.userPlus, _formatCount(followingCount), 'Abonnements',
              onTap: onFollowingTap),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      final k = count / 1000;
      return k < 10 ? '${k.toStringAsFixed(1)}k' : '${k.toStringAsFixed(0)}k';
    }
    return count.toString();
  }

  Widget _statItem(IconData icon, String value, String label, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 36,
      color: Colors.black.withValues(alpha: 0.06),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SkillsCard — Compétences (tags neutres unifiés)
// ─────────────────────────────────────────────────────────────────────────────

class _SkillsCard extends StatelessWidget {
  final List<String> skills;

  const _SkillsCard({required this.skills});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(icon: PhosphorIcons.lightning, title: 'Compétences'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                skills.map((s) => _buildSkillTag(s)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillTag(String skill) {
    // FIX 3: Tous les tags utilisent le même style neutre,
        // quelle que soit la compétence.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor, width: 0.5),
      ),
      child: Text(
        skill,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurface,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ActivitySection — Activité récente
// ─────────────────────────────────────────────────────────────────────────────

class _ActivitySection extends StatelessWidget {
  final List<Post> posts;

  const _ActivitySection({required this.posts});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _SectionTitle(
              icon: PhosphorIcons.clockCounterClockwise,
              title: 'Activité récente'),
        ),
        const SizedBox(height: 12),
        if (posts.isEmpty)
          _SectionCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Aucune activité récente.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          )          else
          Column(
            children: [
              for (var i = 0; i < posts.length && i < 5; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: i < 4 ? 12 : 0),
                  child: _buildPostCard(posts[i]),
                ),
            ],
          ),
      ],
    );
  }

  /// Retourne le composant PostCard partagé (avec images, commentaires, likes).
  Widget _buildPostCard(Post post) {
    return PostCard(post: post, compact: true);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ServicesCard — Market Services (FIX 4 : icônes vert/or cohérentes)
// ─────────────────────────────────────────────────────────────────────────────

class _ServicesCard extends StatelessWidget {
  final List<MarketService> services;

  const _ServicesCard({required this.services});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(icon: PhosphorIcons.storefront, title: 'Market Services'),
          const SizedBox(height: 12),
          // FIX 4 : deux teintes cohérentes — emerald + gold
          ...List.generate(services.length, (i) {
            final service = services[i];
            return Column(
              children: [
                if (i > 0) const SizedBox(height: 10),
                _ServiceTile(
                  icon: PhosphorIcons.package,
                  iconBg: i.isEven
                      ? AppColors.primaryFixed
                      : AppColors.secondaryFixed,
                  iconColor: i.isEven
                      ? AppColors.primary
                      : AppColors.onSecondaryFixedVariant,
                  title: service.title,
                  description: service.description,
                  price: service.price,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String description;
  final String price;

  const _ServiceTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                if (price.isNotEmpty) ...[const SizedBox(height: 6),
                  Text(
                    price,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor, width: 0.5),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CoverViewer — Full-screen cover image viewer
// ─────────────────────────────────────────────────────────────────────────────

class _CoverViewer extends StatelessWidget {
  final String coverUrl;
  final String heroTag;

  const _CoverViewer({required this.coverUrl, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.maybePop(context),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Dismiss tapping anywhere
            const SizedBox.expand(),

            // Centered image
            Center(
              child: Hero(
                tag: heroTag,
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    coverUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                              : null,
                          color: Colors.white70,
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(PhosphorIcons.warningCircle,
                              size: 48, color: Colors.white38),
                          const SizedBox(height: 12),
                          Text(
                            'Impossible de charger l\'image',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Close button
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 12,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(PhosphorIcons.x,
                      size: 20, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ChapterBadge — Badge d'appartenance à une branche locale
// ─────────────────────────────────────────────────────────────────────────────

class _ChapterBadge extends StatelessWidget {
  final Chapter chapter;

  const _ChapterBadge({required this.chapter});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _onTap(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryFixed,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.12),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIcons.usersThree,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Membre de ${chapter.name}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                PhosphorIcons.arrowRight,
                size: 12,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context) {
    Navigator.of(context).pushNamed(
      AppRoutes.chapterDetail,
      arguments: chapter,
    );
  }
}
