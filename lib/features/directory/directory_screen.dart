// ignore_for_file: prefer_const_constructors, prefer_const_constructors_in_immutables, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/models/member.dart';
import '../../core/data/providers/data_providers.dart';
import '../../shared/helpers/contact_helper.dart';
import '../../core/errors/app_exception.dart';
import '../../core/navigation/app_router.dart' show AppRoutes;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../../shared/widgets/fc_card.dart';
import '../../shared/widgets/fc_search_bar.dart';
import '../../shared/widgets/fc_chip.dart';

class DirectoryScreen extends ConsumerStatefulWidget {
  DirectoryScreen({super.key});

  @override
  ConsumerState<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends ConsumerState<DirectoryScreen> {
  int _selectedFilter = 0;
  String _query = '';

  static final _professionFilters = [
    'Tous',
    'Développeurs',
    'Médecins',
    'Entrepreneurs',
    'Juristes',
    'Designers',
  ];

  List<Member> _filter(List<Member> source) {
    var list = source;
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

  Future<void> _contactMember(Member member) async {
    await ContactHelper.navigateToConversation(context, ref, member.id);
  }

  @override
  Widget build(BuildContext context) {
    final asyncMembers = ref.watch(membersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
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
                SizedBox(height: 2),
                Text(
                  'Connectez-vous avec des professionnels du réseau mondial.',
                  style: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
                SizedBox(height: AppSpacing.stackMd),
                // Member count badge (live)
                asyncMembers.when(
                  data: (members) => Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      '${members.length} professionnels inscrits',
                      style: AppTextStyles.labelSm
                          .copyWith(color: AppColors.primaryContainer),
                    ),
                  ),
                  loading: () => SizedBox.shrink(),
                  error: (_, __) => SizedBox.shrink(),
                ),
                SizedBox(height: AppSpacing.stackMd),
                FcSearchBar(
                  placeholder: 'Rechercher professions, noms...',
                  showFilterButton: true,
                  onChanged: (q) => setState(() => _query = q),
                ),
                SizedBox(height: AppSpacing.stackMd),
              ],
            ),
          ),
          // ── Profession filters ─────────────────────────────────
          FcChipRow(
            labels: _professionFilters,
            onSelectionChanged: (i) =>
                setState(() => _selectedFilter = i),
          ),
          SizedBox(height: AppSpacing.stackMd),
          // ── Member list (Riverpod) ─────────────────────────────
          Expanded(
            child: asyncMembers.when(
              data: (members) {
                final filtered = _filter(members);
                if (filtered.isEmpty) {
                  return SizedBox();
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(membersProvider);
                    await ref.read(membersProvider.future);
                  },
                  child: ListView.separated(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(
                      left: AppSpacing.marginMobile,
                      right: AppSpacing.marginMobile,
                      bottom: AppSpacing.bottomNavHeight + AppSpacing.stackMd,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        SizedBox(height: AppSpacing.stackMd),
                    itemBuilder: (_, i) => _MemberCard(
                          member: filtered[i],
                          onContactTap: () => _contactMember(filtered[i]),
                        ),
                  ),
                );
              },
              loading: () => Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.stackLg),
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off,
                          size: 56, color: AppColors.outlineVariant),
                      SizedBox(height: 16),
                      Text(
                        e is AppException
                            ? e.message
                            : 'Impossible de charger l\'annuaire.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMd
                            .copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
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

class _MemberCard extends StatelessWidget {
  final Member member;
  final VoidCallback onContactTap;
  _MemberCard({required this.member, required this.onContactTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.publicProfile,
        arguments: member.id,
      ),
      child: FcCard(
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
                SizedBox(width: AppSpacing.stackMd),
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
                            Icon(Icons.verified,
                                color: AppColors.primaryContainer, size: 18),
                          SizedBox(width: 4),
                          Icon(Icons.more_vert,
                              color: AppColors.onSurfaceVariant, size: 20),
                        ],
                      ),
                      SizedBox(height: 2),
                      Text(
                        member.profession,
                        style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant, fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 13, color: AppColors.onSurfaceVariant),
                          SizedBox(width: 2),
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
              SizedBox(height: AppSpacing.stackMd),
              Wrap(
                spacing: AppSpacing.stackSm,
                runSpacing: AppSpacing.stackSm,
                children: member.skills.take(3).map((s) {
                  final isCultural = s.toLowerCase().contains('pulaar') ||
                      s.toLowerCase().contains('cultural');
                  return Container(
                    padding: EdgeInsets.symmetric(
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
              SizedBox(height: AppSpacing.stackMd),
            ] else
              SizedBox(height: AppSpacing.stackMd),
            // CTA — all uniform outlined style
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onContactTap,
                icon: Icon(Icons.chat_bubble_outline, size: 16),
                label: Text('Contacter'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryContainer,
                  side: BorderSide(
                      color: AppColors.primaryContainer, width: 1.2),
                  padding: EdgeInsets.symmetric(vertical: 10),
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
      ),
    );
  }
}
