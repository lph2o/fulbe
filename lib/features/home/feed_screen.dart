import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers/data_providers.dart';
import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/post_card.dart' show PostCard;

// ─────────────────────────────────────────────────────────────────────────────
// Mock data for the 6 example publications
// ─────────────────────────────────────────────────────────────────────────────

class _MockFeedItem {
  final int type; // 1=texte, 2=image, 3=emploi, 4=événement, 5=article
  final String initials;
  final Color avatarBg;
  final String name;
  final bool verified;
  final String meta;
  final String? text;
  final String? hashtags;
  final int likes;
  final int comments;
  final int shares;

  // Job-specific
  final String? jobTitle;
  final String? jobCompany;
  final String? jobTags1;
  final String? jobTags2;
  final String? jobButton;

  // Event-specific
  final Color? eventColor;
  final String? eventTitle;
  final String? eventDate;
  final String? eventLocation;
  final String? eventBadge;
  final IconData? eventIcon;

  // Article-specific
  final String? articleCategory;
  final String? articleTitle;
  final String? articleSummary;
  final String? articleDuration;
  final Color? articleColor;

  const _MockFeedItem({
    required this.type,
    required this.initials,
    required this.avatarBg,
    required this.name,
    this.verified = false,
    required this.meta,
    this.text,
    this.hashtags,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.jobTitle,
    this.jobCompany,
    this.jobTags1,
    this.jobTags2,
    this.jobButton,
    this.eventColor,
    this.eventTitle,
    this.eventDate,
    this.eventLocation,
    this.eventBadge,
    this.eventIcon,
    this.articleCategory,
    this.articleTitle,
    this.articleSummary,
    this.articleDuration,
    this.articleColor,
  });
}

