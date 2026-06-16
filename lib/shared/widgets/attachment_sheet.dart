import 'dart:io';

import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

// ── Types de pièces jointes ─────────────────────────────────────────────────

/// Type de média ou fichier à attacher à un message.
enum AttachmentType { photo, gallery, video, document }

// ── Sheet de sélection du type de pièce jointe ──────────────────────────────

/// Bottom sheet affichant les 4 options de pièce jointe :
/// Photo, Galerie, Vidéo, Fichier.
/// Retourne un [AttachmentType] via [Navigator.pop].
class AttachmentSheet extends StatelessWidget {
  const AttachmentSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Pièce jointe',
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _AttachmentOption(
                  icon: PhosphorIcons.camera,
                  label: 'Photo',
                  color: AppColors.primary,
                  onTap: () => Navigator.pop(context, AttachmentType.photo),
                ),
                _AttachmentOption(
                  icon: PhosphorIcons.images,
                  label: 'Galerie',
                  color: AppColors.secondaryContainer,
                  onTap: () => Navigator.pop(context, AttachmentType.gallery),
                ),
                _AttachmentOption(
                  icon: PhosphorIcons.videoCamera,
                  label: 'Vidéo',
                  color: AppColors.tertiary,
                  onTap: () => Navigator.pop(context, AttachmentType.video),
                ),
                _AttachmentOption(
                  icon: PhosphorIcons.fileText,
                  label: 'Fichier',
                  color: AppColors.teal,
                  onTap: () => Navigator.pop(context, AttachmentType.document),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Prévisualisation avant envoi ────────────────────────────────────────────

/// Bottom sheet affichant un aperçu du média (image ou vidéo) avant envoi,
/// avec un champ de légende, le nom/size du fichier, et les boutons Envoyer/Annuler.
///
/// Retourne `null` si annulé, ou la légende (String, peut être vide) si Envoyer.
/// Retourne [SendPreviewSheetState.repickSentinel] si l'utilisateur veut
/// reprendre la photo/vidéo.
class SendPreviewSheet extends StatefulWidget {
  final File file;
  final String fileName;
  final String metadataType; // 'image' ou 'video'
  final String fileSize;

  const SendPreviewSheet({
    super.key,
    required this.file,
    required this.fileName,
    required this.metadataType,
    required this.fileSize,
  });

  @override
  State<SendPreviewSheet> createState() => SendPreviewSheetState();
}

class SendPreviewSheetState extends State<SendPreviewSheet> {
  final _captionController = TextEditingController();
  String? _thumbnailPath;

  /// Valeur sentinelle renvoyée via [Navigator.pop] pour signaler au parent
  /// que l'utilisateur souhaite reprendre une nouvelle photo/vidéo.
  static const repickSentinel = '__REPICK__';

  @override
  void initState() {
    super.initState();
    if (widget.metadataType == 'video') {
      _generateThumbnail();
    }
  }

  Future<void> _generateThumbnail() async {
    try {
      final path = await VideoThumbnail.thumbnailFile(
        video: widget.file.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 320,
        quality: 75,
      );
      if (mounted) {
        setState(() => _thumbnailPath = path);
      }
    } catch (_) {
      // Thumbnail non disponible — fallback affiché
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _send() {
    final caption = _captionController.text;
    Navigator.pop(context, caption);
  }

  void _cancel() {
    Navigator.pop(context, null);
  }

  void _repick() {
    Navigator.pop(context, repickSentinel);
  }

  /// Construit la preview vidéo : thumbnail réel si dispo, sinon fond sombre + icône play.
  Widget _buildVideoPreview() {
    if (_thumbnailPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            Image.file(
              File(_thumbnailPath!),
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => _buildVideoFallback(),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.85),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                PhosphorIcons.play,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      );
    }
    return _buildVideoFallback();
  }

  Widget _buildVideoFallback() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.85),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            PhosphorIcons.play,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isImage = widget.metadataType == 'image';
    final displayName = widget.fileName.split('/').last;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final maxPreviewHeight = MediaQuery.of(context).size.height * 0.35;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          // ── Header ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Row(
              children: [
                Icon(
                  isImage ? PhosphorIcons.image : PhosphorIcons.videoCamera,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isImage ? 'Aperçu de la photo' : 'Aperçu de la vidéo',
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Preview ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxPreviewHeight),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: isImage
                        ? Image.file(
                            widget.file,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => Container(
                              height: 180,
                              color: AppColors.surfaceContainerHigh,
                              child: const Center(
                                child: Icon(
                                  PhosphorIcons.image,
                                  size: 48,
                                  color: AppColors.outline,
                                ),
                              ),
                            ),
                          )
                        : _buildVideoPreview(),
                  ),
                  // ── Retake button ──────────────────────
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _repick,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isImage
                              ? PhosphorIcons.camera
                              : PhosphorIcons.videoCamera,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── File info ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        widget.fileSize,
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Caption field ───────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _captionController,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.onSurface,
                ),
                decoration: const InputDecoration(
                  hintText: 'Ajouter une légende…',
                  hintStyle: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          // ── Buttons ─────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 12 + safeBottom),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.onSurface,
                      side: const BorderSide(color: AppColors.outline),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _send,
                    icon: const Icon(PhosphorIcons.paperPlaneTilt, size: 18),
                    label: const Text('Envoyer'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
