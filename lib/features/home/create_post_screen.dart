import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../core/data/models/member.dart';
import '../../core/data/providers/data_providers.dart';
import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/event_preview_card.dart';
import '../../shared/widgets/fc_card.dart';

/// Ecran de creation de post — experience inspiree d'Instagram avec carrousel.
///
/// Flux :
/// 1. L'utilisateur choisit jusqu'a 10 images (galerie multi-select / appareil photo)
/// 2. Swipe horizontal dans le carrousel pour naviguer entre les images
/// 3. Redige une legende (optionnelle, max 500 caracteres)
/// 4. Appuie sur "Publier" → upload images → insert DB → retour au feed
///
/// Si [eventData] est fourni, la legende est pre-remplie avec les infos
/// de l'evenement et une carte de preview est affichee.
class CreatePostScreen extends ConsumerStatefulWidget {
  final Map<String, String>? eventData;
  const CreatePostScreen({super.key, this.eventData});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _captionCtrl = TextEditingController();
  final _captionFocus = FocusNode();
  final _picker = ImagePicker();
  final _pageController = PageController();

  final List<File> _imageFiles = [];
  int _currentPage = 0;
  bool _isPublishing = false;
  bool _showSuccess = false;
  int _charCount = 0;

  static const _maxImages = 10;
  static const _maxChars = 500;

  @override
  void initState() {
    super.initState();
    _captionCtrl.addListener(_onCaptionChanged);

    // Pre-fill caption from event data
    final ev = widget.eventData;
    if (ev != null) {
      final title = ev['eventTitle'] ?? '';
      final date = ev['eventDate'] ?? '';
      final location = ev['eventLocation'] ?? '';
      final parsedDate = DateTime.tryParse(date);
      final dateStr = parsedDate != null
          ? '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}'
          : date;
      _captionCtrl.text = '📅 $title\n📍 $location\n🗓️ $dateStr\n\nInscrivez-vous dès maintenant !';
    }
  }

  void _onCaptionChanged() {
    setState(() => _charCount = _captionCtrl.text.length);
  }

  @override
  void dispose() {
    _captionCtrl.removeListener(_onCaptionChanged);
    _captionCtrl.dispose();
    _captionFocus.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ── Image Pickers ─────────────────────────────────────────────────────

  Future<void> _pickFromGallery() async {
    final remaining = _maxImages - _imageFiles.length;
    if (remaining <= 0) {
      _showMaxToast();
      return;
    }

    try {
      // Multi-select depuis la galerie
      final xFiles = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
        limit: remaining,
      );
      if (xFiles.isNotEmpty && mounted) {
        setState(() {
          for (final xf in xFiles) {
            if (_imageFiles.length >= _maxImages) break;
            _imageFiles.add(File(xf.path));
          }
        });
        _captionFocus.requestFocus();
      }
    } catch (e) {
      _showPickerError(e);
    }
  }

