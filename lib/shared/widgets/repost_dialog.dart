import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/models/post.dart' show Post;
import '../../core/data/providers/data_providers.dart';
import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'fc_card.dart';

/// Dialogue de confirmation pour reposter un post.
///
/// Affiche un champ de commentaire optionnel et un aperçu du post original.
///
/// Usage :
/// ```dart
/// final result = await showDialog<RepostResult>(
///   context: context,
///   builder: (_) => RepostDialog(post: post),
/// );
/// ```
class RepostResult {
  final String comment;
  const RepostResult({this.comment = ''});
}

class RepostDialog extends ConsumerStatefulWidget {
  final Post post;

  const RepostDialog({super.key, required this.post});

  @override
  ConsumerState<RepostDialog> createState() => _RepostDialogState();
}

class _RepostDialogState extends ConsumerState<RepostDialog> {
  final _commentCtrl = TextEditingController();
  bool _isReposting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _repost() async {
    if (_isReposting) return;
    setState(() => _isReposting = true);

    try {
      final currentMember = ref.read(currentMemberProvider).valueOrNull;
      if (currentMember == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vous devez être connecté.')),
          );
        }
        return;
      }

      await ref.read(postsRepositoryProvider).repost(
            originalPostId: widget.post.id,
            authorMemberId: currentMember.id,
            comment: _commentCtrl.text.trim(),
          );

      ref.invalidate(postsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post reposté !'),
            duration: Duration(seconds: 2),
            backgroundColor: AppColors.primaryContainer,
          ),
        );
        Navigator.of(context).pop(const RepostResult());
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du repost.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isReposting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      actionsPadding:
          const EdgeInsets.fromLTRB(16, 8, 16, AppSpacing.stackMd),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(PhosphorIcons.arrowsClockwise,
                size: 20, color: AppColors.primaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Reposter ce post ?',
              style: AppTextStyles.labelLg.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comment field
          const SizedBox(height: AppSpacing.stackSm),
          TextField(
            controller: _commentCtrl,
            maxLines: 3,
            minLines: 1,
            maxLength: 300,
            autofocus: true,
            buildCounter: (_, {required currentLength, required int? maxLength, required isFocused}) =>
                Text(
                  '$currentLength/${maxLength ?? 300}',
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurface,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Ajouter un commentaire... (optionnel)',
              hintStyle: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                fontSize: 14,
              ),
              filled: true,
              fillColor: AppColors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                borderSide: const BorderSide(
                  color: AppColors.primaryContainer,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          // Post preview
          Text(
            'Aperçu du post original',
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          FcCard(
            padding: const EdgeInsets.all(12),
            borderRadius: AppSpacing.radiusMd,
            color: AppColors.surfaceContainerLow,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    FcAvatar(
                      imageUrl: widget.post.authorAvatarUrl,
                      size: 24,
                      showBorder: false,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.post.authorName,
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${widget.post.authorCity}, ${widget.post.authorCountry}',
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (widget.post.content.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.post.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurface,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.stackSm),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isReposting ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Annuler',
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        FilledButton(
          onPressed: _isReposting ? null : _repost,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryContainer,
            disabledBackgroundColor:
                AppColors.outlineVariant.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
          child: _isReposting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Reposter',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ],
    );
  }
}
