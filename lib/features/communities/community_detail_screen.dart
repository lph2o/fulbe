// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

import '../../core/data/models/community.dart';
import '../../core/data/providers/data_providers.dart';
import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/navigation/app_router.dart';
import 'community_chat_tab.dart';

/// Écran détail d'une communauté : en-tête + chat (plus de publications).
class CommunityDetailScreen extends ConsumerStatefulWidget {
  final String communityId;

  const CommunityDetailScreen({super.key, required this.communityId});

  @override
  ConsumerState<CommunityDetailScreen> createState() =>
      _CommunityDetailScreenState();
}

class _CommunityDetailScreenState
    extends ConsumerState<CommunityDetailScreen> {
  Future<void> _toggleMembership(Community community) async {
    final repo = ref.read(communitiesRepositoryProvider);
    final member = await ref.read(currentMemberProvider.future);
    if (member == null) return;

    try {
      if (community.isMember) {
        await repo.leave(community.id, member.id);
      } else {
        await repo.join(community.id, member.id);
        await repo.getOrCreateConversation(community.id);
        await repo.addConversationParticipant(community.id, member.id);
      }
      if (mounted) {
        ref.invalidate(communityProvider(widget.communityId));
        ref.invalidate(communitiesProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncCommunity = ref.watch(communityProvider(widget.communityId));
    final member = ref.watch(currentMemberProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: asyncCommunity.when(
        data: (community) {
          if (community == null) {
            return Center(
              child: Text('Communauté introuvable.',
                  style: TextStyle(color: AppColors.onSurfaceVariant)),
            );
          }

          // Non-membre : vue simple sans chat
          if (!community.isMember) {
            return _buildNonMemberView(community);
          }

          // Membre : en-tête + chat plein écran
          final chat = member != null
              ? CommunityChatTab(
                  communityId: community.id,
                  currentMemberId: member.id,
                )
              : Center(
                  child: Text('Connecte-toi pour utiliser le chat.',
                      style: TextStyle(color: AppColors.onSurfaceVariant)),
                );

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildSliverAppBar(community),
              SliverToBoxAdapter(child: _buildJoinBar(community)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      Expanded(child: _buildMembersButton(community)),
                      const SizedBox(width: 8),
                      _buildInviteButton(community),
                    ],
                  ),
                ),
              ),
            ],
            body: chat,
          );
        },
        loading: () =>
            Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
        error: (e, _) => Center(
          child: Text(
            e is AppException ? e.message : 'Erreur de chargement.',
            style: TextStyle(color: AppColors.onSurfaceVariant),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(Community community) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.surface,
      leading: IconButton(
        icon: Icon(PhosphorIcons.arrowLeft,
            color: AppColors.onSurfaceVariant, size: 22),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: community.isAdmin
          ? [
              IconButton(
                icon: Icon(PhosphorIcons.gear,
                    color: Colors.white70, size: 20),
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.communitySettings,
                    arguments: community,
                  );
                },
              ),
            ]
          : null,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            color: _categoryColor(community.category),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _categoryColor(community.category),
                _categoryColor(community.category).withValues(alpha: 0.7),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    _categoryIcon(community.category),
                    color: Colors.white70,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    community.name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    community.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJoinBar(Community community) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.surface,
      child: Row(
        children: [
          Icon(PhosphorIcons.user, size: 16, color: AppColors.outline),
          const SizedBox(width: 6),
          Text(
            '${community.memberCount} membre${community.memberCount > 1 ? 's' : ''}',
            style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(width: 16),
          if (community.isPrivate) ...[
            Icon(PhosphorIcons.lock, size: 16, color: AppColors.outline),
            const SizedBox(width: 6),
            Text(
              'Groupe privé',
              style:
                  TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
            const Spacer(),
          ] else ...[
            Icon(PhosphorIcons.globe, size: 16, color: AppColors.outline),
            const SizedBox(width: 6),
            Text(
              'Groupe public',
              style:
                  TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
            const Spacer(),
          ],
          SizedBox(
            height: 34,
            child: ElevatedButton(
              onPressed: () => _toggleMembership(community),
              style: ElevatedButton.styleFrom(
                backgroundColor: community.isMember
                    ? AppColors.surface
                    : AppColors.primary,
                foregroundColor: community.isMember
                    ? AppColors.primary
                    : Colors.white,
                elevation: 0,
                side: community.isMember
                    ? BorderSide(color: AppColors.primary)
                    : BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
              child: Text(
                community.isMember ? 'Quitter' : 'Rejoindre',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersButton(Community community) {
    return InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            AppRoutes.communityMembers,
            arguments: {
              'communityId': community.id,
              'isAdmin': community.isAdmin,
            },
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: AppColors.outlineVariant, width: 0.5),
          ),
          child: Row(
            children: [
              Icon(PhosphorIcons.users,
                  size: 18, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Membres (${community.memberCount})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              Icon(PhosphorIcons.caretRight,
                  size: 16, color: AppColors.outlineVariant),
            ],
          ),
        ));
  }

  Widget _buildInviteButton(Community community) {
    return GestureDetector(
      onTap: () => _showInviteSheet(community),
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outlineVariant, width: 0.5),
        ),
        child: Icon(
          PhosphorIcons.shareNetwork,
          size: 20,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Future<void> _showInviteSheet(Community community) async {
    final repo = ref.read(communitiesRepositoryProvider);
    final member = await ref.read(currentMemberProvider.future);
    if (member == null) return;

    String? code = await repo.getInviteCode(community.id);
    if (code == null) {
      try {
        code = await repo.generateInviteCode(
          communityId: community.id,
          createdBy: member.id,
        );
        if (mounted) ref.invalidate(communityInviteCodeProvider(community.id));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur : ${e.toString()}')),
          );
        }
        return;
      }
    }

    if (!mounted) return;
    final safeCode = code;

    final inviteLink = 'https://fulbe.app/join-community/$safeCode';

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Icon(
                PhosphorIcons.shareNetwork,
                size: 32,
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              const Text(
                'Inviter des membres',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Partage ce lien pour inviter des personnes à rejoindre "${community.name}".',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.outlineVariant),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        safeCode,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                          letterSpacing: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: safeCode));
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Code copié !'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryFixed,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          PhosphorIcons.copySimple,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: inviteLink));
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Lien copié !'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: AppColors.outlineVariant),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: Icon(PhosphorIcons.linkSimple,
                          size: 18,
                          color: AppColors.onSurfaceVariant),
                      label: Text(
                        'Copier le lien',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        SharePlus.instance.share(
                          ShareParams(
                            text:
                                'Rejoins "${community.name}" sur Fulɓe Connect avec ce lien :\n\n$inviteLink\n\nCode : $safeCode',
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(PhosphorIcons.shareNetwork,
                          size: 18),
                      label: const Text('Partager',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    final _ = await repo.generateInviteCode(
                      communityId: community.id,
                      createdBy: member.id,
                    );
                    if (mounted) {
                      ref.invalidate(
                          communityInviteCodeProvider(community.id));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nouveau code généré !'),
                        ),
                      );
                    }
                    if (mounted) _showInviteSheet(community);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Erreur : ${e.toString()}')),
                      );
                    }
                  }
                },
                icon: Icon(PhosphorIcons.arrowsClockwise,
                    size: 16, color: AppColors.onSurfaceVariant),
                label: Text(
                  'Régénérer le code',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Vue pour les non-membres (en-tête + barre rejoindre seulement).
  Widget _buildNonMemberView(Community community) {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(community),
        SliverToBoxAdapter(child: _buildJoinBar(community)),
        SliverToBoxAdapter(
          child: SizedBox(height: AppSpacing.bottomNavHeight + 80),
        ),
      ],
    );
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'tech':
        return AppColors.tertiary;
      case 'agriculture':
        return const Color(0xFF16A34A);
      case 'culture':
        return AppColors.purple;
      case 'santé':
      case 'sante':
        return const Color(0xFFDC2626);
      case 'finance':
        return const Color(0xFFE8A838);
      case 'éducation':
      case 'education':
        return AppColors.teal;
      case 'sport':
        return const Color(0xFFF97316);
      default:
        return AppColors.primary;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'tech':
        return PhosphorIcons.code;
      case 'agriculture':
        return PhosphorIcons.plant;
      case 'culture':
        return PhosphorIcons.palette;
      case 'santé':
      case 'sante':
        return PhosphorIcons.heart;
      case 'finance':
        return PhosphorIcons.coin;
      case 'éducation':
      case 'education':
        return PhosphorIcons.bookOpen;
      case 'sport':
        return PhosphorIcons.barbell;
      case 'projet':
        return PhosphorIcons.rocket;
      case 'région':
      case 'region':
        return PhosphorIcons.mapPin;
      default:
        return PhosphorIcons.usersThree;
    }
  }
}
