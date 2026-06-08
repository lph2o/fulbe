import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/data/mock_posts.dart';
import '../../core/navigation/app_router.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../../shared/widgets/fc_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimary,
        elevation: 3,
        child: const Icon(Icons.edit_outlined),
      ),
      body: ListView(
        padding: const EdgeInsets.only(
          top: AppSpacing.stackMd,
          bottom: AppSpacing.bottomNavHeight + AppSpacing.stackMd,
        ),
        children: [
          // ── Announcements Bento ────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile),
            child: Column(
              children: [
                for (final a in MockAnnouncements.all)
                  Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppSpacing.stackMd),
                    child: _AnnouncementCard(announcement: a),
                  ),
              ],
            ),
          ),
          // ── Section header ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.marginMobile,
            ),
            child: Row(
              children: [
                Text(
                  'Fil d\'actualité',
                  style: AppTextStyles.headlineLgMobile.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          // ── Quick-access module row ────────────────────────────
          _ModuleQuickRow(context: context),
          const SizedBox(height: AppSpacing.stackLg),
          // ── Posts ─────────────────────────────────────────────
          for (final post in MockPosts.all)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.marginMobile,
                right: AppSpacing.marginMobile,
                bottom: AppSpacing.stackMd,
              ),
              child: _PostCard(post: post),
            ),
        ],
      ),
    );
  }
}

// ── Announcement Card ──────────────────────────────────────────────────────

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  const _AnnouncementCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    return FcCard(
      onTap: () {},
      child: Stack(
        children: [
          Positioned(
            top: -8,
            right: -8,
            child: Icon(
              Icons.campaign_outlined,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.06),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chip
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.event,
                        size: 12, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      announcement.chipLabel,
                      style: AppTextStyles.labelSm
                          .copyWith(color: AppColors.secondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.stackSm),
              Text(
                announcement.title,
                style: AppTextStyles.headlineLgMobile.copyWith(
                  color: AppColors.onSurface,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: AppSpacing.unit),
              Text(
                announcement.description,
                style: AppTextStyles.bodyMd
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              Row(
                children: [
                  Text(
                    announcement.ctaLabel,
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.primaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward,
                      size: 16, color: AppColors.primaryContainer),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Module Quick Access Row ─────────────────────────────────────────────────

class _ModuleQuickRow extends StatelessWidget {
  final BuildContext context;
  const _ModuleQuickRow({required this.context});

  static const _modules = [
    _Module(icon: Icons.local_library_outlined, label: 'Bibliothèque',
        route: AppRoutes.library),
    _Module(icon: Icons.work_outline, label: 'Emplois',
        route: AppRoutes.jobs),
    _Module(icon: Icons.account_balance_wallet_outlined, label: 'Finances',
        route: AppRoutes.finances),
    _Module(icon: Icons.school_outlined, label: 'Apprendre',
        route: AppRoutes.learn),
    _Module(icon: Icons.chat_outlined, label: 'Messages',
        route: AppRoutes.messages),
  ];

  @override
  Widget build(BuildContext c) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.marginMobile),
        itemCount: _modules.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppSpacing.stackMd),
        itemBuilder: (_, i) => _ModuleChip(
          module: _modules[i],
          onTap: () =>
              Navigator.pushNamed(context, _modules[i].route),
        ),
      ),
    );
  }
}

class _Module {
  final IconData icon;
  final String label;
  final String route;
  const _Module({required this.icon, required this.label, required this.route});
}

class _ModuleChip extends StatelessWidget {
  final _Module module;
  final VoidCallback onTap;
  const _ModuleChip({required this.module, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                  color: AppColors.outlineVariant, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(module.icon,
                size: AppSpacing.iconMd,
                color: AppColors.primaryContainer),
          ),
          const SizedBox(height: 6),
          Text(
            module.label,
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Post Card ──────────────────────────────────────────────────────────────

class _PostCard extends StatefulWidget {
  final Post post;
  const _PostCard({required this.post});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    return FcCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.stackMd),
            child: Row(
              children: [
                FcAvatar(imageUrl: widget.post.authorAvatarUrl, size: 44),
                const SizedBox(width: AppSpacing.stackSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.post.authorName,
                          style: AppTextStyles.labelMd.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w700)),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 12,
                              color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 2),
                          Text(
                            '${widget.post.authorCity}, '
                            '${widget.post.authorCountry} • '
                            '${widget.post.timeAgo}',
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_horiz,
                    color: AppColors.onSurfaceVariant),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.stackMd),
            child: Text(
              widget.post.content,
              style: AppTextStyles.bodyMd
                  .copyWith(color: AppColors.onSurface),
            ),
          ),
          // Image
          if (widget.post.imageUrl != null) ...[
            const SizedBox(height: AppSpacing.stackMd),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.zero),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  widget.post.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.surfaceContainerHigh,
                    child: const Icon(Icons.image_outlined,
                        color: AppColors.outline, size: 48),
                  ),
                ),
              ),
            ),
          ],
          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.stackMd,
              vertical: AppSpacing.stackMd,
            ),
            child: Row(
              children: [
                _ActionBtn(
                  icon: _liked
                      ? Icons.favorite
                      : Icons.favorite_border,
                  label: '${widget.post.likesCount + (_liked ? 1 : 0)}',
                  color: _liked ? Colors.red : null,
                  onTap: () => setState(() => _liked = !_liked),
                ),
                const SizedBox(width: AppSpacing.gutter),
                _ActionBtn(
                  icon: Icons.chat_bubble_outline,
                  label: '${widget.post.commentsCount}',
                  onTap: () {},
                ),
                const SizedBox(width: AppSpacing.gutter),
                _ActionBtn(
                  icon: Icons.share_outlined,
                  label: 'Partager',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon,
              size: 20,
              color: color ?? AppColors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyles.labelSm.copyWith(
                  color: color ?? AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
