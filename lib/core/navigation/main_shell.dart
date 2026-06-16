// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/create_post_screen.dart';
import '../../features/events/create_event_screen.dart';
import '../../features/jobs/create_job_screen.dart';
import '../../features/marketplace/create_service_screen.dart';
import '../../features/map/world_map_screen.dart';
import '../../features/directory/directory_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../data/providers/data_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Main shell with premium bottom navigation bar and central elevated
/// publish button.
class MainShell extends ConsumerStatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late int _tabIndex;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // initialIndex 0-4 maps to visual tabs: 0=Home, 1=Map, 2=Publish(gap),
    // 3=Directory, 4=Profile
    _tabIndex = widget.initialIndex;
    // Chaque instance de _MainShellState possède SA propre liste d'écrans
    // pour éviter les conflits d'éléments quand un nouveau MainShell est
    // poussé comme route (ex: appui sur avatar → /profile).
    // IMPORTANT: PAS de `const` ici — deux MainShell coexistent dans l'arbre
    // (le tab original + la route /profile poussée par-dessus) et des widgets
    // const partagés violent l'assertion '_elements.contains(element)'.
    _screens = <Widget>[
      HomeScreen(key: ValueKey('tab_home')),
      WorldMapScreen(key: ValueKey('tab_map')),
      DirectoryScreen(key: ValueKey('tab_directory')),
      ProfileScreen(key: ValueKey('tab_profile')),
    ];
  }

  /// Maps visual tab index → IndexedStack child index.
  /// Visual indices: 0=Home→0, 1=Map→1, 2=Publish→(none), 3=Annuaire→2, 4=Profil→3
  int _toStackIndex(int visualIndex) {
    if (visualIndex < 2) return visualIndex;
    if (visualIndex == 2) return -1; // publish button
    return visualIndex - 1;
  }

  int _currentStackIndex() => _toStackIndex(_tabIndex);

  void _onVisualTap(int visualIndex) {
    if (visualIndex == 2) {
      // Publish button — show creation menu
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
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
                title: 'Offre d\'emploi',
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

// ── Premium Bottom Navigation ────────────────────────────────────────────────

class _PremiumBottomNav extends StatelessWidget {
  final int currentVisualIndex;
  final ValueChanged<int> onTap;

  const _PremiumBottomNav({
    required this.currentVisualIndex,
    required this.onTap,
  });

  static const _tabs = [
    _NavTab(icon: PhosphorIcons.house, filledIcon: PhosphorIcons.houseFill, label: 'Accueil'),
    _NavTab(icon: PhosphorIcons.mapPin, filledIcon: PhosphorIcons.mapPinFill, label: 'Carte'),
    _NavTab(icon: PhosphorIcons.addressBook, filledIcon: PhosphorIcons.addressBookFill, label: 'Annuaire'),
    _NavTab(icon: PhosphorIcons.user, filledIcon: PhosphorIcons.userFill, label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

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
            // Tab 0 — Home
            _NavItem(
              tab: _tabs[0],
              isActive: currentVisualIndex == 0,
              onTap: () => onTap(0),
            ),
            // Tab 1 — Map
            _NavItem(
              tab: _tabs[1],
              isActive: currentVisualIndex == 1,
              onTap: () => onTap(1),
            ),
            // Center — Publish button
            _PublishButton(onTap: () => onTap(2)),
            // Tab 3 (visual) → stack index 2 — Annuaire
            _NavItem(
              tab: _tabs[2],
              isActive: currentVisualIndex == 3,
              onTap: () => onTap(3),
            ),
            // Tab 4 (visual) → stack index 3 — Profil
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

class _NavItem extends StatelessWidget {
  final _NavTab tab;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryFixed : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? tab.filledIcon : tab.icon,
                size: 22,
                color: isActive ? AppColors.primary : const Color(0xFFBBBBBB),
              ),
              const SizedBox(height: 2),
              Text(
                tab.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? AppColors.primary : const Color(0xFFBBBBBB),
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

// ─────────────────────────────────────────────────────────────────────────────
// _CreateOption — option du menu de création
// ─────────────────────────────────────────────────────────────────────────────

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
