import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/data/mock_members.dart';
import '../../core/data/mock_posts.dart';
import '../../shared/widgets/fc_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static final Member _user = MockMembers.all[7]; // Aaliyah Sow

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.95),
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.marginMobile),
          child: CircleAvatar(
            backgroundImage: NetworkImage(_user.avatarUrl ?? ''),
            radius: 20,
          ),
        ),
        title: Text('Fulɓe Connect',
            style: AppTextStyles.headlineLgMobile.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            )),
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
        padding: const EdgeInsets.only(
            bottom: AppSpacing.bottomNavHeight + AppSpacing.stackMd),
        children: [
          // ── Cover + Avatar header ──────────────────────────────
          _ProfileHeader(user: _user),
          // ── Info section ──────────────────────────────────────
          _ProfileInfo(user: _user),
          const SizedBox(height: AppSpacing.stackMd),
          // ── Professional Skills ────────────────────────────────
          _Section(
            title: 'Compétences Professionnelles',
            icon: Icons.bolt,
            child: _SkillsSection(skills: _user.skills),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          // ── Market Services ────────────────────────────────────
          _Section(
            title: 'Services Marketplace',
            icon: Icons.storefront_outlined,
            child: _ServicesSection(),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          // ── Recent Activity ────────────────────────────────────
          _Section(
            title: 'Activité Récente',
            icon: Icons.history,
            child: _ActivitySection(),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final Member user;
  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover image
        Container(
          height: 140,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryContainer,
                Color(0xFF2D6A4F),
              ],
            ),
          ),
          child: Opacity(
            opacity: 0.15,
            child: CustomPaint(painter: _HeroBgPainter()),
          ),
        ),
        // Avatar + actions row
        Positioned(
          bottom: -40,
          left: AppSpacing.marginMobile,
          right: AppSpacing.marginMobile,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Avatar with border
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(user.avatarUrl ?? ''),
                ),
              ),
              const Spacer(),
              // Action buttons
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.chat_bubble_outline, size: 14),
                label: const Text('Message'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryContainer,
                  side: const BorderSide(color: AppColors.primaryContainer),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  textStyle: AppTextStyles.labelSm,
                ),
              ),
              const SizedBox(width: AppSpacing.stackSm),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  textStyle: AppTextStyles.labelSm,
                ),
                child: const Text('Connecter'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileInfo extends StatelessWidget {
  final Member user;
  const _ProfileInfo({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        52,
        AppSpacing.marginMobile,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                user.name,
                style: AppTextStyles.headlineLgMobile.copyWith(
                    color: AppColors.onSurface),
              ),
              if (user.isVerified) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified,
                    color: AppColors.primaryContainer, size: 20),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(user.profession,
              style: AppTextStyles.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 14, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 2),
              Text('${user.city}, ${user.country.substring(0, 2).toUpperCase()}',
                  style: AppTextStyles.labelSm
                      .copyWith(color: AppColors.onSurfaceVariant)),
              const SizedBox(width: AppSpacing.stackMd),
              const Icon(Icons.link, size: 14, color: AppColors.primaryContainer),
              const SizedBox(width: 2),
              Text('aaliyah.design',
                  style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.primaryContainer,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 13, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('Inscrite en 2021',
                  style: AppTextStyles.labelSm
                      .copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Text(
            'Bridging digital experiences with cultural heritage. Specializing in inclusive UX design for global fintech platforms and providing professional Pulaar translation services to empower local communities.',
            style: AppTextStyles.bodyMd
                .copyWith(color: AppColors.onSurface, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _Section(
      {required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
      child: FcCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primaryContainer),
                const SizedBox(width: 8),
                Text(title,
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    )),
              ],
            ),
            const SizedBox(height: AppSpacing.stackMd),
            child,
          ],
        ),
      ),
    );
  }
}

class _SkillsSection extends StatelessWidget {
  final List<String> skills;
  const _SkillsSection({required this.skills});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.stackSm,
      runSpacing: AppSpacing.stackSm,
      children: skills.map((s) {
        final isCultural = s.toLowerCase().contains('pulaar') ||
            s.toLowerCase().contains('cultural');
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isCultural
                ? AppColors.secondaryContainer
                : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(
              color: isCultural
                  ? AppColors.secondaryContainer
                  : AppColors.outlineVariant,
              width: 0.8,
            ),
          ),
          child: Text(
            s,
            style: AppTextStyles.labelSm.copyWith(
              color: isCultural
                  ? AppColors.onSecondaryContainer
                  : AppColors.onSurfaceVariant,
              fontWeight: isCultural ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ServicesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _ServiceRow(
          icon: Icons.design_services_outlined,
          iconBg: AppColors.primaryContainer,
          title: 'Consultation UX',
          subtitle: 'Session stratégique de design inclusif.',
          price: '150 € / hr',
        ),
        Divider(height: AppSpacing.stackLg, color: AppColors.outlineVariant),
        _ServiceRow(
          icon: Icons.translate,
          iconBg: Color(0xFF735C00),
          title: 'Localisation Pulaar',
          subtitle: 'Traduction professionnelle apps et documents.',
          price: 'À partir de 50 €',
        ),
      ],
    );
  }
}

class _ServiceRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String price;

  const _ServiceRow({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
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
              Text(subtitle,
                  style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant)),
            ],
          ),
        ),
        Text(price,
            style: AppTextStyles.labelMd.copyWith(
                color: AppColors.onSurface, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _ActivitySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: MockPosts.all.take(2).map((post) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.stackMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text('Publication',
                    style: AppTextStyles.labelSm
                        .copyWith(color: AppColors.primaryContainer)),
              ),
              const SizedBox(height: 6),
              Text(post.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.onSurface, fontSize: 14)),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.thumb_up_outlined,
                      size: 13, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('${post.likesCount}',
                      style: AppTextStyles.labelSm
                          .copyWith(color: AppColors.onSurfaceVariant)),
                  const SizedBox(width: AppSpacing.stackMd),
                  Text(post.timeAgo,
                      style: AppTextStyles.labelSm
                          .copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
              if (post != MockPosts.all[1])
                const Divider(
                    height: AppSpacing.stackLg,
                    color: AppColors.outlineVariant),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _HeroBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (double i = -size.height; i < size.width; i += 24) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
