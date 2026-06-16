// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/data/models/call_entry.dart';
import '../../core/data/models/community.dart';
import '../../core/data/models/conversation.dart';
import '../../core/data/providers/data_providers.dart';
import '../../core/errors/app_exception.dart';
import '../../core/navigation/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';

import 'conversation_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MessagesScreen — Premium WhatsApp-style redesign
// ─────────────────────────────────────────────────────────────────────────────

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _searchCtrl = TextEditingController();
  bool _searching = false;
  String _query = '';
  RealtimeChannel? _msgChannel;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _searchCtrl.addListener(
        () => setState(() => _query = _searchCtrl.text.toLowerCase()));
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
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Conversation> _filter(List<Conversation> source) {
    if (_query.isEmpty) return source;
    return source
        .where((c) => c.name.toLowerCase().contains(_query))
        .toList(growable: false);
  }

  List<CallEntry> _filterCalls(List<CallEntry> source) {
    if (_query.isEmpty) return source;
    return source
        .where((c) => c.otherMemberName.toLowerCase().contains(_query))
        .toList(growable: false);
  }

  void _showFabMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Nouveau',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              _FabOption(
                icon: PhosphorIcons.usersThree,
                color: AppColors.purple,
                title: 'Créer une communauté',
                subtitle: "Rassemble des Fulɓe autour d'un thème",
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pushNamed(AppRoutes.createCommunity);
                },
              ),
              _FabOption(
                icon: PhosphorIcons.compass,
                color: const Color(0xFF8B5CF6),
                title: 'Explorer les communautés',
                subtitle: 'Découvrir et rejoindre des groupes',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pushNamed(AppRoutes.communities);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncConversations = ref.watch(conversationsProvider);
    final asyncCommunities = ref.watch(communitiesProvider);
    final asyncCallHistory = ref.watch(callHistoryProvider);

    final unreadCounts = ref.watch(communityUnreadCountsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: asyncConversations.when(
        data: (conversations) {
          final direct = _filter(conversations);

          return TabBarView(
            controller: _tabs,
            children: [
              _ConversationList(conversations: direct, query: _query),
              asyncCommunities.when(
                data: (all) => _CommunityList(
                  communities: all.where((c) => c.isMember).toList(),
                  unreadCounts: unreadCounts,
                  query: _query,
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
                error: (_, __) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIcons.usersThree,
                          size: 48, color: AppColors.outlineVariant),
                      const SizedBox(height: 12),
                      const Text(
                        'Impossible de charger les communautés.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              asyncCallHistory.when(
                data: (calls) => _CallHistoryList(
                    calls: _filterCalls(calls), query: _query),
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
                error: (e, _) {
                  debugPrint('[MessagesScreen] Erreur historique appels: $e');
                  final msg = e is AppException
                      ? e.message
                      : 'Impossible de charger les appels.\nV\u00e9rifiez votre connexion.';
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        msg,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () => _showFabMenu(context),
        tooltip: 'Nouveau',
        child: const Icon(PhosphorIcons.plus, size: 24),
      ),
    );
  }

  // ── AppBar premium ────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(112),
      child: Container(
        color: AppColors.surface,
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title row
              SizedBox(
                height: 56,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      if (_searching) ...[
                        // Inline search field
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            autofocus: true,
                            style: const TextStyle(
                                fontSize: 16, color: AppColors.onSurface),
                            decoration: const InputDecoration(
                              hintText: 'Rechercher...',
                              hintStyle: TextStyle(
                                  color: AppColors.outlineVariant,
                                  fontSize: 16),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 12),
                              prefixIcon: Icon(PhosphorIcons.magnifyingGlass,
                                  color: AppColors.onSurfaceVariant,
                                  size: 20),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(PhosphorIcons.x,
                              color: AppColors.onSurfaceVariant, size: 20),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searching = false);
                          },
                        ),
                      ] else ...[
                        // Brand + logo
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Image.asset(
                            AppConstants.logoAsset,
                            width: 26,
                            height: 26,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Container(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Fulɓe Connect',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(PhosphorIcons.magnifyingGlass,
                              color: AppColors.onSurfaceVariant, size: 20),
                          onPressed: () =>
                              setState(() => _searching = true),
                        ),
                        IconButton(
                          icon: const Icon(PhosphorIcons.dotsThreeVertical,
                              color: AppColors.onSurfaceVariant, size: 20),
                          onPressed: () {},
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // TabBar
              TabBar(
                controller: _tabs,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.onSurfaceVariant,
                indicatorColor: AppColors.primary,
                indicatorWeight: 2.5,
                labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8),
                unselectedLabelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.8),
                tabs: const [
                  Tab(text: 'DISCUSSIONS'),
                  Tab(text: 'COMMUNAUTÉS'),
                  Tab(text: 'APPELS'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Conversation List ───────────────────────────────────────────────────────

class _ConversationList extends StatelessWidget {
  final List<Conversation> conversations;
  final String query;
  const _ConversationList({
    required this.conversations,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    if (conversations.isEmpty) {
      return _EmptyState(query: query);
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.bottomNavHeight + 80),
      itemCount: conversations.length,
      itemBuilder: (_, i) =>
          _ConversationTile(conversation: conversations[i]),
    );
  }
}

// ── Conversation Tile ───────────────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  const _ConversationTile({required this.conversation});

  bool get _hasUnread => conversation.unread > 0;
  bool get _isVoice => conversation.lastMessage.startsWith('\u{1F399}\u{FE0F}');

  static const _groupColors = [
    Color(0xFF16A34A),
    Color(0xFFDC2626),
    Color(0xFFE8A838),
    Color(0xFF8B5CF6),
    Color(0xFF0EA5E9),
    Color(0xFFF97316),
  ];

  Color get _groupColor {
    final hash = conversation.name.hashCode;
    return _groupColors[hash.abs() % _groupColors.length];
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
      onLongPress: () => _showContextMenu(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _hasUnread && conversation.isGroup
              ? AppColors.primaryFixed.withValues(alpha: 0.3)
              : Colors.transparent,
          border: const Border(
            bottom: BorderSide(
                color: AppColors.outlineVariant, width: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAvatar(),
            const SizedBox(width: 14),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  // ── Avatar ────────────────────────────────────────────────────────────────

  Widget _buildAvatar() {
    if (conversation.isGroup) {
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: _groupColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          PhosphorIcons.users,
          color: Colors.white,
          size: 22,
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryFixed,
          ),
          clipBehavior: Clip.antiAlias,
          child: conversation.avatarUrl != null
              ? Image.network(
                  conversation.avatarUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _directAvatarFallback(),
                )
              : _directAvatarFallback(),
        ),
        Positioned(
          bottom: 1,
          right: 1,
          child: Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E),
              shape: BoxShape.circle,
              border:
                  Border.all(color: AppColors.surface, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _directAvatarFallback() {
    final letter = conversation.name.isNotEmpty
        ? conversation.name[0].toUpperCase()
        : '?';
    return Center(
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }

  // ── Content ───────────────────────────────────────────────────────────────

  Widget _buildContent() {
    if (conversation.isGroup) {
      // Style communauté pour les groupes
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  conversation.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        _hasUnread ? FontWeight.w700 : FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${conversation.memberCount} membres',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      _hasUnread ? FontWeight.w600 : FontWeight.w400,
                  color: _hasUnread
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Expanded(
                child: Text(
                  conversation.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        _hasUnread ? FontWeight.w500 : FontWeight.w400,
                    color: _hasUnread
                        ? AppColors.onSurface
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              if (_hasUnread) ...[
                const SizedBox(width: 8),
                _buildBadge(),
              ],
            ],
          ),
        ],
      );
    }

    // Style direct (inchangé)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                conversation.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      _hasUnread ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              conversation.time,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    _hasUnread ? FontWeight.w600 : FontWeight.w400,
                color: _hasUnread
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!_hasUnread && conversation.isRead) ...[
              _buildCheckmark(),
              const SizedBox(width: 4),
            ],
            Expanded(child: _buildDirectPreview()),
            const SizedBox(width: 8),
            if (_hasUnread)
              _buildBadge()
            else
              const SizedBox(width: 20),
          ],
        ),
      ],
    );
  }

  // ── Checkmark (delivery/read status) ─────────────────────────────────────

  Widget _buildCheckmark() {
    return Icon(
      PhosphorIcons.checks,
      size: 16,
      color: AppColors.primary,
    );
  }

  // ── Preview for direct conversations ─────────────────────────────────

  Widget _buildDirectPreview() {
    // Active call badge
    if (conversation.isCallActive) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            conversation.isGroupCall
                ? PhosphorIcons.users
                : PhosphorIcons.phone,
            size: 14,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            'Appel en cours',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    // Voice message
    if (_isVoice) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIcons.microphone,
            size: 14,
            color: _hasUnread ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            'Message vocal',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color:
                  _hasUnread ? AppColors.onSurface : AppColors.onSurfaceVariant,
              fontWeight:
                  _hasUnread ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
      );
    }

    // Group message: show sender name in green
    if (conversation.isGroup) {
      return RichText(
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        text: TextSpan(
          style: TextStyle(
            fontSize: 14,
            color:
                _hasUnread ? AppColors.onSurface : AppColors.onSurfaceVariant,
            fontWeight:
                _hasUnread ? FontWeight.w500 : FontWeight.w400,
          ),
          children: [
            TextSpan(text: conversation.lastMessage),
          ],
        ),
      );
    }

    return Text(
      conversation.lastMessage,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      style: TextStyle(
        fontSize: 14,
        color:
            _hasUnread ? AppColors.onSurface : AppColors.onSurfaceVariant,
        fontWeight: _hasUnread ? FontWeight.w500 : FontWeight.w400,
      ),
    );
  }

  // ── Unread badge ─────────────────────────────────────────────────────────

  Widget _buildBadge() {
    final count = conversation.unread;
    final label = count > 99 ? '99+' : count.toString();
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ── Context menu (long press) ────────────────────────────────────────────

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ContextMenuSheet(name: conversation.name),
    );
  }
}

// ── Context Menu Bottom Sheet ───────────────────────────────────────────────

class _ContextMenuSheet extends StatelessWidget {
  final String name;
  const _ContextMenuSheet({required this.name});

  static const _items = [
    (PhosphorIcons.bellSimpleSlash, 'Mettre en sourdine'),
    (PhosphorIcons.archiveBox, 'Archiver'),
    (PhosphorIcons.pushPin, 'Épingler'),
    (PhosphorIcons.chatCircle, 'Marquer comme non lu'),
    (PhosphorIcons.trash, 'Supprimer'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
        ),
        const Divider(
            color: AppColors.outlineVariant, height: 1),
        ..._items.map(
          (item) => ListTile(
            leading: Icon(item.$1,
                color: AppColors.primary, size: 22),
            title: Text(
              item.$2,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.onSurface),
            ),
            onTap: () => Navigator.pop(context),
            dense: true,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ── Call History List ───────────────────────────────────────────────────────

class _CallHistoryList extends StatelessWidget {
  final List<CallEntry> calls;
  final String query;
  const _CallHistoryList({required this.calls, required this.query});

  @override
  Widget build(BuildContext context) {
    if (calls.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              query.isNotEmpty
                  ? PhosphorIcons.magnifyingGlass
                  : PhosphorIcons.phoneCall,
              size: 48,
              color: AppColors.outlineVariant,
            ),
            const SizedBox(height: 12),
            Text(
              query.isNotEmpty
                  ? 'Aucun r\u00e9sultat pour "$query"'
                  : 'Aucun appel pour l\'instant.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.bottomNavHeight + 80),
      itemCount: calls.length,
      itemBuilder: (_, i) => _CallTile(call: calls[i]),
    );
  }
}

// ── Call Tile ───────────────────────────────────────────────────────────────

class _CallTile extends StatelessWidget {
  final CallEntry call;
  const _CallTile({required this.call});

  bool get _isMissed => call.status == CallEntryStatus.missed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ConversationDetailScreen(
              conversationId: call.conversationId,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
                color: AppColors.outlineVariant, width: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAvatar(),
            const SizedBox(width: 14),
            Expanded(child: _buildContent()),
            const SizedBox(width: 8),
            _buildCallTypeIcon(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryFixed,
      ),
      clipBehavior: Clip.antiAlias,
      child: call.otherMemberAvatarUrl != null
          ? Image.network(
              call.otherMemberAvatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _avatarFallback(),
            )
          : _avatarFallback(),
    );
  }

  Widget _avatarFallback() {
    final letter = call.otherMemberName.isNotEmpty
        ? call.otherMemberName[0].toUpperCase()
        : '?';
    return Center(
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            // Direction arrow
            Icon(
              call.isOutgoing
                  ? PhosphorIcons.arrowUpRight
                  : PhosphorIcons.arrowDownLeft,
              size: 14,
              color: _isMissed
                  ? AppColors.error
                  : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                call.otherMemberName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _isMissed
                      ? AppColors.error
                      : AppColors.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatTimestamp(call.createdAt),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: _isMissed
                    ? AppColors.error
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            const SizedBox(width: 20), // align with text above
            Icon(
              call.callType == 'video'
                  ? PhosphorIcons.videoCamera
                  : PhosphorIcons.phone,
              size: 14,
              color: _isMissed
                  ? AppColors.error
                  : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              _statusLabel(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: _isMissed
                    ? AppColors.error
                    : AppColors.onSurfaceVariant,
              ),
            ),
            if (call.durationFormatted != null) ...[
              const Text(
                ' \u00b7 ',
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant),
              ),
              Text(
                call.durationFormatted!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCallTypeIcon() {
    return Icon(
      call.callType == 'video'
          ? PhosphorIcons.videoCamera
          : PhosphorIcons.phone,
      size: 20,
      color: _isMissed ? AppColors.error : AppColors.primary,
    );
  }

  String _statusLabel() {
    switch (call.status) {
      case CallEntryStatus.missed:
        return 'Appel manqu\u00e9';
      case CallEntryStatus.ended:
        return call.isOutgoing ? 'Appel sortant' : 'Appel entrant';
      case CallEntryStatus.rejected:
        return call.isOutgoing ? 'Appel refus\u00e9' : 'Vous avez refus\u00e9';
      case CallEntryStatus.cancelled:
        return 'Appel annul\u00e9';
    }
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return "\u00c0 l'instant";
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return '${diff.inDays}j';
    return '${dt.day}/${dt.month.toString().padLeft(2, '0')}';
  }
}

// ── Empty state ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    final isSearching = query.isNotEmpty;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSearching
                ? PhosphorIcons.magnifyingGlass
                : PhosphorIcons.chatCircle,
            size: 48,
            color: AppColors.outlineVariant,
          ),
          const SizedBox(height: 12),
          Text(
            isSearching
                ? 'Aucun r\u00e9sultat pour "$query"'
                : "Pas encore de discussion.\nCommencez avec un Ful\u0253e !",
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.onSurfaceVariant, fontSize: 14),
          ),
          if (!isSearching) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(PhosphorIcons.plus, size: 16),
              label: const Text('Nouvelle discussion'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Community List (onglet COMMUNAUTÉS) ─────────────────────────────────────

class _CommunityList extends StatelessWidget {
  final List<Community> communities;
  final Map<String, int> unreadCounts;
  final String query;
  const _CommunityList({
    required this.communities,
    required this.unreadCounts,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered();
    if (filtered.isEmpty) {
      return _CommunityEmptyState(query: query);
    }
    return Column(
      children: [
        // Create community card at top
        _CreateCommunityCard(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(
                bottom: AppSpacing.bottomNavHeight + 80),
            itemCount: filtered.length,
            itemBuilder: (_, i) => _CommunityTile(
              community: filtered[i],
              unreadCount: unreadCounts[filtered[i].id] ?? 0,
            ),
          ),
        ),
      ],
    );
  }

  List<Community> _filtered() {
    if (query.isEmpty) return communities;
    return communities
        .where((c) => c.name.toLowerCase().contains(query))
        .toList(growable: false);
  }
}

class _CreateCommunityCard extends StatelessWidget {
  const _CreateCommunityCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context)
              .pushNamed(AppRoutes.createCommunity),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryFixed.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    PhosphorIcons.plus,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Créer une communauté',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Rassemble des Fulɓe autour d\'un thème',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  PhosphorIcons.caretRight,
                  size: 16,
                  color: AppColors.outlineVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CommunityEmptyState extends StatelessWidget {
  final String query;
  const _CommunityEmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    final isSearching = query.isNotEmpty;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSearching
                ? PhosphorIcons.magnifyingGlass
                : PhosphorIcons.usersThree,
            size: 48,
            color: AppColors.outlineVariant,
          ),
          const SizedBox(height: 12),
          Text(
            isSearching
                ? 'Aucune communauté pour "$query"'
                : "Tu n'es encore membre\nd'aucune communauté.",
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.onSurfaceVariant, fontSize: 14),
          ),
          if (!isSearching) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.createCommunity);
              },
              icon: const Icon(PhosphorIcons.plus, size: 16),
              label: const Text('Créer une communauté'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.communities);
              },
              icon: const Icon(PhosphorIcons.compass, size: 16),
              label: const Text('Explorer les communautés'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.outlineVariant),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── FAB Menu Option ────────────────────────────────────────────────────────

class _FabOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FabOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(PhosphorIcons.caretRight,
                    size: 16, color: AppColors.outlineVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CommunityTile extends StatelessWidget {
  final Community community;
  final int unreadCount;
  const _CommunityTile({
    required this.community,
    this.unreadCount = 0,
  });

  bool get _hasUnread => unreadCount > 0;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamed(
          AppRoutes.communityDetail,
          arguments: community.id,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _hasUnread
              ? AppColors.primaryFixed.withValues(alpha: 0.3)
              : Colors.transparent,
          border: const Border(
            bottom: BorderSide(
                color: AppColors.outlineVariant, width: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar — icône de catégorie sur fond coloré
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _categoryColor(community.category),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _categoryIcon(community.category),
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          community.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                _hasUnread ? FontWeight.w700 : FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${community.memberCount} membres',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              _hasUnread ? FontWeight.w600 : FontWeight.w400,
                          color: _hasUnread
                              ? AppColors.primary
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          community.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                _hasUnread ? FontWeight.w500 : FontWeight.w400,
                            color: _hasUnread
                                ? AppColors.onSurface
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (_hasUnread) ...[
                        const SizedBox(width: 8),
                        _buildBadge(),
                      ],
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

  Widget _buildBadge() {
    final label = unreadCount > 99 ? '99+' : unreadCount.toString();
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
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


