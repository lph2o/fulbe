import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Écran affiché au démarrage quand l'application n'a pas été buildée
/// avec une configuration Supabase valide (URL/clé encore en placeholder).
///
/// Plutôt que de laisser l'app crasher avec une `SocketException` opaque
/// lors du premier appel réseau, on affiche un message clair qui explique
/// comment corriger le tir (variables `--dart-define` ou fichier `.env`).
class ConfigErrorScreen extends StatelessWidget {
  const ConfigErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.marginMobile,
              vertical: AppSpacing.stackLg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 1),
                // ── Icon ──────────────────────────────────────────
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.error.withValues(alpha: 0.12),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.45),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      PhosphorIcons.cloudSlash,
                      size: 44,
                      color: AppColors.secondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.stackLg),
                // ── Title ─────────────────────────────────────────
                Text(
                  'Configuration Supabase\nmanquante',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headlineLg.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: AppSpacing.stackMd),
                // ── Description ───────────────────────────────────
                Text(
                  "L'application n'a pas été démarrée avec une URL et une clé "
                  "Supabase valides. Les appels au backend échoueraient — "
                  "veuillez configurer votre environnement avant de relancer.",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.primaryFixedDim,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.stackLg),
                // ── Code block (helpful diagnostics) ──────────────
                _ConfigCodeBlock(
                  url: AppConstants.supabaseUrl,
                  keyPreview: _maskKey(AppConstants.supabasePublishableKey),
                ),
                const Spacer(flex: 1),
                // ── Steps to fix ─────────────────────────────────
                const _FixSteps(),
                const SizedBox(height: AppSpacing.stackLg),
                // ── Copy config example button ───────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _copyToClipboard(context),
                    icon: const Icon(PhosphorIcons.copy, size: 20),
                    label: const Text("Copier la commande d'exemple"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.onPrimary,
                      side: BorderSide(
                        color: AppColors.primaryFixedDim.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusXl),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.stackSm),
                Text(
                  'Voir README.md → « Configuration de l\'environnement ».',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.primaryFixedDim.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _maskKey(String key) {
    if (key.length <= 8) return '••••';
    return '${key.substring(0, 4)}••••${key.substring(key.length - 4)}';
  }

  void _copyToClipboard(BuildContext context) {
    const snippet =
        'flutter run \\\n  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \\\n  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY';
    Clipboard.setData(const ClipboardData(text: snippet));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Commande d'exemple copiée dans le presse-papier."),
      ),
    );
  }
}

class _ConfigCodeBlock extends StatelessWidget {
  final String url;
  final String keyPreview;

  const _ConfigCodeBlock({required this.url, required this.keyPreview});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.primaryFixedDim.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('SUPABASE_URL', url),
          const SizedBox(height: AppSpacing.stackSm),
          _row('SUPABASE_PUBLISHABLE_KEY', keyPreview),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 36,
          child: Icon(
            PhosphorIcons.circleFill,
            size: 6,
            color: AppColors.error.withValues(alpha: 0.7),
          ),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTextStyles.bodyMd.copyWith(
                fontFamily: 'monospace',
                fontSize: 13,
                color: AppColors.primaryFixedDim,
              ),
              children: [
                TextSpan(
                  text: '$label ',
                  style: const TextStyle(
                    color: AppColors.secondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: value.contains('placeholder') || value == '••••'
                        ? AppColors.error.withValues(alpha: 0.85)
                        : AppColors.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FixSteps extends StatelessWidget {
  const _FixSteps();

  @override
  Widget build(BuildContext context) {
    const steps = <_Step>[
      _Step(
        n: '1',
        text:
            'Créez un fichier `.env` à la racine (cf. `.env.example`).',
      ),
      _Step(
        n: '2',
        text:
            'Renseignez SUPABASE_URL et SUPABASE_PUBLISHABLE_KEY depuis '
            'votre dashboard Supabase.',
      ),
      _Step(
        n: '3',
        text:
            "Relancez l'app avec `flutter run --dart-define-from-file=.env`.",
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps
          .map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.stackSm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.secondaryContainer
                          .withValues(alpha: 0.18),
                      border: Border.all(
                        color: AppColors.secondaryContainer
                            .withValues(alpha: 0.55),
                      ),
                    ),
                    child: Text(
                      s.n,
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.secondaryContainer,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.stackSm),
                  Expanded(
                    child: Text(
                      s.text,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.primaryFixedDim,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _Step {
  final String n;
  final String text;
  const _Step({required this.n, required this.text});
}
