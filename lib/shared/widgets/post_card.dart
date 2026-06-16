import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

import '../../core/data/models/post.dart' show Post, PostComment;
import '../../core/data/models/member.dart' show Member;
import '../../core/data/providers/data_providers.dart';
import '../../core/errors/app_exception.dart';
import '../../core/navigation/app_router.dart' show AppRoutes;
import '../helpers/contact_helper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'event_preview_card.dart';
import 'fc_card.dart';
import 'share_sheet.dart';
import 'repost_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PostCard — Instagram‑inspired feed card (public)
// ─────────────────────────────────────────────────────────────────────────────

class PostCard extends ConsumerStatefulWidget {
  final Post post;
  final bool compact;

  const PostCard({super.key, required this.post, this.compact = false});

  @override
  ConsumerState<PostCard> createState() => PostCardState();
}

class PostCardState extends ConsumerState<PostCard> {
  bool _showHeart = false;
  bool _isTogglingLike = false;
  bool _isTogglingBookmark = false;
  bool _isContacting = false;
  bool _isReposting = false;

  void openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (_) => _CommentsSheet(post: widget.post),
    );
  }

  Future<void> toggleLike() async {
    if (_isTogglingLike) return;
    // Utilise ref.read pour obtenir l'état frais du post depuis le provider
    // (widget.post est immutable et peut être stale après un invalidate).
    final posts = ref.read(postsProvider).valueOrNull;
    final freshPost = posts?.firstWhere(
          (p) => p.id == widget.post.id,
          orElse: () => widget.post,
        ) ??
        widget.post;
    final isLiking = !freshPost.isLiked;
    setState(() => _isTogglingLike = true);
    try {
      await ref.read(postsRepositoryProvider).toggleLike(
            postId: widget.post.id,
            isLiking: isLiking,
          );
      ref.invalidate(postsProvider);
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du like.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isTogglingLike = false);
    }
  }

  /// Ouvre la bottom sheet « Envoyer à... » pour partager en DM.
  void _sharePost(Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareSheet(
        postId: post.id,
        postAuthorName: post.authorName,
        postContent: post.content,
      ),
    ).then((_) {
      // Rafraîchit le compteur de partages après fermeture de la sheet
      ref.invalidate(postsProvider);
    });
  }

  /// Ouvre le dialogue de repost.
  Future<void> _repost() async {
    if (_isReposting) return;

    // Si déjà reposté, propose d'annuler
    // Utilise ref.read car on est dans un event handler (pas dans build)
    final posts = ref.read(postsProvider).valueOrNull ?? [];
    final freshPost = posts.firstWhere(
      (p) => p.id == widget.post.id,
      orElse: () => widget.post,
    );
    if (freshPost.isReposted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          title: const Row(
            children: [
              Icon(PhosphorIcons.arrowsClockwise,
                  size: 22, color: AppColors.primaryContainer),
              SizedBox(width: 10),
              Text(
                'Annuler le repost ?',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Text(
            'Ton repost sera supprimé de ton fil d\'actualité.',
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Garder',
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: const Text(
                'Annuler',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        await _undoRepost();
      }
      return;
    }

    // Pas encore reposté → ouvre le dialogue de repost
    setState(() => _isReposting = true);
    await showDialog(
      context: context,
      builder: (_) => RepostDialog(post: freshPost),
    );
    if (mounted) setState(() => _isReposting = false);
    ref.invalidate(postsProvider);
  }

  Future<void> _undoRepost() async {
    try {
      final currentMember = ref.read(currentMemberProvider).valueOrNull;
      if (currentMember == null) return;

      // Trouve le post de repost créé par l'utilisateur pour ce post original
      final posts = ref.read(postsProvider).valueOrNull ?? [];
      final repostPost = posts.firstWhere(
        (p) =>
            p.repostOf == widget.post.id && p.authorId == currentMember.id,
        orElse: () => widget.post,
      );

      if (repostPost.id != widget.post.id) {
        await ref.read(postsRepositoryProvider).undoRepost(repostPost.id);
        ref.invalidate(postsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Repost annulé.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
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
          const SnackBar(content: Text("Erreur lors de l'annulation.")),
        );
      }
    }
  }

  Future<void> _contactAuthor() async {
    if (_isContacting) return;
    setState(() => _isContacting = true);
    await ContactHelper.navigateToConversation(context, ref, widget.post.authorId);
    if (mounted) setState(() => _isContacting = false);
  }

  Future<void> toggleBookmark() async {
    if (_isTogglingBookmark) return;
    // Même logique que toggleLike : utiliser l'état frais du provider
    final posts = ref.read(postsProvider).valueOrNull;
    final freshPost = posts?.firstWhere(
          (p) => p.id == widget.post.id,
          orElse: () => widget.post,
        ) ??
        widget.post;
    final isBookmarking = !freshPost.isBookmarked;
    setState(() => _isTogglingBookmark = true);
    try {
      await ref.read(postsRepositoryProvider).toggleBookmark(
            postId: widget.post.id,
            isBookmarking: isBookmarking,
          );
      ref.invalidate(postsProvider);
      ref.invalidate(bookmarkedPostsProvider);
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du favori.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isTogglingBookmark = false);
    }
  }

  // ── Options menu (edit / delete) ───────────────────────────────────────────

  void _showPostOptions(Post post, Member? currentMember) {
    final isAuthor = currentMember != null && currentMember.id == post.authorId;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.stackSm),
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (isAuthor) ...[
                _OptionTile(
                  icon: PhosphorIcons.pencilSimple,
                  label: 'Modifier',
                  color: AppColors.onSurface,
                  onTap: () {
                    Navigator.pop(context);
                    _showEditDialog(post, currentMember);
                  },
                ),
                _OptionTile(
                  icon: PhosphorIcons.trash,
                  label: 'Supprimer',
                  color: AppColors.error,
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation();
                  },
                ),
              ] else ...[
                _OptionTile(
                  icon: PhosphorIcons.flag,
                  label: 'Signaler',
                  color: AppColors.onSurface,
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Signalement envoyé. Merci.')),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditDialog(Post post, Member currentMember) async {
    final ctrl = TextEditingController(text: post.content);
    final focusNode = FocusNode();
    final isSaving = ValueNotifier<bool>(false);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.marginMobile,
                      AppSpacing.stackSm,
                      AppSpacing.marginMobile,
                      0,
                    ),
                    child: Row(
                      children: [
                        const Icon(PhosphorIcons.pencilSimple,
                            size: 20, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text(
                          'Modifier le post',
                          style: AppTextStyles.labelMd.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(PhosphorIcons.x, size: 20),
                          color: AppColors.onSurfaceVariant,
                          onPressed: () => Navigator.pop(ctx),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Content preview
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.marginMobile,
                      AppSpacing.stackSm,
                      AppSpacing.marginMobile,
                      0,
                    ),
                    child: Row(
                      children: [
                        FcAvatar(
                          imageUrl: currentMember.avatarUrl,
                          initials: currentMember.initials,
                          size: 28,
                          showBorder: false,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currentMember.name,
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Edit field
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.marginMobile,
                      AppSpacing.stackSm,
                      AppSpacing.marginMobile,
                      AppSpacing.stackSm,
                    ),
                    child: TextField(
                      controller: ctrl,
                      focusNode: focusNode,
                      autofocus: true,
                      onChanged: (_) => setSheetState(() {}),
                      maxLines: 5,
                      minLines: 3,
                      maxLength: 500,
                      buildCounter: (_, {required currentLength, required int? maxLength, required isFocused}) =>
                          Text(
                            '$currentLength/${maxLength ?? 500}',
                            style: AppTextStyles.labelSm.copyWith(
                              color: maxLength != null && currentLength > maxLength * 0.9
                                  ? AppColors.error
                                  : AppColors.onSurfaceVariant,
                            ),
                          ),
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurface,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Modifie ton post...',
                        hintStyle: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
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
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  // Save button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.marginMobile,
                      0,
                      AppSpacing.marginMobile,
                      AppSpacing.stackMd,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ValueListenableBuilder<bool>(
                        valueListenable: isSaving,
                        builder: (_, saving, __) {
                          final canSave = !saving && ctrl.text.trim().isNotEmpty &&
                              ctrl.text.trim() != post.content.trim();
                          return FilledButton(
                            onPressed: canSave
                                ? () async {
                                    isSaving.value = true;
                                    await _saveEdit(ctrl.text.trim());
                                    if (ctx.mounted) Navigator.pop(ctx);
                                  }
                                : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryContainer,
                              disabledBackgroundColor:
                                  AppColors.outlineVariant.withValues(alpha: 0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                              ),
                            ),
                            child: saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Enregistrer',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    ctrl.dispose();
    focusNode.dispose();
  }

  Future<void> _saveEdit(String newContent) async {
    try {
      await ref.read(postsRepositoryProvider).updatePost(
            postId: widget.post.id,
            content: newContent,
          );
      ref.invalidate(postsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post modifié avec succès.'),
            duration: Duration(seconds: 2),
          ),
        );
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
          const SnackBar(content: Text('Erreur lors de la modification.')),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: const Row(
          children: [
            Icon(PhosphorIcons.trash, size: 22, color: AppColors.error),
            SizedBox(width: 10),
            Text(
              'Supprimer le post',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Cette action est irréversible. Veux-tu vraiment supprimer ce post ?',
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Annuler',
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
            ),
            child: const Text(
              'Supprimer',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _deletePost();
    }
  }

  Future<void> _deletePost() async {
    try {
      await ref.read(postsRepositoryProvider).deletePost(widget.post.id);
      ref.invalidate(postsProvider);
      // Invalide aussi le provider du profil pour que le post disparaisse
      // de la section "Activite recente" de l'utilisateur.
      ref.invalidate(userPostsProvider(widget.post.authorId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post supprimé.'),
            duration: Duration(seconds: 2),
          ),
        );
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
          const SnackBar(content: Text('Erreur lors de la suppression.')),
        );
      }
    }
  }

  void onDoubleTapImage() {
    if (!widget.post.isLiked) {
      toggleLike();
    }
    if (mounted) setState(() => _showHeart = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  Post _getFreshPost() {
    final posts = ref.watch(postsProvider).valueOrNull;
    return posts?.firstWhere(
          (p) => p.id == widget.post.id,
          orElse: () => widget.post,
        ) ??
        widget.post;
  }

  @override
  Widget build(BuildContext context) {
    final freshPost = _getFreshPost();

    final previewData =
        ref.watch(commentsPreviewProvider(widget.post.id)).valueOrNull;
    final commentsPreview = previewData?.comments ?? [];
    final realTotalCount =
        previewData?.totalCount ?? freshPost.commentsCount;

    final currentMember = ref.watch(currentMemberProvider).valueOrNull;
    const cardHorizontalPad = 12.0;
    final unshownComments = realTotalCount - commentsPreview.length;
    final postImages = freshPost.imageUrls;
    final displaySharesCount = freshPost.sharesCount;

    // Post original pour l'embed des reposts
    final repostOriginal = freshPost.repostOriginal;

    return FcCard(
      padding: EdgeInsets.zero,
      borderRadius: AppSpacing.radiusLg,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.publicProfile,
                    arguments: freshPost.authorId,
                  ),
                  child: FcAvatar(
                    imageUrl: freshPost.authorAvatarUrl,
                    size: 32,
                    showBorder: false,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pushNamed(
                              AppRoutes.publicProfile,
                              arguments: freshPost.authorId,
                            ),
                            child: Text(
                              freshPost.authorName,
                              style: AppTextStyles.labelSm.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Verified badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.primaryFixed,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(PhosphorIcons.sealCheck,
                                    size: 10, color: AppColors.primary),
                                SizedBox(width: 2),
                                Text(
                                  'Vérifié',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${freshPost.authorCity}, ${freshPost.authorCountry} · ${freshPost.timeAgo}',
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w400,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                // Contact author (hidden for own posts)
                if (currentMember?.id != freshPost.authorId)
                  GestureDetector(
                    onTap: _isContacting ? null : _contactAuthor,
                    child: _isContacting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(PhosphorIcons.chatCircleDots,
                            size: 18, color: AppColors.primaryContainer),
                  ),
                if (currentMember?.id != freshPost.authorId)
                  const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _showPostOptions(freshPost, currentMember),
                  child: const Icon(PhosphorIcons.dotsThree,
                      size: 18, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          // Visual area — images only (no placeholder when empty)
          if (postImages.isNotEmpty)
            Stack(
            alignment: Alignment.center,
            children: [
              if (postImages.length == 1)
                GestureDetector(
                  onDoubleTap: onDoubleTapImage,
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Image.network(
                      postImages.first,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.surfaceContainerHigh,
                        child: const Center(
                          child: Icon(PhosphorIcons.image,
                              color: AppColors.outline, size: 48),
                        ),
                      ),
                    ),
                  ),
                )
              else if (postImages.length > 1)
                PostImageCarousel(
                  imageUrls: postImages,
                  onDoubleTap: onDoubleTapImage,
                ),
              if (_showHeart)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  onEnd: () {
                    if (mounted) setState(() => _showHeart = false);
                  },
                  builder: (_, value, __) {
                    final scale = value < 0.7
                        ? value / 0.7
                        : 1.0 - ((value - 0.7) / 0.3);
                    final opacity = value < 0.5
                        ? value * 2
                        : (1.0 - value) * 2;
                    return Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: scale.clamp(0.0, 1.3),
                        child: const Icon(
                          PhosphorIcons.heartFill,
                          color: Colors.white,
                          size: 84,
                          shadows: [
                            Shadow(
                                blurRadius: 12, color: Colors.black26),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              // Like counter (only on real images)
              if (postImages.isNotEmpty)
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: toggleLike,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: freshPost.isLiked
                            ? Colors.red.withValues(alpha: 0.85)
                            : Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder:
                                (child, animation) => ScaleTransition(
                              scale: animation,
                              child: child,
                            ),
                            child: Icon(
                              freshPost.isLiked
                                  ? PhosphorIcons.heartFill
                                  : PhosphorIcons.heart,
                              key: ValueKey(freshPost.isLiked),
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _formatLikeCount(freshPost.likesCount),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),            // Event preview (if post links to an event)
            if (freshPost.eventId != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                child: EventPreviewCard(eventId: freshPost.eventId!),
              ),
            // Content
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: cardHorizontalPad,
              vertical: AppSpacing.stackSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Repost embed (si ce post est un repost)
                if (freshPost.repostOf != null) ...[
                  _buildRepostEmbed(freshPost, repostOriginal),
                  const SizedBox(height: AppSpacing.stackSm),
                ],
                // Actions
                Row(
                  children: [
                    GestureDetector(
                      onTap: toggleLike,
                      child: Icon(
                        freshPost.isLiked
                            ? PhosphorIcons.heartFill
                            : PhosphorIcons.heart,
                        size: 22,
                        color: freshPost.isLiked
                            ? Colors.red
                            : AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: openComments,
                      child: const Icon(PhosphorIcons.chatCircle,
                          size: 22, color: AppColors.onSurface),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: _isReposting ? null : () => _repost(),
                      child: Icon(
                        PhosphorIcons.arrowsClockwise,
                        size: 22,
                        color: freshPost.isReposted
                            ? AppColors.primaryContainer
                            : AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => _sharePost(freshPost),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(PhosphorIcons.paperPlaneTilt,
                              size: 20, color: AppColors.onSurface),
                          if (displaySharesCount > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              '$displaySharesCount',
                              style: AppTextStyles.labelSm.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _isTogglingBookmark ? null : toggleBookmark,
                      child: Icon(
                        freshPost.isBookmarked
                            ? PhosphorIcons.bookmarkSimpleFill
                            : PhosphorIcons.bookmarkSimple,
                        size: 22,
                        color: freshPost.isBookmarked
                            ? AppColors.primaryContainer
                            : AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackSm),
                // Likes (hidden in compact mode)
                if (freshPost.likesCount > 0 && !widget.compact)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _buildLikesPreview(freshPost),
                  ),
                // Caption
                if (freshPost.content.isNotEmpty)
                  _buildCaption(freshPost),
                // Comments preview (hidden in compact mode)
                if (commentsPreview.isNotEmpty && !widget.compact)
                  _buildCommentsPreview(commentsPreview, unshownComments),
                const SizedBox(height: 6),
                Text(
                  freshPost.timeAgo.toUpperCase(),
                  style: AppTextStyles.labelSm.copyWith(
                    color:
                        AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // Inline input (hidden in compact mode)
          if (!widget.compact)
            GestureDetector(
              onTap: openComments,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color:
                          AppColors.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    FcAvatar(
                      imageUrl: currentMember?.avatarUrl,
                      initials: currentMember?.initials,
                      size: 24,
                      showBorder: false,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ajouter un commentaire...',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant
                              .withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Icon(PhosphorIcons.smiley,
                        size: 18, color: AppColors.onSurfaceVariant),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Affiche la carte embed du post original pour les reposts.
  Widget _buildRepostEmbed(Post repost, Post? original) {
    // Si le post original n'est pas encore chargé, on n'affiche rien
    if (original == null) return const SizedBox.shrink();

    final displayPost = original;
    final hasComment = repost.content.isNotEmpty;
    final repostImages = displayPost.imageUrls;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label "Reposté"
        Row(
          children: [
            const Icon(PhosphorIcons.arrowsClockwise,
                size: 14, color: AppColors.primaryContainer),
            const SizedBox(width: 4),
            Text(
              '${repost.authorName} a reposté',
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.primaryContainer,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        // Commentaire du reposteur
        if (hasComment) ...[
          const SizedBox(height: 6),
          Text(
            repost.content,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurface,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.stackSm),
        // Carte embed du post original
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    FcAvatar(
                      imageUrl: displayPost.authorAvatarUrl,
                      size: 24,
                      showBorder: false,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayPost.authorName,
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${displayPost.authorCity}, ${displayPost.authorCountry} · ${displayPost.timeAgo}',
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
                if (displayPost.content.isNotEmpty && !hasComment) ...[
                  const SizedBox(height: 8),
                  Text(
                    displayPost.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurface,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
                // Image du post original (première image du carrousel)
                if (repostImages.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: AspectRatio(
                      aspectRatio: 1.6,
                      child: Image.network(
                        repostImages.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.surfaceContainerHigh,
                          child: const Center(
                            child: Icon(PhosphorIcons.image,
                                color: AppColors.outline, size: 24),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLikesPreview(Post post) {
    final firstLiker = post.firstLikerName;
    final otherCount = post.likesCount - 1;

    if (firstLiker != null && otherCount > 0) {
      return GestureDetector(
        onTap: openComments,
        child: RichText(
          text: TextSpan(
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
            children: [
              const TextSpan(text: 'Aimé par '),
              TextSpan(
                text: firstLiker,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(text: ' et $otherCount autres'),
            ],
          ),
        ),
      );
    } else if (firstLiker != null) {
      return GestureDetector(
        onTap: openComments,
        child: RichText(
          text: TextSpan(
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
            children: [
              const TextSpan(text: 'Aimé par '),
              TextSpan(
                text: firstLiker,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      );
    } else {
      return Text(
        '${post.likesCount} J\'aime',
        style: AppTextStyles.labelSm.copyWith(
          color: AppColors.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      );
    }
  }

  Widget _buildCaption(Post post) {
    const maxLines = 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final span = TextSpan(
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.onSurface,
            fontSize: 13,
            height: 1.4,
          ),
          children: [
            TextSpan(
              text: '${post.authorName} ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: post.content),
          ],
        );

        final tp = TextPainter(
          text: span,
          maxLines: maxLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final didOverflow = tp.didExceedMaxLines;

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                text: span,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
              if (didOverflow)
                GestureDetector(
                  onTap: () => _showFullCaption(post),
                  child: Text(
                    'plus',
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showFullCaption(Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.stackMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.marginMobile,
                  AppSpacing.stackMd,
                  AppSpacing.marginMobile,
                  AppSpacing.stackSm,
                ),
                child: Row(
                  children: [
                    FcAvatar(
                      imageUrl: post.authorAvatarUrl,
                      size: 32,
                      showBorder: false,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorName,
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${post.authorCity}, ${post.authorCountry} · ${post.timeAgo}',
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.w400,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(PhosphorIcons.x, size: 20),
                      color: AppColors.onSurfaceVariant,
                      onPressed: () => Navigator.pop(context),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.marginMobile),
                  child: Text(
                    post.content,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurface,
                      fontSize: 15,
                      height: 1.6,
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

  String _formatLikeCount(int count) {
    if (count < 1000) return '$count';
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }

  Widget _buildCommentsPreview(
      List<PostComment> comments, int unshownCount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (unshownCount > 0)
            GestureDetector(
              onTap: openComments,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  'Voir les $unshownCount commentaires',
                  style: AppTextStyles.labelSm.copyWith(
                    color:
                        AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          for (final c in comments)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: GestureDetector(
                onTap: openComments,
                child: RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurface,
                      fontSize: 12,
                      height: 1.35,
                    ),
                    children: [
                      TextSpan(
                        text: '${c.authorName} ',
                        style:
                            const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: c.content),
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

// ─────────────────────────────────────────────────────────────────────────────
// PostImageCarousel — PageView with dot indicators
// ─────────────────────────────────────────────────────────────────────────────

class PostImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final VoidCallback? onDoubleTap;

  const PostImageCarousel({
    super.key,
    required this.imageUrls,
    this.onDoubleTap,
  });

  @override
  State<PostImageCarousel> createState() => _PostImageCarouselState();
}

class _PostImageCarouselState extends State<PostImageCarousel> {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.imageUrls;

    return GestureDetector(
      onDoubleTap: widget.onDoubleTap,
      child: SizedBox(
        width: double.infinity,
        child: AspectRatio(
          aspectRatio: 1.0,
          child: Stack(
            children: [
              PageView(
                controller: _pageCtrl,
                onPageChanged: (i) {
                  if (mounted) setState(() => _currentPage = i);
                },
                children: images.map((url) => Image.network(
                  url,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.surfaceContainerHigh,
                    child: const Center(
                      child: Icon(PhosphorIcons.image,
                          color: AppColors.outline, size: 48),
                    ),
                  ),
                )).toList(),
              ),
              // Page indicator dots
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: SafeArea(
                  top: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(images.length, (i) {
                      final isActive = _currentPage == i;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin:
                            const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 8 : 6,
                        height: isActive ? 8 : 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.2),
                                    blurRadius: 2,
                                  )
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Comments Bottom Sheet (private to this file)
// ─────────────────────────────────────────────────────────────────────────────

class _CommentsSheet extends ConsumerStatefulWidget {
  final Post post;
  const _CommentsSheet({required this.post});

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _textCtrl = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSending = false;

  String? _replyingToCommentId;
  String? _replyingToAuthorName;
  String _mentionQuery = '';

  @override
  void initState() {
    super.initState();
    _textCtrl.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onTextChanged() {
    _updateMentionQuery();
    setState(() {});
  }

  void _updateMentionQuery() {
    final text = _textCtrl.text;
    final cursor = _textCtrl.selection.baseOffset;
    if (cursor < 0) {
      _mentionQuery = '';
      return;
    }

    final textBefore = text.substring(0, cursor);
    final atIndex = textBefore.lastIndexOf('@');
    if (atIndex == -1) {
      _mentionQuery = '';
      return;
    }

    if (atIndex > 0 &&
        textBefore[atIndex - 1] != ' ' &&
        textBefore[atIndex - 1] != '\n') {
      _mentionQuery = '';
      return;
    }

    final query = textBefore.substring(atIndex + 1);
    if (query.contains(' ') || query.length > 50) {
      _mentionQuery = '';
      return;
    }

    _mentionQuery = query.toLowerCase();
  }

  void _insertMention(Member member) {
    final text = _textCtrl.text;
    final cursor = _textCtrl.selection.baseOffset;
    final textBefore = text.substring(0, cursor);
    final atIndex = textBefore.lastIndexOf('@');
    if (atIndex == -1) return;

    final beforeAt = textBefore.substring(0, atIndex);
    final afterCursor = text.substring(cursor);
    final mention = '@${member.name} ';

    _textCtrl.text = '$beforeAt$mention$afterCursor';
    final newPos = beforeAt.length + mention.length;
    _textCtrl.selection = TextSelection.collapsed(offset: newPos);
    _mentionQuery = '';
  }

  Widget _buildMentionSuggestions() {
    final members = ref.watch(membersProvider).valueOrNull ?? const [];
    final query = _mentionQuery;

    final startsWith = <Member>[];
    final contains = <Member>[];
    for (final m in members) {
      final name = m.name.toLowerCase();
      if (!name.contains(query)) continue;
      if (name.startsWith(query)) {
        startsWith.add(m);
      } else {
        contains.add(m);
      }
    }
    final matches = [...startsWith, ...contains].take(6).toList();

    if (matches.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: matches.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
        itemBuilder: (_, i) {
          final m = matches[i];
          return InkWell(
            onTap: () => _insertMention(m),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile,
                vertical: 10,
              ),
              child: Row(
                children: [
                  FcAvatar(
                    imageUrl: m.avatarUrl,
                    initials: m.initials,
                    size: 32,
                  ),
                  const SizedBox(width: AppSpacing.stackSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.name,
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          m.profession,
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (m.isVerified)
                    const Icon(PhosphorIcons.sealCheck,
                        size: 16, color: AppColors.tertiaryContainer),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _onFocusChanged() => setState(() {});

  @override
  void dispose() {
    _textCtrl.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startReply(String commentId, String authorName) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToAuthorName = authorName;
    });
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToAuthorName = null;
    });
  }

  void _showEmojiPicker() {
    final wasFocused = _focusNode.hasFocus;
    _focusNode.unfocus();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.45,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile,
                vertical: AppSpacing.stackSm,
              ),
              child: Row(
                children: [
                  const Icon(PhosphorIcons.smiley,
                      size: 20, color: AppColors.onSurface),
                  const SizedBox(width: 8),
                  Text(
                    'Choisir un emoji',
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(PhosphorIcons.x, size: 20),
                    color: AppColors.onSurfaceVariant,
                    onPressed: () => Navigator.of(context).pop(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  final text = _textCtrl.text;
                  final selection = _textCtrl.selection;
                  final cursorPos = selection.isValid
                      ? selection.baseOffset
                      : text.length;
                  final newText = text.substring(0, cursorPos) +
                      emoji.emoji +
                      text.substring(cursorPos);

                  _textCtrl.text = newText;
                  _textCtrl.selection = TextSelection.collapsed(
                      offset: cursorPos + emoji.emoji.length);
                },
                config: const Config(
                  categoryViewConfig: CategoryViewConfig(
                    indicatorColor: AppColors.primaryContainer,
                    iconColorSelected: AppColors.primaryContainer,
                    iconColor: AppColors.onSurfaceVariant,
                    backgroundColor: AppColors.surface,
                    dividerColor: AppColors.outlineVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      if (wasFocused && mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  Future<void> _sendComment() async {
    final content = _textCtrl.text.trim();
    if (content.isEmpty || _isSending) return;

    final member = ref.read(currentMemberProvider).valueOrNull;
    if (member == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Vous devez être connecté pour commenter.')),
        );
      }
      return;
    }

    setState(() => _isSending = true);

    try {
      await ref.read(postsRepositoryProvider).addComment(
            postId: widget.post.id,
            authorMemberId: member.id,
            content: content,
            parentCommentId: _replyingToCommentId,
          );

      _textCtrl.clear();
      _cancelReply();
      _focusNode.unfocus();

      ref.invalidate(commentsProvider(widget.post.id));
      ref.invalidate(commentsPreviewProvider(widget.post.id));
      ref.invalidate(postsProvider);
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _toggleCommentLike(String commentId) async {
    try {
      final asyncComments = ref.read(commentsProvider(widget.post.id));
      final comment =
          asyncComments.value?.firstWhere((c) => c.id == commentId);
      if (comment == null) return;

      await ref.read(postsRepositoryProvider).toggleCommentLike(
            commentId: commentId,
            isLiking: !comment.isLiked,
          );

      ref.invalidate(commentsProvider(widget.post.id));
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du like.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncComments = ref.watch(commentsProvider(widget.post.id));
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final posts = ref.watch(postsProvider).valueOrNull;
    final freshPost = posts?.firstWhere(
          (p) => p.id == widget.post.id,
          orElse: () => widget.post,
        ) ??
        widget.post;
    final freshCommentsCount = freshPost.commentsCount;

    final loadedCommentCount =
        asyncComments.valueOrNull?.length ?? freshCommentsCount;

    final currentMember = ref.watch(currentMemberProvider).valueOrNull;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.marginMobile,
                AppSpacing.stackSm,
                AppSpacing.marginMobile,
                0,
              ),
              child: Row(
                children: [
                  const Icon(PhosphorIcons.chatCircle,
                      size: 20, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    'Commentaires ($loadedCommentCount)',
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(PhosphorIcons.x, size: 20),
                    color: AppColors.onSurfaceVariant,
                    onPressed: () => Navigator.of(context).pop(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: asyncComments.when(
                data: (comments) {
                  if (comments.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(PhosphorIcons.chatCircle,
                              size: 48, color: AppColors.outlineVariant),
                          const SizedBox(height: AppSpacing.stackMd),
                          Text(
                            'Soyez le premier à commenter !',
                            style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final rootComments = comments
                      .where((c) => c.parentCommentId == null)
                      .toList();
                  final replies = comments
                      .where((c) => c.parentCommentId != null)
                      .toList();
                  final ordered = <PostComment>[];
                  for (final root in rootComments) {
                    ordered.add(root);
                    for (final reply in replies
                        .where((r) => r.parentCommentId == root.id)) {
                      ordered.add(reply);
                    }
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.marginMobile,
                        vertical: AppSpacing.stackSm),
                    itemCount: ordered.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 60),
                    itemBuilder: (_, i) {
                      final comment = ordered[i];
                      final isReply = comment.parentCommentId != null;
                      return Padding(
                        padding:
                            EdgeInsets.only(left: isReply ? 48.0 : 0),
                        child: _CommentTile(
                          comment: comment,
                          onReply: () => _startReply(
                              comment.id, comment.authorName),
                          onToggleLike: () =>
                              _toggleCommentLike(comment.id),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child:
                        CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.stackLg),
                    child: Text(
                      e is AppException
                          ? e.message
                          : 'Impossible de charger les commentaires.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMd
                          .copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
            ),
            if (_mentionQuery.isNotEmpty) ...[
              _buildMentionSuggestions(),
            ],
            AnimatedSlide(
              duration: const Duration(milliseconds: 200),
              offset: _replyingToCommentId != null
                  ? Offset.zero
                  : const Offset(0, 0.5),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _replyingToCommentId != null ? 1.0 : 0.0,
                child: AnimatedContainer(
                  clipBehavior: Clip.hardEdge,
                  duration: const Duration(milliseconds: 200),
                  height: _replyingToCommentId != null ? 40.0 : 0.0,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer
                        .withValues(alpha: 0.08),
                    border: Border(
                      top: BorderSide(
                          color: AppColors.outlineVariant
                              .withValues(alpha: 0.5)),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.marginMobile,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(PhosphorIcons.arrowBendUpLeft,
                          size: 16, color: AppColors.primaryContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Réponse à ${_replyingToAuthorName ?? "quelqu'un"}',
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.primaryContainer,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: _cancelReply,
                        child: const Icon(PhosphorIcons.x,
                            size: 18,
                            color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(
                      color: AppColors.outlineVariant
                          .withValues(alpha: 0.5)),
                ),
              ),
              padding: EdgeInsets.only(
                left: AppSpacing.stackSm,
                right: AppSpacing.stackSm,
                top: 10,
                bottom: 10 + MediaQuery.of(context).padding.bottom,
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FcAvatar(
                      imageUrl: currentMember?.avatarUrl,
                      initials: currentMember?.initials,
                      size: 32,
                    ),
                    const SizedBox(width: AppSpacing.stackSm),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusFull),
                          border: Border.all(
                            color: _focusNode.hasFocus
                                ? AppColors.primaryContainer
                                    .withValues(alpha: 0.35)
                                : Colors.transparent,
                            width: 1.5,
                          ),
                          boxShadow: _focusNode.hasFocus
                              ? [
                                  BoxShadow(
                                    color: AppColors.primaryContainer
                                        .withValues(alpha: 0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                              minHeight: 40, maxHeight: 120),
                          child: TextField(
                            controller: _textCtrl,
                            focusNode: _focusNode,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.send,
                            onSubmitted: _isSending
                                ? null
                                : (_) => _sendComment(),
                            maxLines: null,
                            style: AppTextStyles.bodyMd.copyWith(
                                color: AppColors.onSurface, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: _replyingToCommentId != null
                                  ? 'Écrire une réponse...'
                                  : 'Ajouter un commentaire...',
                              hintStyle: const TextStyle(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 14),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                              isDense: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(PhosphorIcons.smiley, size: 22),
                      color: AppColors.onSurfaceVariant,
                      onPressed: _showEmojiPicker,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                          minWidth: 36, minHeight: 36),
                    ),
                    AnimatedScale(
                      duration: const Duration(milliseconds: 200),
                      scale: _textCtrl.text.trim().isEmpty ? 0.0 : 1.0,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity:
                            _textCtrl.text.trim().isEmpty ? 0.0 : 1.0,
                        child: IconButton(
                          icon: _isSending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Icon(
                                  PhosphorIcons.paperPlaneTilt,
                                  size: 22),
                          color: AppColors.primaryContainer,
                          onPressed:
                              _isSending ? null : _sendComment,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 36, minHeight: 36),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final PostComment comment;
  final VoidCallback? onReply;
  final VoidCallback? onToggleLike;
  const _CommentTile({
    required this.comment,
    this.onReply,
    this.onToggleLike,
  });

  void _openProfile(BuildContext context) {
    // Close the comments bottom sheet first, then navigate.
    // This way the back button returns to the feed, not the comments sheet.
    Navigator.of(context).pop();
    Navigator.of(context).pushNamed(
      AppRoutes.publicProfile,
      arguments: comment.authorId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _openProfile(context),
            child: FcAvatar(
              imageUrl: comment.authorAvatarUrl,
              size: 40,
            ),
          ),
          const SizedBox(width: AppSpacing.stackSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _openProfile(context),
                      child: Text(
                        comment.authorName,
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatTime(comment.createdAt),
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  comment.content,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurface,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (onToggleLike != null) ...[
                      GestureDetector(
                        onTap: onToggleLike,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              comment.isLiked
                                  ? PhosphorIcons.heartFill
                                  : PhosphorIcons.heart,
                              size: 14,
                              color: comment.isLiked
                                  ? Colors.red
                                  : AppColors.onSurfaceVariant,
                            ),
                            if (comment.likesCount > 0) ...[
                              const SizedBox(width: 2),
                              Text(
                                '${comment.likesCount}',
                                style: AppTextStyles.labelSm.copyWith(
                                  fontSize: 11,
                                  color: comment.isLiked
                                      ? Colors.red
                                      : AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (onReply != null)
                      GestureDetector(
                        onTap: onReply,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(PhosphorIcons.arrowBendUpLeft,
                                size: 14,
                                color: AppColors.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              'Répondre',
                              style: AppTextStyles.labelSm.copyWith(
                                fontSize: 11,
                                color: AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'il y a ${diff.inDays}j';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _OptionTile — option row used in the post options bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: AppTextStyles.labelMd.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }
}
