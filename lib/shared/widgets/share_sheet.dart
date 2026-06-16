import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/models/conversation.dart' show Conversation;
import '../../core/data/providers/data_providers.dart';
import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Bottom sheet « Envoyer à... » qui liste les conversations récentes
/// et permet d'envoyer un post en message privé.
///
/// Usage :
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   builder: (_) => ShareSheet(postId: post.id),
/// );
/// ```
class ShareSheet extends ConsumerStatefulWidget {
  final String postId;
  final String postAuthorName;
  final String postContent;

  const ShareSheet({
    super.key,
    required this.postId,
    required this.postAuthorName,
    required this.postContent,
  });

  @override
  ConsumerState<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends ConsumerState<ShareSheet> {
  final _searchCtrl = TextEditingController();
  bool _isSending = false;
  String? _sentConvId;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendToConversation(String conversationId) async {
    if (_isSending) return;
    setState(() => _isSending = true);

    try {
      final currentMember = ref.read(currentMemberProvider).valueOrNull;
      if (currentMember == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vous devez être connecté.')),
          );
        }
        return;
      }

      await ref.read(postsRepositoryProvider).sendPostAsDM(
            postId: widget.postId,
            conversationId: conversationId,
            senderMemberId: currentMember.id,
          );

      ref.invalidate(conversationsProvider);
      setState(() => _sentConvId = conversationId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post envoyé !'),
            duration: Duration(seconds: 2),
            backgroundColor: AppColors.primaryContainer,
          ),
        );
        Navigator.of(context).pop();
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de l'envoi.")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncConversations = ref.watch(conversationsProvider);
    final searchQuery = _searchCtrl.text.toLowerCase();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.marginMobile,
              AppSpacing.stackSm,
              AppSpacing.marginMobile,
              0,
            ),
            child: Row(
              children: [
                const Icon(PhosphorIcons.paperPlaneTilt,
                    size: 20, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'Envoyer à...',
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(PhosphorIcons.x, size: 20),
                  color: AppColors.onSurfaceVariant,
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.marginMobile,
              AppSpacing.stackSm,
              AppSpacing.marginMobile,
              AppSpacing.stackSm,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                style: AppTextStyles.bodyMd.copyWith(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Rechercher un contact...',
                  hintStyle: TextStyle(
                    color: AppColors.outline,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(PhosphorIcons.magnifyingGlass,
                      color: AppColors.outline, size: 18),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  isDense: true,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          // Conversations list
          Flexible(
            child: asyncConversations.when(
              data: (conversations) {
                final filtered = searchQuery.isEmpty
                    ? conversations
                    : conversations
                        .where((c) =>
                            c.name.toLowerCase().contains(searchQuery))
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.stackLg),
                      child: Text(
                        searchQuery.isEmpty
                            ? 'Aucune conversation'
                            : 'Aucun résultat pour "$searchQuery"',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 0,
                    indent: 72,
                    color: AppColors.outlineVariant.withValues(alpha: 0.4),
                  ),
                  itemBuilder: (_, i) {
                    final conv = filtered[i];
                    final alreadySent = _sentConvId == conv.id;
                    return _ConversationShareTile(
                      conversation: conv,
                      isSending: _isSending && alreadySent,
                      alreadySent: alreadySent,
                      onTap: () => _sendToConversation(conv.id),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.stackLg),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.stackLg),
                  child: Text(
                    'Impossible de charger les conversations.',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
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

class _ConversationShareTile extends StatelessWidget {
  final Conversation conversation;
  final bool isSending;
  final bool alreadySent;
  final VoidCallback onTap;

  const _ConversationShareTile({
    required this.conversation,
    required this.isSending,
    required this.alreadySent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isSending ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.marginMobile,
          vertical: 10,
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                conversation.avatarUrl != null
                    ? CircleAvatar(
                        radius: 22,
                        backgroundImage: NetworkImage(conversation.avatarUrl!),
                      )
                    : Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: conversation.isGroup
                              ? AppColors.tertiaryFixed
                              : AppColors.primaryFixed,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            conversation.isGroup
                                ? PhosphorIcons.users
                                : PhosphorIcons.user,
                            size: 20,
                            color: conversation.isGroup
                                ? AppColors.tertiaryContainer
                                : AppColors.primaryContainer,
                          ),
                        ),
                      ),
                if (conversation.isGroup)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.tertiaryContainer,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                      child: const Icon(PhosphorIcons.users,
                          size: 8, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.stackMd),
            // Name + last message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.name,
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (conversation.lastMessage.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      conversation.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Send button
            if (isSending)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            else
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: alreadySent
                      ? AppColors.primaryFixed
                      : AppColors.primaryContainer.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  alreadySent ? PhosphorIcons.check : PhosphorIcons.paperPlaneTilt,
                  size: 16,
                  color: alreadySent
                      ? AppColors.primary
                      : AppColors.primaryContainer,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
