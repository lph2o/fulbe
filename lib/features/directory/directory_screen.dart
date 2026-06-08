import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/data/mock_members.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../../shared/widgets/fc_card.dart';
import '../../shared/widgets/fc_search_bar.dart';
import '../../shared/widgets/fc_chip.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  int _selectedFilter = 0;
  String _query = '';

  static const _professionFilters = [
    'Tous',
    'Développeurs',
    'Médecins',
    'Entrepreneurs',
    'Juristes',
    'Designers',
  ];

  List<Member> get _filteredMembers {
    var list = MockMembers.all;
    if (_selectedFilter > 0) {
      list = list.where((m) {
        final prof = m.profession.toLowerCase();
        switch (_selectedFilter) {
          case 1: // Développeurs
            return prof.contains('dev') || prof.contains('soft');
          case 2: // Médecins
            return prof.contains('méd') || prof.contains('doc') || prof.contains('sant');
          case 3: // Entrepreneurs
            return prof.contains('entrep') || prof.contains('fond') || prof.contains('ceo');
          case 4: // Juristes
            return prof.contains('jur') || prof.contains('avoc') || prof.contains('droit');
          case 5: // Designers
            return prof.contains('desig') || prof.contains('ux') || prof.contains('ui');
          default:
            return true;
        }
      }).toList();
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where((m) =>
              m.name.toLowerCase().contains(q) ||
              m.profession.toLowerCase().contains(q) ||
              m.city.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────
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
                  'Annuaire',
                  style: AppTextStyles.headlineLg.copyWith(
                    color: AppColors.onSurface,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Connectez-vous avec des professionnels du réseau mondial.',
                  style: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.stackMd),
                // Member count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    '${MockMembers.all.length} professionnels inscrits',
                    style: AppTextStyles.labelSm
                        .copyWith(color: AppColors.primaryContainer),
                  ),
                ),
                const SizedBox(height: AppSpacing.stackMd),
                FcSearchBar(
                  placeholder: 'Rechercher professions, noms...',
                  showFilterButton: true,
                  onChanged: (q) => setState(() => _query = q),
                ),
                const SizedBox(height: AppSpacing.stackMd),
              ],
            ),
          ),
          // ── Profession filters ─────────────────────────────────
          FcChipRow(
            labels: _professionFilters,
            onSelectionChanged: (i) =>
                setState(() => _selectedFilter = i),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          // ── Member list ────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(
                left: AppSpacing.marginMobile,
                right: AppSpacing.marginMobile,
                bottom: AppSpacing.bottomNavHeight + AppSpacing.stackMd,
              ),
              itemCount: _filteredMembers.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.stackMd),
              itemBuilder: (_, i) =>
                  _MemberCard(member: _filteredMembers[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final Member member;
  const _MemberCard({required this.member});

  @override
  Widget build(BuildContext context) {
    return FcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FcAvatar(
                imageUrl: member.avatarUrl,
                initials: member.initials ??
                    member.name.substring(0, 2).toUpperCase(),
                size: 56,
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            member.name,
                            style: AppTextStyles.labelMd.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (member.isVerified)
                          const Icon(Icons.verified,
                              color: AppColors.primaryContainer, size: 18),
                        const SizedBox(width: 4),
                        const Icon(Icons.more_vert,
                            color: AppColors.onSurfaceVariant, size: 20),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      member.profession,
                      style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 2),
                        Text(
                          '${member.city}, ${member.country}',
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
            ],
          ),
          // Skills chips
          if (member.skills.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.stackMd),
            Wrap(
              spacing: AppSpacing.stackSm,
              runSpacing: AppSpacing.stackSm,
              children: member.skills.take(3).map((s) {
                final isCultural = s.toLowerCase().contains('pulaar') ||
                    s.toLowerCase().contains('cultural');
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCultural
                        ? AppColors.secondaryContainer
                            .withValues(alpha: 0.4)
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
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.stackMd),
          ] else
            const SizedBox(height: AppSpacing.stackMd),
          // CTA — all uniform outlined style
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.chat_bubble_outline, size: 16),
              label: const Text('Contacter'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryContainer,
                side: const BorderSide(
                    color: AppColors.primaryContainer, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                textStyle: AppTextStyles.labelMd.copyWith(
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
