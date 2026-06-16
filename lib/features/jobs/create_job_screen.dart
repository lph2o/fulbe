// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../core/data/providers/data_providers.dart';
import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/fc_button.dart';

/// Écran de publication d'offre d'emploi.
///
/// Design d'input unifié : fond blanc, bordure grise discrète, radius 12px.
class CreateJobScreen extends ConsumerStatefulWidget {
  const CreateJobScreen({super.key});

  @override
  ConsumerState<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends ConsumerState<CreateJobScreen> {
  final _titleCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _titleFocus = FocusNode();
  final _companyFocus = FocusNode();
  final _locationFocus = FocusNode();

  String _selectedType = 'Full-time';
  String _selectedDomain = 'Tech';
  bool _isPublishing = false;
  bool _showSuccess = false;

  static const _jobTypes = [
    'Full-time', 'Part-time', 'Contract', 'Internship',
    'Mission Freelance', 'Stage', 'Bénévolat',
  ];

  static const _domains = [
    'Tech', 'Agriculture', 'Santé', 'Finance', 'Design',
    'Éducation', 'Marketing', 'Droit', 'Commerce', 'Artisanat',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose(); _companyCtrl.dispose(); _locationCtrl.dispose();
    _titleFocus.dispose(); _companyFocus.dispose(); _locationFocus.dispose();
    super.dispose();
  }

  // ── Publish ──────────────────────────────────────────────────────────

  bool get _canPublish =>
      _titleCtrl.text.trim().isNotEmpty &&
      _companyCtrl.text.trim().isNotEmpty &&
      _locationCtrl.text.trim().isNotEmpty;

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate() || _isPublishing) return;

    final member = ref.read(currentMemberProvider).valueOrNull;
    if (member == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vous devez être connecté pour publier une offre.')),
        );
      }
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final company = _companyCtrl.text.trim();
      final initials = company
          .split(' ').where((w) => w.isNotEmpty).take(2)
          .map((w) => w[0].toUpperCase()).join();

      await ref.read(jobsRepositoryProvider).createJob(
            title: _titleCtrl.text.trim(),
            company: company,
            companyInitials: initials,
            location: _locationCtrl.text.trim(),
            type: _selectedType,
            domain: _selectedDomain,
            postedByMemberId: member.id,
          );

      ref.invalidate(jobsProvider);

      if (mounted) {
        setState(() { _isPublishing = false; _showSuccess = true; });
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.of(context).pop(true);
      }
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _isPublishing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isPublishing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la publication.')),
        );
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_showSuccess) {
      return _SuccessOverlay(onDismiss: () => Navigator.of(context).pop(true));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface, elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIcons.x, size: 22),
          color: AppColors.onSurface,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Nouvelle offre', style: AppTextStyles.labelMd.copyWith(
          color: AppColors.onSurface, fontWeight: FontWeight.w700, fontSize: 15,
        )),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.marginMobile),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Titre du poste', required: true),
              SizedBox(height: AppSpacing.stackSm),
              _inputField(
                controller: _titleCtrl, focusNode: _titleFocus,
                hint: 'Ex: Développeur Flutter Senior',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
              ),

              SizedBox(height: AppSpacing.stackMd),

              _sectionLabel('Entreprise', required: true),
              SizedBox(height: AppSpacing.stackSm),
              _inputField(
                controller: _companyCtrl, focusNode: _companyFocus,
                hint: 'Nom de l\'entreprise',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
              ),

              SizedBox(height: AppSpacing.stackMd),

              _sectionLabel('Lieu', required: true),
              SizedBox(height: AppSpacing.stackSm),
              _inputField(
                controller: _locationCtrl, focusNode: _locationFocus,
                hint: 'Ville, pays ou remote',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
              ),

              SizedBox(height: AppSpacing.stackMd),

              _sectionLabel('Type de contrat'),
              SizedBox(height: AppSpacing.stackSm),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _jobTypes.map((type) {
                  final isSelected = type == _selectedType;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = type),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryFixed : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.outlineVariant.withValues(alpha: 0.4),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(type, style: AppTextStyles.labelSm.copyWith(
                        color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      )),
                    ),
                  );
                }).toList(),
              ),

              SizedBox(height: AppSpacing.stackMd),

              _sectionLabel('Domaine'),
              SizedBox(height: AppSpacing.stackSm),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _domains.map((domain) {
                  final isSelected = domain == _selectedDomain;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDomain = domain),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.tertiaryFixed : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        border: Border.all(
                          color: isSelected ? AppColors.tertiary : AppColors.outlineVariant.withValues(alpha: 0.4),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(domain, style: AppTextStyles.labelSm.copyWith(
                        color: isSelected ? AppColors.tertiary : AppColors.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      )),
                    ),
                  );
                }).toList(),
              ),

              SizedBox(height: AppSpacing.stackLg),

              FcPrimaryButton(
                label: 'Publier l\'offre',
                icon: PhosphorIcons.paperPlaneTilt,
                onTap: _canPublish ? _publish : null,
              ),
              SizedBox(height: AppSpacing.stackMd),
            ],
          ),
        ),
      ),
    );
  }

  // ── Design System : Inputs unifiés ───────────────────────────────────

  Widget _sectionLabel(String label, {bool required = false}) {
    return Row(
      children: [
        if (required)
          Text('* ', style: AppTextStyles.labelSm.copyWith(
            color: AppColors.error, fontWeight: FontWeight.w700,
          )),
        Text(label, style: AppTextStyles.labelSm.copyWith(
          color: AppColors.onSurface, fontWeight: FontWeight.w600,
        )),
      ],
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {    return ListenableBuilder(
      listenable: focusNode,
      builder: (_, __) {
        final hasFocus = focusNode.hasFocus;
        return Material(
          color: AppColors.surfaceContainerLowest,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            side: BorderSide(
              color: hasFocus
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.outlineVariant.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            maxLines: maxLines,
            validator: validator,
            cursorColor: AppColors.primary,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurface, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              fillColor: Colors.transparent,
              focusColor: Colors.transparent,
              contentPadding: EdgeInsets.all(16),
              isDense: true,
            ),
          ),
        );
      },
    );
  }
}

// ── Success Overlay ────────────────────────────────────────────────────────

class _SuccessOverlay extends StatefulWidget {
  final VoidCallback onDismiss;
  const _SuccessOverlay({required this.onDismiss});

  @override
  State<_SuccessOverlay> createState() => _SuccessOverlayState();
}

class _SuccessOverlayState extends State<_SuccessOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Container(
        color: AppColors.primaryContainer.withValues(alpha: _opacityAnim.value * 0.95),
        child: Center(
          child: Transform.scale(
            scale: _scaleAnim.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: Offset(0, 8))],
                  ),
                  child: Icon(PhosphorIcons.briefcase, color: AppColors.primaryContainer, size: 56),
                ),
                SizedBox(height: AppSpacing.stackLg),
                Text('Offre publiée !', style: AppTextStyles.headlineMd.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                SizedBox(height: 8),
                Text('Votre offre d\'emploi est maintenant visible', style: AppTextStyles.bodyMd.copyWith(color: Colors.white.withValues(alpha: 0.8))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
