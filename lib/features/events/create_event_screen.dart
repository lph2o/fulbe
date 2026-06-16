// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../core/data/models/event.dart';
import '../../core/data/providers/data_providers.dart';
import '../../core/errors/app_exception.dart';
import '../../core/navigation/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/fc_button.dart';

/// Écran de création / modification d'événement communautaire.
class CreateEventScreen extends ConsumerStatefulWidget {
  /// Événement existant pour le mode édition (null = création).
  final Event? existingEvent;
  const CreateEventScreen({super.key, this.existingEvent});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _titleFocus = FocusNode();
  final _locationFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _picker = ImagePicker();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _selectedTime = TimeOfDay(hour: 18, minute: 0);
  String _selectedCategory = 'Conférence';
  File? _coverImage;
  bool _removeCoverImage = false;
  bool _isPublishing = false;

  static const _categories = [
    'Conférence',
    'Festival',
    'Webinaire',
    'Rencontre',
    'Formation',
    'Atelier',
    'Networking',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    final ev = widget.existingEvent;
    if (ev != null) {
      _titleCtrl.text = ev.title;
      _locationCtrl.text = ev.location;
      _descriptionCtrl.text = ev.description;
      _selectedDate = ev.date;
      _selectedTime = TimeOfDay(hour: ev.date.hour, minute: ev.date.minute);
      _selectedCategory = ev.category;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _descriptionCtrl.dispose();
    _titleFocus.dispose();
    _locationFocus.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  // ── Image Picker ────────────────────────────────────────────────────

  Future<void> _pickFromGallery() async {
    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (xFile != null && mounted) {
        setState(() {
          _coverImage = File(xFile.path);
          _removeCoverImage = false;
        });
      }
    } catch (e) {
      _showPickerError(e);
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (xFile != null && mounted) {
        setState(() {
          _coverImage = File(xFile.path);
          _removeCoverImage = false;
        });
      }
    } catch (e) {
      _showPickerError(e);
    }
  }

  void _removeImage() {
    setState(() {
      _coverImage = null;
      _removeCoverImage = false;
    });
  }

  void _removeExistingImage() => setState(() {
        _coverImage = null;
        _removeCoverImage = true;
      });

  void _showPickerError(Object e) {
    if (!mounted) return;
    final errMsg = e.toString();
    final shortMsg = errMsg.split('\n').first;
    final isPermission = shortMsg.contains('permission') ||
        shortMsg.contains('Permission') ||
        shortMsg.contains('denied');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isPermission
              ? 'Permission refusée. Activez l\'accès à la caméra/galerie dans les réglages.'
              : 'Erreur : ${shortMsg.length > 80 ? '${e.runtimeType}' : shortMsg}',
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackMd),
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
              const SizedBox(height: AppSpacing.stackMd),
              Text(
                'Photo de couverture',
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: const Icon(PhosphorIcons.images, color: AppColors.primaryContainer),
                ),
                title: Text(
                  'Galerie',
                  style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurface),
                ),
                subtitle: Text(
                  'Choisir une image',
                  style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryFixed,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: const Icon(PhosphorIcons.camera, color: AppColors.secondary),
                ),
                title: Text(
                  'Appareil photo',
                  style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurface),
                ),
                subtitle: Text(
                  'Prendre une photo',
                  style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera();
                },
              ),
              if (_coverImage != null)
                ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: const Icon(PhosphorIcons.trash, color: AppColors.error),
                  ),
                  title: Text(
                    'Supprimer la photo',
                    style: AppTextStyles.labelMd.copyWith(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _removeImage();
                  },
                ),
              if (_coverImage == null && _existingImageUrl != null && !_removeCoverImage)
                ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: const Icon(PhosphorIcons.trash, color: AppColors.error),
                  ),
                  title: Text(
                    'Supprimer la photo',
                    style: AppTextStyles.labelMd.copyWith(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _removeExistingImage();
                  },
                ),
              const SizedBox(height: AppSpacing.stackSm),
            ],
          ),
        ),
      ),
    );
  }

  // ── Pickers ──────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (_, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (_, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  String _formatDate(DateTime d) {
    final months = [
      'janv.', 'févr.', 'mars', 'avril', 'mai', 'juin',
      'juill.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  // ── Publish ──────────────────────────────────────────────────────────

  bool get _canPublish =>
      _titleCtrl.text.trim().isNotEmpty && _locationCtrl.text.trim().isNotEmpty;

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate() || _isPublishing) return;

    final member = ref.read(currentMemberProvider).valueOrNull;
    if (member == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vous devez être connecté pour créer un événement.')),
        );
      }
      return;
    }

    final ev = widget.existingEvent;
    setState(() => _isPublishing = true);

    try {
      final eventDate = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day,
        _selectedTime.hour, _selectedTime.minute,
      );

      if (ev != null) {
        // ── Mode édition ──────────────────────────────────
        await ref.read(eventsRepositoryProvider).updateEvent(
              eventId: ev.id,
              title: _titleCtrl.text.trim(),
              date: eventDate.toUtc(),
              location: _locationCtrl.text.trim(),
              category: _selectedCategory,
              description: _descriptionCtrl.text.trim(),
              imageFile: _coverImage,
              clearImage: _removeCoverImage,
            );
        ref.invalidate(eventsProvider);
        if (mounted) {
          setState(() => _isPublishing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Événement modifié avec succès.'),
              backgroundColor: AppColors.primaryContainer,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        // ── Mode création ────────────────────────────────
        final created = await ref.read(eventsRepositoryProvider).createEvent(
              title: _titleCtrl.text.trim(),
              date: eventDate.toUtc(),
              location: _locationCtrl.text.trim(),
              category: _selectedCategory,
              description: _descriptionCtrl.text.trim(),
              createdByMemberId: member.id,
              imageFile: _coverImage,
            );
        ref.invalidate(eventsProvider);
        if (mounted) {
          setState(() => _isPublishing = false);
          _showShareDialog(created.id);
        }
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

  void _showShareDialog(String eventId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.stackLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  PhosphorIcons.calendarCheck,
                  color: AppColors.primaryContainer,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              Text(
                'Événement créé !',
                style: AppTextStyles.headlineLgMobile.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: AppSpacing.stackSm),
              Text(
                "Le partager dans le fil d'actualité pour toucher plus de participants ?",
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppSpacing.stackLg),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop(true);
                    Navigator.of(context).pushNamed(
                      AppRoutes.createPost,
                      arguments: {
                        'eventId': eventId,
                        'eventTitle': _titleCtrl.text.trim(),
                        'eventDate': DateTime(
                          _selectedDate.year, _selectedDate.month, _selectedDate.day,
                          _selectedTime.hour, _selectedTime.minute,
                        ).toIso8601String(),
                        'eventLocation': _locationCtrl.text.trim(),
                        'eventCategory': _selectedCategory,
                      },
                    );
                  },
                  icon: const Icon(PhosphorIcons.paperPlaneTilt, size: 18),
                  label: const Text('Partager dans le feed'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    textStyle: AppTextStyles.labelMd.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.stackSm),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop(true);
                  },
                  child: Text(
                    'Plus tard',
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIcons.x, size: 22),
          color: AppColors.onSurface,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.existingEvent != null ? 'Modifier l\'événement' : 'Nouvel événement',
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.onSurface, fontWeight: FontWeight.w700, fontSize: 15,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.marginMobile),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCoverImagePicker(),

              SizedBox(height: AppSpacing.stackMd),

              _sectionLabel('Titre', required: true),
              SizedBox(height: AppSpacing.stackSm),
              _inputField(
                controller: _titleCtrl,
                focusNode: _titleFocus,
                hint: "Titre de l'événement",
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
              ),

              SizedBox(height: AppSpacing.stackMd),

              _sectionLabel('Date et heure', required: true),
              SizedBox(height: AppSpacing.stackSm),
              Row(
                children: [
                  Expanded(
                    child: _pickerTile(
                      icon: PhosphorIcons.calendar,
                      value: _formatDate(_selectedDate),
                      label: 'Date',
                      onTap: _pickDate,
                    ),
                  ),
                  SizedBox(width: AppSpacing.stackSm),
                  Expanded(
                    child: _pickerTile(
                      icon: PhosphorIcons.clock,
                      value: _selectedTime.format(context),
                      label: 'Heure',
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.stackMd),

              _sectionLabel('Lieu', required: true),
              SizedBox(height: AppSpacing.stackSm),
              _inputField(
                controller: _locationCtrl,
                focusNode: _locationFocus,
                hint: 'Ville, pays ou lien visio',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
              ),

              SizedBox(height: AppSpacing.stackMd),

              _sectionLabel('Catégorie'),
              SizedBox(height: AppSpacing.stackSm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
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
                      child: Text(
                        cat,
                        style: AppTextStyles.labelSm.copyWith(
                          color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              SizedBox(height: AppSpacing.stackMd),

              _sectionLabel('Description'),
              SizedBox(height: AppSpacing.stackSm),
              _inputField(
                controller: _descriptionCtrl,
                focusNode: _descriptionFocus,
                hint: "Décrivez l'événement...",
                maxLines: 4,
              ),

              SizedBox(height: AppSpacing.stackLg),

              FcPrimaryButton(
                label: widget.existingEvent != null ? "Modifier l'événement" : "Publier l'événement",
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

  // ── Couverture image ────────────────────────────────────────────────

  /// URL de l'image existante (null en mode création).
  String? get _existingImageUrl {
    final ev = widget.existingEvent;
    if (ev == null) return null;
    return ev.imageUrl.isNotEmpty ? ev.imageUrl : null;
  }

  Widget _buildCoverImagePicker() {
    final hasLocalImage = _coverImage != null;
    final hasExistingUrl = _existingImageUrl != null && !_removeCoverImage;
    final hasAnyImage = hasLocalImage || hasExistingUrl;

    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Container(
        width: double.infinity,
        height: hasAnyImage ? 200 : 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: hasLocalImage
              ? _buildCoverPreview()
              : hasExistingUrl
                  ? _buildExistingCoverPreview()
                  : _buildCoverPlaceholder(),
        ),
      ),
    );
  }

  /// Superpose le gradient et le badge "Modifier" sur l'image de couverture.
  /// [extraWidget] permet d'ajouter un bouton supplémentaire (ex. X pour supprimer).
  Widget _buildCoverOverlay({Widget? extraWidget}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradient bas
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 60,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Bouton supprimer (optionnel)
        if (extraWidget != null)
          Positioned(top: 8, right: 8, child: extraWidget),
        // Badge "Modifier"
        Positioned(
          bottom: 12,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(PhosphorIcons.pencilSimple, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Modifier',
                  style: AppTextStyles.labelSm.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Aperçu de l'image existante (réseau) en mode édition.
  Widget _buildExistingCoverPreview() {
    if (_removeCoverImage) return _buildCoverPlaceholder();
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          _existingImageUrl!,
          fit: BoxFit.cover,
          cacheWidth: 800,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return _buildCoverPlaceholder();
          },
          errorBuilder: (_, __, ___) => _buildCoverPlaceholder(),
        ),
        _buildCoverOverlay(),
      ],
    );
  }

  Widget _buildCoverPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(_coverImage!, fit: BoxFit.cover),
        _buildCoverOverlay(
          extraWidget: GestureDetector(
            onTap: _removeImage,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(PhosphorIcons.x, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
          width: 1.5,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              PhosphorIcons.images,
              color: AppColors.primaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Text(
            'Ajouter une photo de couverture',
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Touchez pour choisir une image',
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
              fontWeight: FontWeight.w400,
              fontSize: 11,
            ),
          ),
        ],
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
        Text(
          label,
          style: AppTextStyles.labelSm.copyWith(
            color: AppColors.onSurface, fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return ListenableBuilder(
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

  Widget _pickerTile({
    required IconData icon,
    required String value,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primaryContainer),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurface, fontWeight: FontWeight.w600, fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    label,
                    style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(PhosphorIcons.caretDown, size: 16, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