const _mockFeed = [
  // ── Publication 1 — Type 1 (texte) ──────────────────────────────────────
  _MockFeedItem(
    type: 1,
    initials: 'MD',
    avatarBg: AppColors.primaryContainer,
    name: 'Mamadou Diallo',
    verified: true,
    meta: 'Développeur Full Stack · Milan, Italie · il y a 2h',
    text:
        "Ravi d'annoncer que je rejoins la communauté Fulɓe Connect ! Développeur Full Stack basé à Milan, je suis convaincu que notre diaspora peut rayonner dans la tech mondiale. Si tu cherches un collaborateur ou un partenaire tech, mon DM est ouvert.",
    hashtags: '#Fulɓe #Tech #Milan #Diaspora',
    likes: 48,
    comments: 12,
    shares: 7,
  ),
  // ── Publication 2 — Type 3 (emploi) ─────────────────────────────────────
  _MockFeedItem(
    type: 3,
    initials: 'RC',
    avatarBg: AppColors.secondary,
    name: 'Recrutement Connect',
    meta: 'Emploi & Carrières · Paris, France · il y a 4h',
    jobTitle: 'Lead Developer React/Node',
    jobCompany: 'FinTech Paris · CDI · Présentiel',
    jobTags1: '60–80k€',
    jobTags2: 'Paris',
    jobButton: 'Postuler',
  ),
  // ── Publication 3 — Type 2 (image) ──────────────────────────────────────
  _MockFeedItem(
    type: 2,
    initials: 'FB',
    avatarBg: AppColors.tertiary,
    name: 'Fatoumata Barry',
    verified: true,
    meta: 'Médecin · Bruxelles, Belgique · il y a 6h',
    text:
        "Honneur d'avoir représenté la communauté peule au Forum Santé Europe 2025 à Bruxelles. Ensemble, on avance.",
    likes: 134,
    comments: 28,
    shares: 19,
  ),
  // ── Publication 4 — Type 4 (événement) ──────────────────────────────────
  _MockFeedItem(
    type: 4,
    initials: 'FC',
    avatarBg: AppColors.primaryContainer,
    name: 'Fulɓe Connect Officiel',
    meta: 'Événements · il y a 8h',
    eventColor: AppColors.primary,
    eventIcon: PhosphorIcons.mapPin,
    eventTitle: 'Rencontre Fulɓe Italie — Milan',
    eventDate: 'Samedi 15 Juin 2025 · 14h00',
    eventLocation: 'Centro Culturale, Via Torino 12, Milan',
    eventBadge: 'ÉVÉNEMENT',
  ),
  // ── Publication 5 — Type 5 (article / culture) ──────────────────────────
  _MockFeedItem(
    type: 5,
    initials: 'BF',
    avatarBg: Color(0xFF1A1A1A),
    name: 'Bibliothèque Fulɓe',
    meta: 'Culture & Patrimoine · il y a 1 jour',
    articleCategory: 'PATRIMOINE',
    articleColor: AppColors.secondary,
    articleTitle:
        "L'histoire des empires peuls : de Fouta-Djalon à Sokoto",
    articleSummary:
        'Une plongée dans les grandes dynasties qui ont façonné l\'Afrique de l\'Ouest pendant des siècles.',
    articleDuration: '8 min de lecture',
  ),
  // ── Publication 6 — Type 1 (texte) ──────────────────────────────────────
  _MockFeedItem(
    type: 1,
    initials: 'AK',
    avatarBg: AppColors.secondary,
    name: 'Aissatou Kouyaté',
    meta: 'Entrepreneur · Dakar, Sénégal · il y a 2 jours',
    text:
        'Lancement officiel de ma startup ce mois-ci. 2 ans de travail, des nuits sans sommeil, et enfin... un produit qui va changer la vie de milliers de femmes entrepreneures en Afrique. Merci à ma communauté Fulɓe pour le soutien. 🙏',
    hashtags: '#Startup #Entrepreneuriat #Afrique #Fulɓe',
    likes: 312,
    comments: 67,
    shares: 45,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// FeedScreen — Premium redesign with 5 card types
// ─────────────────────────────────────────────────────────────────────────────

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPosts = ref.watch(postsProvider);
    final posts = asyncPosts.valueOrNull ?? const [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          // ── Premium Sliver AppBar ─────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 100,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(PhosphorIcons.arrowLeft,
                  color: Colors.white, size: 22),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(bottom: 14, left: 56),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Fil d'actualité",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Dernières nouvelles de la communauté',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────
          asyncPosts.when(
            data: (_) {
              final hasRealPosts = posts.isNotEmpty;

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.marginMobile,
                  AppSpacing.stackMd,
                  AppSpacing.marginMobile,
                  AppSpacing.stackLg * 2,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Section label ─────────────────────────
                    if (_mockFeed.isNotEmpty) ...{
                      _sectionLabel('À la une'),
                      const SizedBox(height: AppSpacing.stackSm),
                      ..._mockFeed.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _FeedCard(item: item),
                          )),
                      if (hasRealPosts) ...{
                        const SizedBox(height: AppSpacing.stackLg),
                        _sectionLabel('Publications récentes'),
                        const SizedBox(height: AppSpacing.stackSm),
                      },
                    },

                    // ── Real posts from DB ─────────────────────
                    if (hasRealPosts)
                      ...posts.map((post) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: PostCard(post: post),
                          )),

                    // ── Empty state ────────────────────────────
                    if (!hasRealPosts && _mockFeed.isEmpty)
                      _buildEmptyState(),
                  ]),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              child: _buildError(e is AppException
                  ? e.message
                  : 'Impossible de charger le fil d\'actualité.'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 80),
          Icon(PhosphorIcons.newspaperClipping,
              size: 64, color: AppColors.outlineVariant),
          SizedBox(height: AppSpacing.stackMd),
          Text(
            'Aucun post pour le moment.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Sois le premier à partager quelque chose !',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.stackLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(PhosphorIcons.cloudSlash,
                size: 64, color: AppColors.outlineVariant),
            const SizedBox(height: AppSpacing.stackMd),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FeedCard — StatefulWidget with like toggle + interactions
// ─────────────────────────────────────────────────────────────────────────────

class _FeedCard extends StatefulWidget {
  final _MockFeedItem item;
  const _FeedCard({required this.item});

  @override
  State<_FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<_FeedCard> {
  late bool _isLiked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _isLiked = false;
    _likeCount = widget.item.likes;
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
  }

  // ── Show full caption in a modal bottom sheet ────────────────────────────

  void _showFullCaption(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 6),
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Header with close
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Avatar mini
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: widget.item.avatarBg,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              widget.item.initials,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.item.name,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            Text(
                              widget.item.meta,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                color: Color(0xFF888888),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(PhosphorIcons.x, size: 18),
                          onPressed: () => Navigator.pop(ctx),
                          color: const Color(0xFF888888),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  // Scrollable text
                  Flexible(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.text ?? '',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              height: 1.7,
                              color: Color(0xFF333333),
                            ),
                          ),
                          if (widget.item.hashtags != null) ...{
                            const SizedBox(height: 16),
                            Text(
                              widget.item.hashtags!,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                          },
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.07),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          const SizedBox(height: 10),
          _buildBody(context),
          const SizedBox(height: 10),
          const Divider(height: 0.5, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 10),
          _buildInteractionBar(),
        ],
      ),
    );
  }

  // ── Shared Header ────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar (mock — pas de membre reel)
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: widget.item.avatarBg,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              widget.item.initials,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Name + meta
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    widget.item.name,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  if (widget.item.verified) ...{
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5EE),
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
                  },
                ],
              ),
              const SizedBox(height: 1),
              Text(
                widget.item.meta,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF888888),
                ),
              ),
            ],
          ),
        ),
        // Dots menu
        GestureDetector(
          onTap: () => _showPostOptions(context),
          child: const Icon(PhosphorIcons.dotsThree,
              size: 16, color: Color(0xFFBBBBBB)),
        ),
      ],
    );
  }

  void _showPostOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _OptionTile(
                  icon: PhosphorIcons.flag,
                  label: 'Signaler cette publication',
                  color: Colors.redAccent,
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Publication signalée. Merci.')),
                    );
                  },
                ),
                _OptionTile(
                  icon: PhosphorIcons.copy,
                  label: 'Copier le lien',
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lien copié dans le presse-papier.')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Body (type-specific) ─────────────────────────────────────────────────

  Widget _buildBody(BuildContext context) {
    switch (widget.item.type) {
      case 1:
        return _buildTextBody(context);
      case 2:
        return _buildImageBody();
      case 3:
        return _buildJobBody(context);
      case 4:
        return _buildEventBody(context);
      case 5:
        return _buildArticleBody();
      default:
        return _buildTextBody(context);
    }
  }

  // ── Type 1: Text post ────────────────────────────────────────────────────

  Widget _buildTextBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.item.text ?? '',
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.65,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _showFullCaption(context),
          child: const Text(
            'Lire la suite',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
        ),
        if (widget.item.hashtags != null) ...{
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Recherche : ${widget.item.hashtags}'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: Text(
              widget.item.hashtags!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ),
        },
      ],
    );
  }

  // ── Type 2: Image post ───────────────────────────────────────────────────

  Widget _buildImageBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Image placeholder
        GestureDetector(
          onTap: () {
            // Full-screen image placeholder — could be extended
          },
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF00674F), Color(0xFF004D3A)],
              ),
            ),
            child: const Center(
              child: Icon(PhosphorIcons.image,
                  size: 36, color: AppColors.secondary),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.item.text ?? '',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.4,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  // ── Type 3: Job offer post ───────────────────────────────────────────────

  Widget _buildJobBody(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F6F2),
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: AppColors.primary, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(PhosphorIcons.briefcase,
                  size: 16, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                'OFFRE D\'EMPLOI',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.item.jobTitle ?? '',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.item.jobCompany ?? '',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _jobTag(widget.item.jobTags1 ?? ''),
              const SizedBox(width: 6),
              _jobTag(widget.item.jobTags2 ?? ''),
              const Spacer(),
              // "Postuler" button
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Candidature pour ${widget.item.jobTitle}'),
                      action: SnackBarAction(
                        label: 'Annuler',
                        onPressed: () {},
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Postuler',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _jobTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5EE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }

  // ── Type 4: Event post ───────────────────────────────────────────────────

  Widget _buildEventBody(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.07),
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Event header image
          Stack(
            children: [
              Container(
                height: 90,
                width: double.infinity,
                color: widget.item.eventColor ?? AppColors.primary,
                child: Center(
                  child: Icon(
                    widget.item.eventIcon,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ),
              // Badge overlay
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.item.eventBadge ?? '',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Event body
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.item.eventTitle ?? '',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(PhosphorIcons.calendar,
                        size: 12, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.item.eventDate ?? '',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(PhosphorIcons.mapPin,
                        size: 12, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.item.eventLocation ?? '',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // "Je participe" button
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Inscription à l\'événement confirmée !'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary, width: 0.5),
                    ),
                    child: const Text(
                      'Je participe',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
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

  // ── Type 5: Article / culture post ───────────────────────────────────────

  Widget _buildArticleBody() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.07),
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thumbnail
          GestureDetector(
            onTap: () {
              // Full-screen article reading — could navigate to article
            },
            child: Stack(
              children: [
                Container(
                  height: 130,
                  width: double.infinity,
                  color: const Color(0xFF1A1A1A),
                  child: const Center(
                    child: Icon(PhosphorIcons.book,
                        size: 32, color: AppColors.secondary),
                  ),
                ),
                // Gradient overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 60,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x99000000)],
                      ),
                    ),
                  ),
                ),
                // Category badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.item.articleCategory ?? '',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.item.articleTitle ?? '',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.item.articleSummary ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                    color: Color(0xFF555555),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(PhosphorIcons.clock,
                        size: 11, color: Color(0xFF888888)),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.item.articleDuration} · Patrimoine Fulɓe',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF888888),
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

  // ── Shared Interaction Bar ───────────────────────────────────────────────

  Widget _buildInteractionBar() {
    return Row(
      children: [
        // Like button
        GestureDetector(
          onTap: _toggleLike,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isLiked ? PhosphorIcons.heartFill : PhosphorIcons.heart,
                size: 14,
                color: _isLiked ? Colors.redAccent : const Color(0xFF666666),
              ),
              if (_likeCount > 0) ...{
                const SizedBox(width: 4),
                Text(
                  '$_likeCount',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _isLiked ? Colors.redAccent : const Color(0xFF666666),
                  ),
                ),
              },
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Comment button
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Commentaires (à implémenter)'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(PhosphorIcons.chatCircle,
                  size: 14, color: Color(0xFF666666)),
              if (widget.item.comments > 0) ...{
                const SizedBox(width: 4),
                Text(
                  '${widget.item.comments}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF666666),
                  ),
                ),
              },
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Share button
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Partager (à implémenter)'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(PhosphorIcons.shareNetwork,
                  size: 14, color: Color(0xFF666666)),
              if (widget.item.shares > 0) ...{
                const SizedBox(width: 4),
                Text(
                  '${widget.item.shares}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF666666),
                  ),
                ),
              },
            ],
          ),
        ),
        const Spacer(),
        // Bookmark button
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Enregistré dans vos favoris'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          child: const Icon(PhosphorIcons.bookmarkSimple,
              size: 14, color: Color(0xFF666666)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _OptionTile — reusable bottom-sheet option row
// ─────────────────────────────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20, color: color ?? const Color(0xFF666666)),
      title: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: color ?? const Color(0xFF1A1A1A),
        ),
      ),
      onTap: onTap,
      dense: true,
    );
  }
}