  Future<void> _pickFromCamera() async {
    if (_imageFiles.length >= _maxImages) {
      _showMaxToast();
      return;
    }

    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (xFile != null && mounted) {
        setState(() => _imageFiles.add(File(xFile.path)));
        _pageController.animateToPage(
          _imageFiles.length - 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        _captionFocus.requestFocus();
      }
    } catch (e) {
      _showPickerError(e);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
      if (_currentPage >= _imageFiles.length) {
        _currentPage = _imageFiles.isEmpty ? 0 : _imageFiles.length - 1;
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_currentPage);
        }
      }
    });
  }

  void _showMaxToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Maximum 10 images atteint.')),
    );
  }

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
              ? 'Permission refusee. Activez l\'acces a la camera/galerie dans les reglages.'
              : 'Erreur : ${shortMsg.length > 80 ? '${e.runtimeType}' : shortMsg}',
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showImageSourceSheet() {
    final remaining = _maxImages - _imageFiles.length;

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
                _imageFiles.isEmpty ? 'Ajouter des photos' : 'Ajouter une photo ($_maxImages max)',
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.stackSm),
              Text(
                '${_imageFiles.length}/$_maxImages selectionnees',
                style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              ListTile(
                enabled: remaining > 0,
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: remaining > 0 ? AppColors.primaryFixed : AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Icon(
                    PhosphorIcons.images,
                    color: remaining > 0 ? AppColors.primaryContainer : AppColors.outlineVariant,
                  ),
                ),
                title: Text(
                  'Galerie (multi-select)',
                  style: AppTextStyles.labelMd.copyWith(
                    color: remaining > 0 ? AppColors.onSurface : AppColors.outlineVariant,
                  ),
                ),
                subtitle: Text(
                  'Choisir jusqu\'a $remaining image${remaining > 1 ? 's' : ''}',
                  style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              ListTile(
                enabled: remaining > 0,
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: remaining > 0 ? AppColors.secondaryFixed : AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Icon(
                    PhosphorIcons.camera,
                    color: remaining > 0 ? AppColors.secondary : AppColors.outlineVariant,
                  ),
                ),
                title: Text(
                  'Appareil photo',
                  style: AppTextStyles.labelMd.copyWith(
                    color: remaining > 0 ? AppColors.onSurface : AppColors.outlineVariant,
                  ),
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
              if (_imageFiles.isNotEmpty)
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
                    'Supprimer toutes les photos',
                    style: AppTextStyles.labelMd.copyWith(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _imageFiles.clear();
                      _currentPage = 0;
                    });
                  },
                ),
              const SizedBox(height: AppSpacing.stackSm),
            ],
          ),
        ),
      ),
    );
  }

  // ── Publish ────────────────────────────────────────────────────────────

  Future<void> _publish() async {
    if (_isPublishing) return;

    final content = _captionCtrl.text.trim();
    final member = ref.read(currentMemberProvider).valueOrNull;

    if (member == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vous devez etre connecte pour publier.')),
        );
      }
      return;
    }

    setState(() => _isPublishing = true);

    try {
      await ref.read(postsRepositoryProvider).createPost(
            authorMemberId: member.id,
            content: content,
            imageFiles: _imageFiles,
            eventId: widget.eventData?['eventId'],
          );

      ref.invalidate(postsProvider);

      if (mounted) {
        setState(() {
          _isPublishing = false;
          _showSuccess = true;
        });

        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.of(context).pop(true);
      }
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _isPublishing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
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

  bool get _isFromEvent => widget.eventData != null;

  bool get _canPublish =>
      !_isPublishing && (_imageFiles.isNotEmpty || _captionCtrl.text.trim().isNotEmpty);

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final member = ref.watch(currentMemberProvider).valueOrNull;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    if (_showSuccess) {
      return _SuccessOverlay(onDismiss: () => Navigator.of(context).pop(true));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(member),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildCarousel(),
                    if (widget.eventData?['eventId'] != null) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.marginMobile,
                          AppSpacing.stackMd,
                          AppSpacing.marginMobile,
                          0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(PhosphorIcons.calendar, size: 14, color: AppColors.primaryContainer),
                                const SizedBox(width: 6),
                                Text(
                                  'Aperçu événement',
                                  style: AppTextStyles.labelSm.copyWith(
                                    color: AppColors.primaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.stackSm),
                            EventPreviewCard(eventId: widget.eventData!['eventId']!),
                          ],
                        ),
                      ),
                    ],
                    _buildCaptionEditor(),
                    if (_imageFiles.isNotEmpty || _captionCtrl.text.isNotEmpty)
                      _buildPreviewCard(member),
                  ],
                ),
              ),
            ),
            if (bottomInset > 0)
              const SizedBox.shrink()
            else
              _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ── Top Bar ───────────────────────────────────────────────────────────

  Widget _buildTopBar(Member? member) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(PhosphorIcons.x, size: 22),
            color: AppColors.onSurface,
            onPressed: () => Navigator.of(context).pop(),
            visualDensity: VisualDensity.compact,
          ),
          const Spacer(),
          Text(
            'Nouveau post',
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const Spacer(),
          _canPublish
              ? _isPublishing
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : TextButton(
                      onPressed: _publish,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryContainer,
                        textStyle: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Publier'),
                    )
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Publier',
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.outlineVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  // ── Carousel ──────────────────────────────────────────────────────────

  Widget _buildCarousel() {
    // No images selected — nothing to show. The bottom bar has Gallery/Camera
    // buttons for adding images. Text-only posts are fully supported.
    if (_imageFiles.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        AppSpacing.stackMd,
        AppSpacing.marginMobile,
        0,
      ),
      child: Column(
        children: [
          // ── PageView (swipe) ──────────────────────────
          Container(
            width: double.infinity,
            height: 380,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              child: _buildPageView(),
            ),
          ),

          // ── Dot indicators ────────────────────────────
          if (_imageFiles.length > 1) ...[
            const SizedBox(height: AppSpacing.stackSm),
            _buildDotIndicators(),
          ],

          // ── Thumbnail strip ───────────────────────────
          const SizedBox(height: AppSpacing.stackSm),
          _buildThumbnailStrip(),
        ],
      ),
    );
  }

  Widget _buildPageView() {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: _imageFiles.length,
          onPageChanged: (i) => setState(() => _currentPage = i),
          itemBuilder: (_, i) {
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.file(_imageFiles[i], fit: BoxFit.cover),
                // Gradient bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 80,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Counter badge (top left)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      '${i + 1}/${_imageFiles.length}',
                      style: AppTextStyles.labelSm.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                // Delete button (top right)
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => _removeImage(i),
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
          },
        ),
        // Left arrow
        if (_currentPage > 0)
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                ),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Icon(PhosphorIcons.caretLeft, size: 16, color: Colors.black87),
                ),
              ),
            ),
          ),
        // Right arrow
        if (_currentPage < _imageFiles.length - 1)
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                ),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Icon(PhosphorIcons.caretRight, size: 16, color: Colors.black87),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDotIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_imageFiles.length, (i) {
        final isActive = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 8 : 6,
          height: isActive ? 8 : 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primaryContainer : AppColors.outlineVariant.withValues(alpha: 0.5),
          ),
        );
      }),
    );
  }

  Widget _buildThumbnailStrip() {
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          // Existing thumbnails
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _imageFiles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final isSelected = i == _currentPage;
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    );
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryContainer : AppColors.outlineVariant.withValues(alpha: 0.3),
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primaryContainer.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd - 1),
                      child: Image.file(_imageFiles[i], fit: BoxFit.cover),
                    ),
                  ),
                );
              },
            ),
          ),

          // Add more button
          if (_imageFiles.length < _maxImages)
            GestureDetector(
              onTap: _showImageSourceSheet,
              child: Container(
                width: 56,
                height: 56,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.4),
                    style: BorderStyle.solid,
                    width: 1.5,
                  ),
                  color: AppColors.surfaceContainerLow,
                ),
                child: const Icon(
                  PhosphorIcons.plus,
                  color: AppColors.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Caption Editor ────────────────────────────────────────────────────

  Widget _buildCaptionEditor() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.stackMd),
          Row(
            children: [
              const Icon(PhosphorIcons.textT, size: 16, color: AppColors.primaryContainer),
              const SizedBox(width: 8),
              Text(
                'Legende',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.primaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: AppTextStyles.labelSm.copyWith(
                  color: _charCount > _maxChars * 0.9
                      ? AppColors.error
                      : AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                child: Text('$_charCount/$_maxChars'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: _captionFocus.hasFocus
                    ? AppColors.primaryContainer.withValues(alpha: 0.3)
                    : AppColors.outlineVariant.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: _captionFocus.hasFocus
                  ? [
                      BoxShadow(
                        color: AppColors.primaryContainer.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: TextField(
              controller: _captionCtrl,
              focusNode: _captionFocus,
              maxLength: _maxChars,
              maxLines: 4,
              minLines: 2,
              buildCounter: (_, {required currentLength, required maxLength, required isFocused}) => null,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurface,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'Ecrivez une legende...',
                hintStyle: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Preview Card ──────────────────────────────────────────────────────

  Widget _buildPreviewCard(Member? member) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        AppSpacing.stackLg,
        AppSpacing.marginMobile,
        AppSpacing.stackLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(PhosphorIcons.eye, size: 14, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'Apercu',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_imageFiles.length > 1) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    '${_imageFiles.length} photos',
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.primaryContainer,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          FcCard(
            padding: EdgeInsets.zero,
            borderRadius: AppSpacing.radiusSm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  child: Row(
                    children: [
                      FcAvatar(
                        imageUrl: member?.avatarUrl,
                        initials: member?.initials,
                        size: 32,
                        showBorder: false,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member?.name ?? 'Vous',
                              style: AppTextStyles.labelSm.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${member?.city ?? 'Ville'}, ${member?.country ?? 'Pays'}',
                              style: AppTextStyles.labelSm.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.w400,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(PhosphorIcons.dotsThree, size: 18, color: AppColors.onSurfaceVariant),
                    ],
                  ),
                ),
                // Carousel preview (first image or carousel)
                if (_imageFiles.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSpacing.radiusSm),
                    ),
                    child: Stack(
                      children: [
                        Image.file(
                          _imageFiles.first,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        if (_imageFiles.length > 1)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(PhosphorIcons.images, color: Colors.white, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    '1/${_imageFiles.length}',
                                    style: AppTextStyles.labelSm.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Dot indicators in preview
                  if (_imageFiles.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_imageFiles.length.clamp(0, 6), (i) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == 0
                                  ? AppColors.primaryContainer
                                  : AppColors.outlineVariant.withValues(alpha: 0.5),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
                // Caption preview
                if (_captionCtrl.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Icon(PhosphorIcons.heart, size: 22, color: AppColors.onSurface),
                              SizedBox(width: 16),
                              Icon(PhosphorIcons.chatCircle, size: 22, color: AppColors.onSurface),
                              SizedBox(width: 16),
                              Icon(PhosphorIcons.paperPlaneTilt, size: 20, color: AppColors.onSurface),
                              Spacer(),
                              Icon(PhosphorIcons.bookmarkSimple, size: 22, color: AppColors.onSurface),
                            ],
                          ),
                        ),
                        RichText(
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.onSurface,
                              fontSize: 13,
                              height: 1.4,
                            ),
                            children: [
                              TextSpan(
                                text: '${member?.name ?? 'Vous'} ',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              TextSpan(text: _captionCtrl.text),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'A L\'INSTANT',
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Bar ────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.marginMobile),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          // Boutons Galerie/Photo masques quand le post est cree depuis
          // un evenement (l'evenement a deja sa propre image de couverture).
          if (!_isFromEvent) ...[
            _BottomAction(
              icon: PhosphorIcons.images,
              label: 'Galerie',
              onTap: _pickFromGallery,
            ),
            const SizedBox(width: AppSpacing.stackMd),
            _BottomAction(
              icon: PhosphorIcons.camera,
              label: 'Photo',
              onTap: _pickFromCamera,
            ),
            const Spacer(),
          ],
          AnimatedScale(
            duration: const Duration(milliseconds: 200),
            scale: _canPublish ? 1.0 : 0.95,
            child: SizedBox(
              width: _isFromEvent ? double.infinity : null,
              height: 48,
              child: ElevatedButton(
                onPressed: _canPublish ? _publish : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canPublish
                      ? AppColors.primaryContainer
                      : AppColors.outlineVariant.withValues(alpha: 0.3),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.outlineVariant.withValues(alpha: 0.3),
                  disabledForegroundColor: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                  elevation: _canPublish ? 2 : 0,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  textStyle: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w700),
                ),
                child: _isPublishing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Publier'),
                          if (_imageFiles.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              '(${_imageFiles.length})',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Success Overlay ──────────────────────────────────────────────────────────

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
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

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
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    PhosphorIcons.checkCircleFill,
                    color: AppColors.primaryContainer,
                    size: 56,
                  ),
                ),
                const SizedBox(height: AppSpacing.stackLg),
                Text(
                  'Post cree !',
                  style: AppTextStyles.headlineMd.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Votre publication est maintenant visible',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bottom Action Button ────────────────────────────────────────────────────

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.onSurface),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
