// ignore_for_file: prefer_const_constructors, prefer_const_constructors_in_immutables, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/models/member.dart';
import '../../core/data/providers/data_providers.dart';
import '../../core/errors/app_exception.dart';
import '../../core/navigation/app_router.dart' show AppRoutes;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../../shared/widgets/fc_card.dart';

class WorldMapScreen extends ConsumerStatefulWidget {
  WorldMapScreen({super.key});

  @override
  ConsumerState<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends ConsumerState<WorldMapScreen> {
  int _selectedCountry = 0;
  MemberCluster? _selectedCluster;

  static final _countryFilters = [
    'Toutes régions', 'Sénégal', 'Guinée', 'France', 'Italie', 'Mali',
  ];

  @override
  Widget build(BuildContext context) {
    final asyncClusters = ref.watch(memberClustersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(showBack: true),
      body: Stack(
        children: [
          // ── World map background ──────────────────────────────
          Positioned.fill(
            child: Container(
              color: Color(0xFFE8EAE8),
              child: asyncClusters.when(
                data: (clusters) {
                  final filtered = _selectedCountry == 0
                      ? clusters
                      : clusters
                          .where((c) =>
                              c.country.toLowerCase() ==
                              _countryFilters[_selectedCountry].toLowerCase())
                          .toList();
                  return _MapBackground(
                    clusters: filtered,
                    onClusterTap: (c) =>
                        setState(() => _selectedCluster = c),
                  );
                },
                loading: () => Center(
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.stackLg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(PhosphorIcons.cloudSlash,
                            size: 56, color: AppColors.outlineVariant),
                        SizedBox(height: AppSpacing.stackMd),
                        Text(
                          e is AppException
                              ? e.message
                              : 'Impossible de charger la carte.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMd
                              .copyWith(color: AppColors.onSurfaceVariant),
                        ),
                        SizedBox(height: AppSpacing.stackMd),
                        FilledButton.tonalIcon(
                          onPressed: () =>
                              ref.invalidate(memberClustersProvider),
                          icon: Icon(PhosphorIcons.arrowsClockwise, size: 18),
                          label: Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // ── Search + filters overlay ──────────────────────────
          Positioned(
            top: AppSpacing.stackMd,
            left: AppSpacing.marginMobile,
            right: AppSpacing.marginMobile,
            child: Column(
              children: [
                // Glassmorphism search bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest
                          .withValues(alpha: 0.92),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 16),
                        Icon(PhosphorIcons.magnifyingGlass, color: AppColors.outline),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            style: AppTextStyles.bodyMd,
                            decoration: InputDecoration(
                              hintText: 'Rechercher par ville...',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 14),
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.all(4),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(PhosphorIcons.arrowRight,
                              color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.stackMd),
                // Country filters
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _countryFilters.length,
                    separatorBuilder: (_, __) =>
                        SizedBox(width: AppSpacing.stackSm),
                    itemBuilder: (_, i) {
                      final isSelected = _selectedCountry == i;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCountry = i),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryContainer
                                : AppColors.surfaceContainerLowest
                                    .withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusFull),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryContainer
                                  : AppColors.outlineVariant,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            _countryFilters[i],
                            style: AppTextStyles.labelSm.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.onSurfaceVariant,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // ── Cluster Preview Card ──────────────────────────────
          if (_selectedCluster != null)
            Positioned(
              bottom: AppSpacing.bottomNavHeight + AppSpacing.stackMd,
              left: AppSpacing.marginMobile,
              right: AppSpacing.marginMobile,
              child: _ClusterPreviewCard(
                cluster: _selectedCluster!,
                onClose: () => setState(() => _selectedCluster = null),
              ),
            ),
        ],
      ),
    );
  }
}

class _MapBackground extends StatelessWidget {
  final List<MemberCluster> clusters;
  final ValueChanged<MemberCluster> onClusterTap;

  _MapBackground({
    required this.clusters,
    required this.onClusterTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        children: [
          // Map tinted background
          Positioned.fill(
            child: CustomPaint(painter: _MapPainter()),
          ),
          // Overlay tint
          Positioned.fill(
            child: Container(
              color: AppColors.surface.withValues(alpha: 0.25),
            ),
          ),
          // Cluster pins
          ...clusters.map((c) {
            final x = constraints.maxWidth * c.lngPercent;
            final y = constraints.maxHeight * c.latPercent;
            return Positioned(
              left: x - 24,
              top: y - 24,
              child: _ClusterPin(
                cluster: c,
                onTap: () => onClusterTap(c),
              ),
            );
          }),
        ],
      );
    });
  }
}

class _ClusterPin extends StatefulWidget {
  final MemberCluster cluster;
  final VoidCallback onTap;
  _ClusterPin({required this.cluster, required this.onTap});

  @override
  State<_ClusterPin> createState() => _ClusterPinState();
}

class _ClusterPinState extends State<_ClusterPin>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _pinColor => widget.cluster.count > 100
      ? AppColors.primaryContainer
      : widget.cluster.count > 30
          ? AppColors.primaryContainer.withValues(alpha: 0.85)
          : AppColors.primaryContainer.withValues(alpha: 0.7);

  double get _pinSize => widget.cluster.count > 100
      ? 48.0
      : widget.cluster.count > 30
          ? 40.0
          : 36.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 56,
        height: 56,
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                if (widget.cluster.count > 60)
                  Transform.scale(
                    scale: _anim.value,
                    child: Container(
                      width: _pinSize,
                      height: _pinSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _pinColor.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                Container(
                  width: _pinSize - 4,
                  height: _pinSize - 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _pinColor,
                    border: Border.all(
                        color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _pinColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${widget.cluster.count}',
                      style: AppTextStyles.labelSm.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ClusterPreviewCard extends StatelessWidget {
  final MemberCluster cluster;
  final VoidCallback onClose;
  _ClusterPreviewCard(
      {required this.cluster, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return FcCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(AppSpacing.stackMd),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(PhosphorIcons.users,
                      color: AppColors.primaryContainer),
                ),
                SizedBox(width: AppSpacing.stackMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cluster.name,
                        style: AppTextStyles.labelMd.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${cluster.count} membres dans cette zone',
                        style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: Icon(PhosphorIcons.x,
                      color: AppColors.onSurfaceVariant, size: 20),
                ),
              ],
            ),
          ),
          Divider(height: 0, color: AppColors.outlineVariant.withValues(alpha: 0.5)),
          Padding(
            padding: EdgeInsets.all(AppSpacing.stackMd),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      onClose();
                      Navigator.of(context).pushNamed(AppRoutes.directory);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    child: Text('Voir les profils'),
                  ),
                ),
                SizedBox(width: AppSpacing.stackSm),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: AppColors.outlineVariant),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    padding: EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  child: Icon(PhosphorIcons.chatCircle,
                      color: AppColors.onSurfaceVariant, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple geometric map painter
class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = Color(0xFFDDE2DE);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final landPaint = Paint()
      ..color = Color(0xFFCDD4CE)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Color(0xFFB8C2BA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Simple continent blobs (approximate)
    _drawContinent(canvas, size, landPaint, borderPaint);
  }

  void _drawContinent(Canvas canvas, Size size, Paint fill, Paint border) {
    // Europe
    final europe = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.3),
        width: size.width * 0.12,
        height: size.height * 0.15,
      ));
    canvas.drawPath(europe, fill);
    canvas.drawPath(europe, border);

    // Africa
    final africa = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.49, size.height * 0.55),
          width: size.width * 0.14,
          height: size.height * 0.28,
        ),
        Radius.circular(20),
      ));
    canvas.drawPath(africa, fill);
    canvas.drawPath(africa, border);

    // Americas
    final americas = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.25, size.height * 0.45),
          width: size.width * 0.14,
          height: size.height * 0.4,
        ),
        Radius.circular(16),
      ));
    canvas.drawPath(americas, fill);
    canvas.drawPath(americas, border);

    // Asia
    final asia = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.68, size.height * 0.35),
          width: size.width * 0.22,
          height: size.height * 0.22,
        ),
        Radius.circular(12),
      ));
    canvas.drawPath(asia, fill);
    canvas.drawPath(asia, border);

    // Australia
    final australia = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(size.width * 0.78, size.height * 0.65),
        width: size.width * 0.09,
        height: size.height * 0.1,
      ));
    canvas.drawPath(australia, fill);
    canvas.drawPath(australia, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
