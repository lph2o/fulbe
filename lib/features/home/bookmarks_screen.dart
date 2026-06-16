// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../core/data/providers/data_providers.dart';
import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/post_card.dart';

/// Écran « Mes favoris » — liste tous les posts mis en favoris par
/// l'utilisateur courant.
class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPosts = ref.watch(bookmarkedPostsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft, size: 22),
          color: AppColors.onSurface,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Mes favoris',
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        centerTitle: true,
      ),
      body: asyncPosts.when(
        data: (posts) {
          if (posts.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.stackLg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      PhosphorIcons.bookmarkSimple,
                      size: 72,
                      color: AppColors.outlineVariant,
                    ),
                    SizedBox(height: AppSpacing.stackMd),
                    Text(
                      'Aucun favori',
                      style: AppTextStyles.headlineLgMobile.copyWith(
                        color: AppColors.onSurface,
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Appuie sur l\'icône marque-page d\'un post pour l\'ajouter à tes favoris.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: AppSpacing.stackLg),
                    FilledButton.tonalIcon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(PhosphorIcons.caretLeft, size: 18),
                      label: Text('Retour au feed'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(bookmarkedPostsProvider);
              await ref.read(bookmarkedPostsProvider.future);
            },
            child: ListView.separated(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.marginMobile,
                AppSpacing.stackMd,
                AppSpacing.marginMobile,
                AppSpacing.stackLg * 2,
              ),
              itemCount: posts.length,
              separatorBuilder: (_, __) =>
                  SizedBox(height: AppSpacing.stackMd),
              itemBuilder: (_, i) => PostCard(post: posts[i]),
            ),
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
                      : 'Impossible de charger les favoris.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
                SizedBox(height: AppSpacing.stackMd),
                FilledButton.tonalIcon(
                  onPressed: () => ref.invalidate(bookmarkedPostsProvider),
                  icon: Icon(PhosphorIcons.arrowsClockwise, size: 18),
                  label: Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
