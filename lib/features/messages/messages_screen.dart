import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';

class _Conversation {
  final String id;
  final String name;
  final String? avatarUrl;
  final String lastMessage;
  final String time;
  final int unread;
  final bool isRead;

  const _Conversation({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.lastMessage,
    required this.time,
    this.unread = 0,
    this.isRead = true,
  });
}

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();

  static const _directConversations = [
    _Conversation(
      id: 'c1',
      name: 'Amadou Diallo',
      avatarUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&q=80',
      lastMessage: 'Super ! Je te rappelle dès que possible pour discuter du projet.',
      time: '14:32',
      unread: 3,
      isRead: false,
    ),
    _Conversation(
      id: 'c2',
      name: 'Dr. Aïssatou Sow',
      avatarUrl:
          'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=150&h=150&fit=crop&q=80',
      lastMessage: 'Merci pour les documents, je les ai bien reçus.',
      time: '11:18',
      unread: 0,
      isRead: true,
    ),
    _Conversation(
      id: 'c3',
      name: 'Ousmane Baldé',
      avatarUrl:
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&q=80',
      lastMessage: 'On se voit à l\'événement de Paris la semaine prochaine ?',
      time: 'Hier',
      unread: 0,
      isRead: true,
    ),
    _Conversation(
      id: 'c4',
      name: 'Fatou Barry',
      avatarUrl:
          'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=150&h=150&fit=crop&q=80',
      lastMessage: 'J\'ai partagé le lien de l\'événement avec l\'équipe.',
      time: 'Lun',
      unread: 0,
      isRead: true,
    ),
  ];

  static const _groupConversations = [
    _Conversation(
      id: 'g1',
      name: '🇸🇳 Peuls au Sénégal',
      lastMessage: 'Ibrahima: Nouvelle annonce pour les membres de Dakar !',
      time: '09:15',
      unread: 12,
      isRead: false,
    ),
    _Conversation(
      id: 'g2',
      name: '💼 Network Entrepreneurs',
      lastMessage: 'Mamadou: Qui participe au forum de la semaine prochaine ?',
      time: 'Hier',
      unread: 4,
      isRead: false,
    ),
    _Conversation(
      id: 'g3',
      name: '📚 Club de Lecture Pulaar',
      lastMessage: 'Admin: Le livre du mois de juillet a été annoncé !',
      time: 'Dim',
      unread: 0,
      isRead: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.95),
        elevation: 0.5,
        titleSpacing: AppSpacing.marginMobile,
        automaticallyImplyLeading: false,
        title: Text('Messages',
            style: AppTextStyles.headlineLg
                .copyWith(color: AppColors.onSurface, fontSize: 28)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.onSurfaceVariant),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert,
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
        child: const Icon(Icons.edit_outlined),
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
                      Icon(Icons.search, color: AppColors.outline, size: 20),
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
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Direct Messages
                _directConversations.isEmpty
                    ? _EmptyMessagesState()
                    : ListView.separated(
                        padding: const EdgeInsets.only(
                            bottom: AppSpacing.bottomNavHeight + 80),
                        itemCount: _directConversations.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 0,
                          indent: 80,
                          color: AppColors.outlineVariant.withValues(alpha: 0.5),
                        ),
                        itemBuilder: (_, i) => _ConversationTile(
                          conversation: _directConversations[i],
                          isGroup: false,
                        ),
                      ),
                // Groups
                _groupConversations.isEmpty
                    ? _EmptyMessagesState()
                    : ListView.separated(
                        padding: const EdgeInsets.only(
                            bottom: AppSpacing.bottomNavHeight + 80),
                        itemCount: _groupConversations.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 0,
                          indent: 80,
                          color: AppColors.outlineVariant.withValues(alpha: 0.5),
                        ),
                        itemBuilder: (_, i) => _ConversationTile(
                          conversation: _groupConversations[i],
                          isGroup: true,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final _Conversation conversation;
  final bool isGroup;
  const _ConversationTile(
      {required this.conversation, required this.isGroup});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.marginMobile, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                isGroup || conversation.avatarUrl == null
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
                // Online indicator
                if (!isGroup)
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
                      if (conversation.isRead && conversation.unread == 0)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.done_all,
                              size: 14,
                              color: AppColors.primaryContainer),
                        ),
                      Expanded(
                        child: Text(
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
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline,
              size: 64, color: AppColors.outlineVariant),
          const SizedBox(height: AppSpacing.stackMd),
          Text('Aucun message pour l\'instant.',
              style: AppTextStyles.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.stackMd),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit_outlined, size: 16),
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
