// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers/data_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Résultat de fetchMembers avec embed member.
class _MemberEntry {
  final String id;
  final String memberId;
  final String role;
  final String memberName;
  final String? memberAvatarUrl;

  const _MemberEntry({
    required this.id,
    required this.memberId,
    required this.role,
    required this.memberName,
    this.memberAvatarUrl,
  });
}

/// Écran de gestion des membres d'une communauté.
///
/// Accessible uniquement aux membres du groupe.
/// Les admins peuvent changer les rôles.
class CommunityMembersScreen extends ConsumerStatefulWidget {
  final String communityId;
  final bool isAdmin;

  const CommunityMembersScreen({
    super.key,
    required this.communityId,
    this.isAdmin = false,
  });

  @override
  ConsumerState<CommunityMembersScreen> createState() =>
      _CommunityMembersScreenState();
}

class _CommunityMembersScreenState
    extends ConsumerState<CommunityMembersScreen> {
  List<_MemberEntry> _members = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ref.read(communitiesRepositoryProvider);
      final data = await repo.fetchMembers(widget.communityId);

      _members = data.map((json) {
        final member = json['member'] as Map<String, dynamic>?;
        return _MemberEntry(
          id: json['id'] as String,
          memberId: json['member_id'] as String,
          role: json['role'] as String? ?? 'member',
          memberName: member?['full_name'] as String? ??
              member?['name'] as String? ??
              'Membre',
          memberAvatarUrl: member?['avatar_url'] as String?,
        );
      }).toList();

      // Trier : admins en premier, puis modérateurs, puis membres
      _members.sort((a, b) {
        const order = {'admin': 0, 'moderator': 1, 'member': 2};
        return (order[a.role] ?? 3).compareTo(order[b.role] ?? 3);
      });
    } catch (e) {
      _error = 'Impossible de charger les membres.';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changeRole(
      _MemberEntry member, String newRole, String label) async {
    try {
      final repo = ref.read(communitiesRepositoryProvider);
      await repo.updateMemberRole(widget.communityId, member.memberId, newRole);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.memberName} est maintenant $label'),
            duration: Duration(seconds: 2),
          ),
        );
        _loadMembers();
        ref.invalidate(communityProvider(widget.communityId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _confirmRemove(_MemberEntry member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Retirer ${member.memberName} ?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Ce membre ne pourra plus accéder au groupe.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final repo = ref.read(communitiesRepositoryProvider);
        await repo.leave(widget.communityId, member.memberId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${member.memberName} a été retiré.')),
          );
          _loadMembers();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft,
              color: AppColors.onSurfaceVariant, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Membres (${_members.length})',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(strokeWidth: 2.4));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIcons.warning, size: 40, color: AppColors.outlineVariant),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMembers,
              child: Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    if (_members.isEmpty) {
      return Center(
        child: Text(
          'Aucun membre.',
          style: TextStyle(color: AppColors.onSurfaceVariant),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(
          top: 8, bottom: AppSpacing.bottomNavHeight + 40),
      itemCount: _members.length,
      itemBuilder: (_, i) => _MemberTile(
        member: _members[i],
        isAdmin: widget.isAdmin,
        onRoleChanged: _changeRole,
        onRemove: _confirmRemove,
      ),
    );
  }
}

// ── Member Tile ─────────────────────────────────────────────────────────────

class _MemberTile extends StatelessWidget {
  final _MemberEntry member;
  final bool isAdmin;
  final Future<void> Function(_MemberEntry, String, String) onRoleChanged;
  final Future<void> Function(_MemberEntry) onRemove;

  const _MemberTile({
    required this.member,
    required this.isAdmin,
    required this.onRoleChanged,
    required this.onRemove,
  });

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'moderator':
        return 'Modérateur';
      default:
        return 'Membre';
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return AppColors.primary;
      case 'moderator':
        return AppColors.tertiary;
      default:
        return AppColors.outline;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'admin':
        return PhosphorIcons.crown;
      case 'moderator':
        return PhosphorIcons.shieldCheck;
      default:
        return PhosphorIcons.user;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant, width: 0.5),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primaryFixed,
            backgroundImage: member.memberAvatarUrl != null
                ? NetworkImage(member.memberAvatarUrl!)
                : null,
            child: member.memberAvatarUrl == null
                ? Text(
                    member.memberName.isNotEmpty
                        ? member.memberName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Name + role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.memberName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(_roleIcon(member.role),
                        size: 13, color: _roleColor(member.role)),
                    const SizedBox(width: 4),
                    Text(
                      _roleLabel(member.role),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _roleColor(member.role),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions (admin only, not for self)
          if (isAdmin && member.role != 'admin')
            PopupMenuButton<String>(
              icon: Icon(PhosphorIcons.dotsThreeVertical,
                  size: 18, color: AppColors.onSurfaceVariant),
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.outlineVariant),
              ),
              onSelected: (value) {
                switch (value) {
                  case 'promote_moderator':
                    onRoleChanged(member, 'moderator', 'modérateur');
                    break;
                  case 'demote_member':
                    onRoleChanged(member, 'member', 'membre');
                    break;
                  case 'remove':
                    onRemove(member);
                    break;
                }
              },
              itemBuilder: (_) => [
                if (member.role == 'member')
                  PopupMenuItem(
                    value: 'promote_moderator',
                    child: Row(
                      children: [
                        Icon(PhosphorIcons.shieldCheck,
                            size: 18, color: AppColors.tertiary),
                        const SizedBox(width: 10),
                        Text('Promouvoir modérateur'),
                      ],
                    ),
                  ),
                if (member.role == 'moderator')
                  PopupMenuItem(
                    value: 'demote_member',
                    child: Row(
                      children: [
                        Icon(PhosphorIcons.arrowDown,
                            size: 18, color: AppColors.outline),
                        const SizedBox(width: 10),
                        Text('Rétrograder membre'),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(PhosphorIcons.userMinus,
                          size: 18, color: AppColors.error),
                      const SizedBox(width: 10),
                      Text('Retirer du groupe'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
