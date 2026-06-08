import 'package:flutter/material.dart';
import '../../features/home/home_screen.dart';
import '../../features/map/world_map_screen.dart';
import '../../features/directory/directory_screen.dart';
import '../../features/marketplace/marketplace_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

/// Navigation indices
enum NavTab { home, map, directory, market, profile }

/// Main shell with persistent bottom navigation bar.
/// Uses IndexedStack to keep all tab states alive.
class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Accueil'),
    _NavItem(icon: Icons.map_outlined, activeIcon: Icons.map, label: 'Carte'),
    _NavItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Annuaire'),
    _NavItem(icon: Icons.storefront_outlined, activeIcon: Icons.storefront, label: 'Marché'),
    _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profil'),
  ];

  final List<Widget> _screens = const [
    HomeScreen(),
    WorldMapScreen(),
    DirectoryScreen(),
    MarketplaceScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _AppBottomNav(
        currentIndex: _currentIndex,
        items: _items,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _AppBottomNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.bottomNavHeight +
          MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.5),
            width: 0.8,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom,
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isActive = currentIndex == index;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(index),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.secondaryContainer.withValues(alpha: 0.5)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                      ),
                      child: Icon(
                        isActive ? item.activeIcon : item.icon,
                        size: AppSpacing.iconMd,
                        color: isActive
                            ? AppColors.primaryContainer
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: AppTextStyles.labelSm.copyWith(
                        fontSize: 10,
                        color: isActive
                            ? AppColors.primaryContainer
                            : AppColors.onSurfaceVariant,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
