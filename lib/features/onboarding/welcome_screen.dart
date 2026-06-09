import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/navigation/app_router.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedLang = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const _langs = ['Français', 'Fulfulde', 'English'];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // ── Background pattern overlay ─────────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _GridPatternPainter()),
          ),
          // ── Green gradient ─────────────────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.85),
                    AppColors.primary.withValues(alpha: 0.95),
                    AppColors.primary,
                  ],
                ),
              ),
            ),
          ),
          // ── Content ────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile,
              ),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.stackMd),
                  // Language selector
                  _LanguageSelector(
                    selected: _selectedLang,
                    langs: _langs,
                    onSelect: (i) => setState(() => _selectedLang = i),
                  ),
                  // Hero center
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo orb
                        _LogoOrb(pulseAnimation: _pulseAnimation),
                        const SizedBox(height: AppSpacing.stackLg),
                        // Title
                        Text(
                          'Fulɓe\nConnect',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.displayLg.copyWith(
                            color: AppColors.onPrimary,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.stackMd),
                        Text(
                          'Connecter les Peuls partout dans le monde.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyLg.copyWith(
                            color: AppColors.primaryFixedDim,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // CTA buttons
                  Column(
                    children: [
                      _GoldCTAButton(
                        label: 'Rejoindre la communauté',
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.auth, arguments: 1),
                      ),
                      const SizedBox(height: AppSpacing.stackMd),
                      _GhostCTAButton(
                        label: 'Se connecter',
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.auth, arguments: 0),
                      ),
                      const SizedBox(height: AppSpacing.stackLg),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-components ──────────────────────────────────────────────────────────

class _LanguageSelector extends StatelessWidget {
  final int selected;
  final List<String> langs;
  final ValueChanged<int> onSelect;

  const _LanguageSelector({
    required this.selected,
    required this.langs,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: List.generate(langs.length, (i) {
              final isSelected = selected == i;
              return GestureDetector(
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.secondaryContainer
                        : Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    langs[i],
                    style: AppTextStyles.labelSm.copyWith(
                      color: isSelected
                          ? AppColors.onSecondaryContainer
                          : AppColors.primaryFixedDim,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _LogoOrb extends StatelessWidget {
  final Animation<double> pulseAnimation;
  const _LogoOrb({required this.pulseAnimation});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: AnimatedBuilder(
        animation: pulseAnimation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring 3
              Transform.scale(
                scale: pulseAnimation.value * 1.25,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.secondaryContainer
                          .withValues(alpha: 0.08),
                      width: 1,
                    ),
                  ),
                ),
              ),
              // Outer ring 2
              Transform.scale(
                scale: pulseAnimation.value * 1.1,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.secondaryContainer
                          .withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                ),
              ),
              // Main orb
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondaryContainer.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.secondaryContainer.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondaryContainer
                          .withValues(alpha: 0.2),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.public,
                  size: 48,
                  color: AppColors.secondaryContainer,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GoldCTAButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GoldCTAButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondaryContainer,
          foregroundColor: AppColors.onSecondaryContainer,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          shadowColor:
              AppColors.secondaryContainer.withValues(alpha: 0.4),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.onSecondaryContainer,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _GhostCTAButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GhostCTAButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryFixedDim,
          side: BorderSide(
            color: AppColors.primaryFixedDim.withValues(alpha: 0.4),
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.primaryFixedDim,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

/// Subtle dot-grid pattern for the welcome background
class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.secondaryContainer.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;
    const spacing = 28.0;
    const radius = 1.2;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
