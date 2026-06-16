// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show RealtimeChannel, PostgresChangeEvent, Supabase;
import '../../features/home/home_screen.dart';
import '../../features/home/create_post_screen.dart';
import '../../features/events/create_event_screen.dart';
import '../../features/jobs/create_job_screen.dart';
import '../../features/marketplace/create_service_screen.dart';
import '../../features/map/world_map_screen.dart';
import '../../features/messages/messages_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../data/providers/data_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class MainShell extends ConsumerStatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late int _tabIndex;
  late final List<Widget> _screens;
  RealtimeChannel? _msgRealtimeChannel;

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialIndex;
    _screens = <Widget>[
      HomeScreen(key: ValueKey('tab_home')),
      WorldMapScreen(key: ValueKey('tab_map')),
      MessagesScreen(key: ValueKey('tab_messages')),
      ProfileScreen(key: ValueKey('tab_profile')),
    ];
    _subscribeToMessageRealtime();
  }

  void _subscribeToMessageRealtime() {
    _msgRealtimeChannel = Supabase.instance.client
        .channel('main_shell_messages')
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
    _msgRealtimeChannel?.unsubscribe();
    super.dispose();
  }

  int _toStackIndex(int visualIndex) {
    if (visualIndex < 2) return visualIndex;
    if (visualIndex == 2) return -1; // publish button
    return visualIndex - 1;
  }

  int _currentStackIndex() => _toStackIndex(_tabIndex);

  void _onVisualTap(int visualIndex) {
    if (visualIndex == 2) {
      _showCreateMenu();
      return;
    }
    setState(() => _tabIndex = visualIndex);
  }

  void _showCreateMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: SingleChildScrollView(
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
                'Créer',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Choisissez le type de contenu à publier',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              _CreateOption(
                icon: PhosphorIcons.article,
                color: AppColors.primary,
                title: 'Publication',
                subtitle: 'Partager une actualité, photo ou réflexion',
                onTap: () {
                  Navigator.pop(ctx);
                  _openCreateScreen(
                    () => CreatePostScreen(),
                    () => ref.invalidate(postsProvider),
                  );
                },
              ),
              _CreateOption(
                icon: PhosphorIcons.calendarBlank,
                color: AppColors.tertiary,
                title: 'Événement',
                subtitle: 'Organiser une rencontre ou activité',
                onTap: () {
                  Navigator.pop(ctx);
                  _openCreateScreen(
                    () => CreateEventScreen(),
                    () => ref.invalidate(eventsProvider),
                  );
                },
              ),
              _CreateOption(
                icon: PhosphorIcons.briefcase,
                color: AppColors.secondary,
                title: "Offre d'emploi",
                subtitle: 'Publier une opportunité professionnelle',
                onTap: () {
                  Navigator.pop(ctx);
                  _openCreateScreen(
                    () => CreateJobScreen(),
                    () => ref.invalidate(jobsProvider),
                  );
                },
              ),
              _CreateOption(
                icon: PhosphorIcons.storefront,
                color: const Color(0xFFE8A838),
                title: 'Service / Annonce',
                subtitle: 'Proposer un service ou publier une annonce',
                onTap: () {
                  Navigator.pop(ctx);
                  _openCreateScreen(
                    () => CreateServiceScreen(),
                    () => ref.invalidate(servicesProvider),
                  );
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Future<void> _openCreateScreen(
    Widget Function() pageBuilder,
    VoidCallback onCreated,
  ) async {
    final created = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => pageBuilder(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.15),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            )),
            child: FadeTransition(
              opacity:
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
    if (created == true && mounted) {
      onCreated();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentStackIndex(),
        children: _screens,
      ),
      bottomNavigationBar: _PremiumBottomNav(
        currentVisualIndex: _tabIndex,
        onTap: _onVisualTap,
      ),
    );
  }
}

class _PremiumBottomNav extends ConsumerWidget {
  final int currentVisualIndex;
  final ValueChanged<int> onTap;

  const _PremiumBottomNav({
    required this.currentVisualIndex,
    required this.onTap,
  });

  static const    _tabs = [
    _NavTab(icon: PhosphorIcons.house, filledIcon: PhosphorIcons.houseFill, label: 'Accueil'),
    _NavTab(icon: PhosphorIcons.mapPin, filledIcon: PhosphorIcons.mapPinFill, label: 'Carte'),
    _NavTab(icon: PhosphorIcons.chatsTeardrop, filledIcon: PhosphorIcons.chatsTeardropFill, label: 'Messages'),
    _NavTab(icon: PhosphorIcons.user, filledIcon: PhosphorIcons.userFill, label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    final conversationsAsync = ref.watch(conversationsProvider);
    final unreadCount = conversationsAsync.whenOrNull(
          data: (convs) => convs.where((c) => !c.isRead).length,
        ) ??
        0;

    return Container(
      height: AppSpacing.bottomNavHeight + bottomPad,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(
            color: Colors.black.withValues(alpha: 0.08),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPad),
        child: Row(
          children: [
            _NavItem(
              tab: _tabs[0],
              isActive: currentVisualIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavItem(
              tab: _tabs[1],
              isActive: currentVisualIndex == 1,
              onTap: () => onTap(1),
            ),
            _PublishButton(onTap: () => onTap(2)),
            _NavItem(
              tab: _tabs[2],
              isActive: currentVisualIndex == 3,
              onTap: () => onTap(3),
              badgeCount: unreadCount,
            ),
            _NavItem(
              tab: _tabs[3],
              isActive: currentVisualIndex == 4,
              onTap: () => onTap(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTab {
  final IconData icon;
  final IconData filledIcon;
  final String label;
  const _NavTab({required this.icon, required this.filledIcon, required this.label});
}

class _NavItem extends StatefulWidget {
  final _NavTab tab;
  final bool isActive;
  final VoidCallback onTap;
  final int badgeCount;

  const _NavItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    if (widget.badgeCount > 0) {
      _bounceCtrl.value = 1.0;
    }
    _bounceAnim = CurvedAnimation(
      parent: _bounceCtrl,
      curve: Curves.elasticOut,
    );
  }

  @override
  void didUpdateWidget(covariant _NavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger bounce when badge count increases (new notification)
    if (widget.badgeCount > oldWidget.badgeCount) {
      _bounceCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFDC3545),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        widget.badgeCount > 99 ? '99+' : '${widget.badgeCount}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1.2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: widget.isActive ? AppColors.primaryFixed : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.isActive ? widget.tab.filledIcon : widget.tab.icon,
                    size: 22,
                    color: widget.isActive ? AppColors.primary : const Color(0xFFBBBBBB),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.tab.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9,
                      fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                      color: widget.isActive ? AppColors.primary : const Color(0xFFBBBBBB),
                    ),
                  ),
                ],
              ),
              if (widget.badgeCount > 0)
                Positioned(
                  top: -1,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ScaleTransition(
                      scale: _bounceAnim,
                      child: _buildBadge(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublishButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PublishButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Container(
              width: 42,
              height: 42,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                PhosphorIcons.plus,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Publier',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Color(0xFFBBBBBB),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CreateOption({
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
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'Inter',
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
