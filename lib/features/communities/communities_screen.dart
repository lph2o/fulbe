// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/models/community.dart';
import '../../core/data/providers/data_providers.dart';
import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/navigation/app_router.dart';

/// Écran catalogue des communautés.
///
/// Affiche les groupes disponibles avec recherche et filtre par catégorie.
class CommunitiesScreen extends ConsumerStatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  ConsumerState<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends ConsumerState<CommunitiesScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';
  String? _selectedCategory;
  bool _showSearch = false;
  String _sortBy = 'popularity'; // 'popularity' | 'recent'

  static const _categories = [
    'Tout',
    'Tech',
    'Agriculture',
    'Culture',
    'Santé',
    'Finance',
    'Éducation',
    'Sport',
    'Projet',
    'Région',
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<Community> _sort(List<Community> source) {
    final sorted = List<Community>.from(source);
    if (_sortBy == 'popularity') {
      sorted.sort((a, b) => b.memberCount.compareTo(a.memberCount));
    } else {
      sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return sorted;
  }

  List<Community> _filter(List<Community> source) {
    var result = source;
    if (_selectedCategory != null && _selectedCategory != 'Tout') {
      result = result
          .where((c) => c.category.toLowerCase() == _selectedCategory!.toLowerCase())
          .toList();
    }
    if (_query.isNotEmpty) {
      result = result
          .where((c) =>
              c.name.toLowerCase().contains(_query) ||
              c.description.toLowerCase().contains(_query))
          .toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final asyncCommunities = ref.watch(communitiesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildCategories(),
          _buildSortBar(),
          Expanded(
            child: asyncCommunities.when(
              data: (communities) {
                final sorted = _sort(communities);
                final filtered = _filter(sorted);
                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 8,
                    bottom: AppSpacing.bottomNavHeight + 80,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) =>
                      _CommunityCard(community: filtered[i]),
                );
              },
              loading: () => Center(
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.stackLg),
                  child: Text(
                    e is AppException
                        ? e.message
                        : 'Impossible de charger les communautés.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMd
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: Container(
        color: AppColors.surface,
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  if (_showSearch) ...[
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        focusNode: _searchFocus,
                        autofocus: true,
                        style: const TextStyle(
                            fontSize: 16, color: AppColors.onSurface),
                        decoration: const InputDecoration(
                          hintText: 'Rechercher...',
                          hintStyle: TextStyle(
                              color: AppColors.outlineVariant,
                              fontSize: 16),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(PhosphorIcons.x,
                          color: AppColors.onSurfaceVariant, size: 20),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _showSearch = false);
                      },
                    ),
                  ] else ...[
                    if (Navigator.of(context).canPop())
                      IconButton(
                        icon: Icon(PhosphorIcons.arrowLeft,
                            color: AppColors.onSurfaceVariant, size: 22),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        PhosphorIcons.usersThree,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Communautés',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      icon: Icon(
                        _sortBy == 'popularity'
                            ? PhosphorIcons.funnel
                            : PhosphorIcons.clockCounterClockwise,
                        color: AppColors.onSurfaceVariant,
                        size: 20,
                      ),
                      tooltip: 'Trier par',
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: AppColors.surface,
                      onSelected: (value) {
                        if (value != _sortBy) {
                          setState(() => _sortBy = value);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'popularity',
                          child: Row(
                            children: [
                              Icon(
                                _sortBy == 'popularity'
                                    ? PhosphorIcons.funnelFill
                                    : PhosphorIcons.funnel,
                                size: 18,
                                color: _sortBy == 'popularity'
                                    ? AppColors.primary
                                    : AppColors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Popularité',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      _sortBy == 'popularity'
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                  color: _sortBy == 'popularity'
                                      ? AppColors.primary
                                      : AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'recent',
                          child: Row(
                            children: [
                              Icon(
                                _sortBy == 'recent'
                                    ? PhosphorIcons.clockCounterClockwiseFill
                                    : PhosphorIcons.clockCounterClockwise,
                                size: 18,
                                color: _sortBy == 'recent'
                                    ? AppColors.primary
                                    : AppColors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Récents',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      _sortBy == 'recent'
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                  color: _sortBy == 'recent'
                                      ? AppColors.primary
                                      : AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: Icon(PhosphorIcons.qrCode,
                          color: AppColors.onSurfaceVariant, size: 20),
                      tooltip: 'Rejoindre par code',
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: AppColors.surface,
                      onSelected: (value) {
                        if (value == 'join_by_code') {
                          _showJoinByCodeDialog();
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'join_by_code',
                          child: Row(
                            children: [
                              Icon(PhosphorIcons.qrCode,
                                  size: 18, color: AppColors.primary),
                              SizedBox(width: 10),
                              Text('Rejoindre par code'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(PhosphorIcons.magnifyingGlass,
                          color: AppColors.onSurfaceVariant, size: 20),
                      onPressed: () =>
                          setState(() => _showSearch = true),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showJoinByCodeDialog() async {
    final codeCtrl = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rejoindre par code',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Saisis le code d\'invitation reçu pour rejoindre un groupe.',
              style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.none,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                letterSpacing: 3,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Code 12 caractères',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: AppColors.outlineVariant,
                  fontFamily: 'monospace',
                ),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.outlineVariant),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, codeCtrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rejoindre'),
          ),
        ],
      ),
    );
    codeCtrl.dispose();

    if (code == null || code.isEmpty) return;

    try {
      final repo = ref.read(communitiesRepositoryProvider);
      final communityId = await repo.joinByInviteCode(code);
      if (mounted) {
        ref.invalidate(communitiesProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tu as rejoint le groupe !'),
            duration: Duration(seconds: 3),
          ),
        );
        // Navigue vers le détail du groupe
        Navigator.of(context).pushNamed(
          AppRoutes.communityDetail,
          arguments: communityId,
        );
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString();
        String userMessage;
        if (message.contains('NOT_AUTHENTICATED')) {
          userMessage = 'Tu dois être connecté pour rejoindre un groupe.';
        } else if (message.contains('INVALID_CODE')) {
          userMessage = 'Ce code d\'invitation est invalide.';
        } else if (message.contains('ALREADY_MEMBER')) {
          userMessage = 'Tu es déjà membre de ce groupe.';
        } else {
          userMessage = 'Impossible de rejoindre le groupe.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userMessage)),
        );
      }
    }
  }

  Widget _buildSortBar() {
    if (_sortBy == 'popularity') return const SizedBox.shrink();
    return Container(
      height: 32,
      margin: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(PhosphorIcons.clockCounterClockwise,
              size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            'Trié par date de création',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: _categories.map((cat) {
          final isSelected =
              cat == (_selectedCategory ?? 'Tout');
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                cat,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : AppColors.onSurfaceVariant,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.outlineVariant,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              onSelected: (_) {
                setState(() => _selectedCategory =
                    cat == 'Tout' ? null : cat);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _query.isNotEmpty || _selectedCategory != null
                ? PhosphorIcons.magnifyingGlass
                : PhosphorIcons.usersThree,
            size: 48,
            color: AppColors.outlineVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'Aucune communauté pour le moment.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Community Card ────────────────────────────────────────────────────────

class _CommunityCard extends StatelessWidget {
  final Community community;
  const _CommunityCard({required this.community});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.outlineVariant, width: 0.5),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            AppRoutes.communityDetail,
            arguments: community.id,
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar / couverture
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _categoryColor(community.category),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _categoryIcon(community.category),
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            community.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                        if (community.isMember)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryFixed,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Membre',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      community.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(PhosphorIcons.user,
                            size: 14, color: AppColors.outline),
                        const SizedBox(width: 4),
                        Text(
                          '${community.memberCount} membre${community.memberCount > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.outline,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(PhosphorIcons.tag,
                            size: 14, color: AppColors.outline),
                        const SizedBox(width: 4),
                        Text(
                          community.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.outline,
                          ),
                        ),
                        if (community.isPrivate) ...[
                          const SizedBox(width: 12),
                          Icon(PhosphorIcons.lock,
                              size: 14, color: AppColors.outline),
                          const SizedBox(width: 4),
                          Text(
                            'Privé',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.outline,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'tech':
        return AppColors.tertiary;
      case 'agriculture':
        return const Color(0xFF16A34A);
      case 'culture':
        return AppColors.purple;
      case 'santé':
      case 'sante':
        return const Color(0xFFDC2626);
      case 'finance':
        return const Color(0xFFE8A838);
      case 'éducation':
      case 'education':
        return AppColors.teal;
      case 'sport':
        return const Color(0xFFF97316);
      default:
        return AppColors.primary;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'tech':
        return PhosphorIcons.code;
      case 'agriculture':
        return PhosphorIcons.plant;
      case 'culture':
        return PhosphorIcons.palette;
      case 'santé':
      case 'sante':
        return PhosphorIcons.heart;
      case 'finance':
        return PhosphorIcons.coin;
      case 'éducation':
      case 'education':
        return PhosphorIcons.bookOpen;
      case 'sport':
        return PhosphorIcons.barbell;
      case 'projet':
        return PhosphorIcons.rocket;
      case 'région':
      case 'region':
        return PhosphorIcons.mapPin;
      default:
        return PhosphorIcons.usersThree;
    }
  }
}
