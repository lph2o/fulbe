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

/// Écran de création de service marketplace.
///
/// Design d'input unifié : fond blanc, bordure grise discrète, radius 12px.
class CreateServiceScreen extends ConsumerStatefulWidget {
  const CreateServiceScreen({super.key});

  @override
  ConsumerState<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends ConsumerState<CreateServiceScreen> {
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _titleFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _priceFocus = FocusNode();

  String _selectedCategory = 'Traduction';
  String _selectedPriceLabel = 'Par heure';
  bool _isPublishing = false;
  bool _showSuccess = false;

  static const _categories = [
    _ServiceCategory('Traduction', PhosphorIcons.translate, 'translate'),
    _ServiceCategory('Développement Web', PhosphorIcons.code, 'code'),
    _ServiceCategory('Transport', PhosphorIcons.car, 'car'),
    _ServiceCategory('Immobilier', PhosphorIcons.house, 'house'),
    _ServiceCategory('Consulting', PhosphorIcons.briefcase, 'briefcase'),
    _ServiceCategory('Design Graphique', PhosphorIcons.palette, 'palette'),
    _ServiceCategory('Cuisine & Traiteur', PhosphorIcons.forkKnife, 'forkKnife'),
    _ServiceCategory('Cours particuliers', PhosphorIcons.chalkboardTeacher, 'chalkboardTeacher'),
    _ServiceCategory('Photographie', PhosphorIcons.camera, 'camera'),
    _ServiceCategory('Autre', PhosphorIcons.dotsThree, 'dotsThree'),
  ];

  static const _priceLabels = [
    'Par heure', 'Par jour', 'Par projet', 'Forfait mensuel', 'Gratuit', 'Sur devis',
  ];

  _ServiceCategory _findCategory(String name) =>
      _categories.firstWhere((c) => c.name == name, orElse: () => _categories.last);

  @override
  void dispose() {
    _titleCtrl.dispose(); _descriptionCtrl.dispose(); _priceCtrl.dispose();
    _titleFocus.dispose(); _descriptionFocus.dispose(); _priceFocus.dispose();
    super.dispose();
  }

  // ── Publish ──────────────────────────────────────────────────────────

  bool get _canPublish =>
      _titleCtrl.text.trim().isNotEmpty && _descriptionCtrl.text.trim().isNotEmpty;

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate() || _isPublishing) return;

    final member = ref.read(currentMemberProvider).valueOrNull;
    if (member == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vous devez être connecté pour proposer un service.')),
        );
      }
      return;
    }

    setState(() => _isPublishing = true);

    try {
      await ref.read(marketplaceRepositoryProvider).createService(
            title: _titleCtrl.text.trim(),
            description: _descriptionCtrl.text.trim(),
            category: _selectedCategory,
            categoryIcon: _findCategory(_selectedCategory).slug,
            price: _priceCtrl.text.trim().isEmpty ? 'Sur devis' : _priceCtrl.text.trim(),
            priceLabel: _selectedPriceLabel,
            providerMemberId: member.id,
          );

      ref.invalidate(servicesProvider);

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
          const SnackBar(content: Text('Erreur lors de la création.')),
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
        title: Text('Nouveau service', style: AppTextStyles.labelMd.copyWith(
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
              _sectionLabel('Titre du service', required: true),
              SizedBox(height: AppSpacing.stackSm),
              _inputField(
                controller: _titleCtrl, focusNode: _titleFocus,
                hint: 'Ex: Traduction Fulfulde-Français',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
              ),

              SizedBox(height: AppSpacing.stackMd),

              _sectionLabel('Catégorie'),
              SizedBox(height: AppSpacing.stackSm),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = cat.name == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat.name),
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.icon, size: 16, color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant),
                          SizedBox(width: 6),
                          Text(cat.name, style: AppTextStyles.labelSm.copyWith(
                            color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          )),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              SizedBox(height: AppSpacing.stackMd),

              _sectionLabel('Description', required: true),
              SizedBox(height: AppSpacing.stackSm),
              _inputField(
                controller: _descriptionCtrl, focusNode: _descriptionFocus,
                hint: 'Décrivez votre service en détail...',
                maxLines: 4,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
              ),

              SizedBox(height: AppSpacing.stackMd),

              _sectionLabel('Prix'),
              SizedBox(height: AppSpacing.stackSm),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _inputField(
                      controller: _priceCtrl, focusNode: _priceFocus,
                      hint: 'Montant',
                    ),
                  ),
                  SizedBox(width: AppSpacing.stackSm),
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        border: Border.all(
                          color: AppColors.outlineVariant.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedPriceLabel,
                            isExpanded: true,
                            style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.onSurface, fontSize: 15,
                            ),
                            items: _priceLabels
                                .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                                .toList(),
                            onChanged: (v) { if (v != null) setState(() => _selectedPriceLabel = v); },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.stackLg),

              FcPrimaryButton(
                label: 'Publier le service',
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

// ── Service Category Model ─────────────────────────────────────────────────

class _ServiceCategory {
  final String name;
  final IconData icon;
  final String slug;
  const _ServiceCategory(this.name, this.icon, this.slug);
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
                  child: Icon(PhosphorIcons.storefront, color: AppColors.primaryContainer, size: 56),
                ),
                SizedBox(height: AppSpacing.stackLg),
                Text('Service créé !', style: AppTextStyles.headlineMd.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                SizedBox(height: 8),
                Text('Votre service est maintenant visible', style: AppTextStyles.bodyMd.copyWith(color: Colors.white.withValues(alpha: 0.8))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
