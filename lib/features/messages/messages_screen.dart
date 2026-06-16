import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/data/models/conversation.dart';
import '../../core/data/providers/data_providers.dart';
import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import 'conversation_detail_screen.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  RealtimeChannel? _msgChannel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _subscribeToNewMessages();
  }

  void _subscribeToNewMessages() {
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) return;

    _msgChannel = Supabase.instance.client
        .channel('conversations_list')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (_) {
            if (mounted) ref.invalidate(conversationsProvider);
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _msgChannel?.unsubscribe();
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncConversations = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.95),
        elevation: 0.5,
        titleSpacing: AppSpacing.marginMobile,
        leading: IconButton(
            icon: const Icon(PhosphorIcons.arrowLeft,
                color: AppColors.onSurfaceVariant, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        title: Text('Messages',
            style: AppTextStyles.headlineLg
                .copyWith(color: AppColors.onSurface, fontSize: 28)),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIcons.magnifyingGlass, color: AppColors.onSurfaceVariant),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(PhosphorIcons.dotsThree,
                color: AppColors.onSurfaceVariant),
            onPressed: () {},
            padding: const EdgeInsets.only(right: AppSpacing.marginMobile),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            labelStyle: AppTextStyles.labelMd
                .copyWith(fontWeight: FontWeight.w700),
            unselectedLabelStyle: AppTextStyles.labelMd
                .copyWith(fontWeight: FontWeight.w500),
            labelColor: AppColors.primaryContainer,
            unselectedLabelColor: AppColors.onSurfaceVariant,
            indicatorColor: AppColors.primaryContainer,
            indicatorWeight: 2.5,
            tabs: const [
              Tab(text: 'Messages Directs'),
              Tab(text: 'Groupes'),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: Colors.white,
        elevation: 3,
        child: const Icon(PhosphorIcons.pencilSimple),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.marginMobile),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: AppTextStyles.bodyMd,
                decoration: const InputDecoration(
                  hintText: 'Rechercher un message...',
                  hintStyle: TextStyle(color: AppColors.outline),
                  prefixIcon:
                      Icon(PhosphorIcons.magnifyingGlass, color: AppColors.outline, size: 20),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  isDense: true,
                ),
              ),
            ),
          ),
          // Tab content with Riverpod
          Expanded(
            child: asyncConversations.when(
              data: (conversations) {
                final direct = conversations
                    .where((c) => !c.isGroup)
                    .toList(growable: false);
                final groups = conversations
                    .where((c) => c.isGroup)
                    .toList(growable: false);

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Direct Messages
                    direct.isEmpty
                        ? const _EmptyMessagesState()
                        : ListView.separated(
                            padding: const EdgeInsets.only(
                                bottom: AppSpacing.bottomNavHeight + 80),
                            itemCount: direct.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 0,
                              indent: 80,
                              color: AppColors.outlineVariant
                                  .withValues(alpha: 0.5),
                            ),
                            itemBuilder: (_, i) => _ConversationTile(
                              conversation: direct[i],
                            ),
                          ),
                    // Groups
                    groups.isEmpty
                        ? const _EmptyMessagesState()
                        : ListView.separated(
                            padding: const EdgeInsets.only(
                                bottom: AppSpacing.bottomNavHeight + 80),
                            itemCount: groups.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 0,
                              indent: 80,
                              color: AppColors.outlineVariant
                                  .withValues(alpha: 0.5),
                            ),
                            itemBuilder: (_, i) => _ConversationTile(
                              conversation: groups[i],
                            ),
                          ),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.stackLg),
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.stackLg),
                  child: Text(
                    e is AppException
                        ? e.message
                        : 'Impossible de charger les messages.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMd
                        .copyWith(color: AppColors.onSurfaceVariant),
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

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  const _ConversationTile({required this.conversation});

  Widget _buildActiveCallBadge() {
    final icon = conversation.isGroupCall
        ? PhosphorIcons.users
        : PhosphorIcons.phone;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(
          'Appel en cours',
          style: AppTextStyles.labelSm.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ConversationDetailScreen(
              conversationId: conversation.id,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.marginMobile, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                conversation.isGroup || conversation.avatarUrl == null
                    ? Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryFixed,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            conversation.name.substring(0, 1),
                            style: AppTextStyles.headlineLgMobile.copyWith(
                              color: AppColors.primaryContainer,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      )
                    : CircleAvatar(
                        radius: 26,
                        backgroundImage:
                            NetworkImage(conversation.avatarUrl!),
                      ),
                // Online indicator (direct only)
                if (!conversation.isGroup)
                  Positioned(
                    bottom: 1,
                    right: 1,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.surface, width: 2),
                      ),
                    ),
                  ),
              ],
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
                          conversation.name,
                          style: AppTextStyles.labelMd.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: conversation.unread > 0
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        conversation.time,
                        style: AppTextStyles.labelSm.copyWith(
                          color: conversation.unread > 0
                              ? AppColors.primaryContainer
                              : AppColors.onSurfaceVariant,
                          fontWeight: conversation.unread > 0
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      // Read receipt
                      if (conversation.isRead &&
                          conversation.unread == 0 &&
                          !conversation.isCallActive)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(PhosphorIcons.checks,
                              size: 14,
                              color: AppColors.primaryContainer),
                        ),
                      Expanded(
                        child: conversation.isCallActive
                            ? _buildActiveCallBadge()
                            : Text(
                                conversation.lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodyMd.copyWith(
                                  color: conversation.unread > 0
                                      ? AppColors.onSurface
                                      : AppColors.onSurfaceVariant,
                                  fontWeight: conversation.unread > 0
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  fontSize: 13,
                                ),
                              ),
                      ),
                      if (conversation.unread > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${conversation.unread}',
                              style: AppTextStyles.labelSm.copyWith(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMessagesState extends StatelessWidget {
  const _EmptyMessagesState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(PhosphorIcons.chatCircle,
              size: 64, color: AppColors.outlineVariant),
          const SizedBox(height: AppSpacing.stackMd),
          Text('Aucun message pour l\'instant.',
              style: AppTextStyles.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.stackMd),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(PhosphorIcons.pencilSimple, size: 16),
            label: const Text('Nouvelle conversation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
