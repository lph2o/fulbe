// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../core/data/models/member.dart';
import '../../core/data/providers/data_providers.dart';
import '../../core/navigation/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/helpers/contact_helper.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FollowersListScreen — Liste d'abonnés ou d'abonnements
// ─────────────────────────────────────────────────────────────────────────────

enum FollowListMode { followers, following }

class FollowersListScreen extends ConsumerWidget {
  final String memberId;
  final String memberName;
  final FollowListMode mode;

  const FollowersListScreen({
    super.key,
    required this.memberId,
    required this.memberName,
    required this.mode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = mode == FollowListMode.followers
        ? memberFollowersProvider(memberId)
        : memberFollowingProvider(memberId);

    final membersAsync = ref.watch(provider);
    final title = mode == FollowListMode.followers ? 'Abonnés' : 'Abonnements';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft,
              color: AppColors.onSurfaceVariant, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              memberName,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: membersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 40, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                'Erreur de chargement',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        data: (members) {
          if (members.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    mode == FollowListMode.followers
                        ? PhosphorIcons.usersThree
                        : PhosphorIcons.userPlus,
                    size: 40,
                    color: AppColors.outlineVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    mode == FollowListMode.followers
                        ? 'Aucun abonné pour le moment'
                        : 'Aucun abonnement pour le moment',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.marginMobile,
              AppSpacing.stackSm,
              AppSpacing.marginMobile,
              AppSpacing.bottomNavHeight + AppSpacing.stackMd,
            ),
            itemCount: members.length,
            itemBuilder: (_, i) => _MemberRow(member: members[i]),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MemberRow
// ─────────────────────────────────────────────────────────────────────────────

class _MemberRow extends ConsumerStatefulWidget {
  final Member member;
  const _MemberRow({required this.member});

  @override
  ConsumerState<_MemberRow> createState() => _MemberRowState();
}

class _MemberRowState extends ConsumerState<_MemberRow> {
  bool _isContacting = false;

  Future<void> _contactMember() async {
    if (_isContacting) return;
    setState(() => _isContacting = true);
    await ContactHelper.navigateToConversation(context, ref, widget.member.id);
    if (mounted) setState(() => _isContacting = false);
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            AppRoutes.publicProfile,
            arguments: member.id,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.secondaryFixed,
                backgroundImage: member.avatarUrl != null
                    ? NetworkImage(member.avatarUrl!)
                    : null,
                child: member.avatarUrl == null
                    ? Text(
                        member.initials ?? '?',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      member.profession,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Contact button
              GestureDetector(
                onTap: _isContacting ? null : _contactMember,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    PhosphorIcons.chatCircleDots,
                    size: 18,
                    color: AppColors.primaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(PhosphorIcons.caretRight,
                  size: 16, color: AppColors.outlineVariant),
            ],
          ),
        ),
      ),
    );
  }
}
