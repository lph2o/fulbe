import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/models/job.dart';
import '../../core/data/providers/data_providers.dart';
import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../../shared/widgets/fc_card.dart';
import '../../shared/widgets/fc_chip.dart';
import '../../shared/widgets/fc_search_bar.dart';
import '../../core/navigation/app_router.dart';

class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen> {
  int _selectedRole = 0;
  int _selectedCountry = 0;
  int _selectedDomain = 0;

  // ── Filter labels (UI) ──────────────────────────────────────────────────
  static const _roleFilters = [
    'Tous',
    'Full-time',
    'Internships',
    'Freelance',
  ];
  static const _countries = [
    'Tous les pays',
    'Sénégal',
    'France',
    'Guinée',
    'Mali',
    'Italie',
  ];
  static const _domains = [
    'Tous domaines',
    'Tech',
    'Santé',
    'Finance',
    'Agriculture',
    'Design',
  ];

  List<Job> _filter(List<Job> jobs) {
    var list = _selectedRole == 0
        ? jobs
        : jobs.where((j) => j.type == _roleFilters[_selectedRole]).toList();

    if (_selectedCountry != 0) {
      final countryToken = _countries[_selectedCountry].split(' ').first.toLowerCase();
      list = list
          .where((j) => j.location.toLowerCase().contains(countryToken))
          .toList();
    }

    if (_selectedDomain != 0) {
      final selectedDomain = _domains[_selectedDomain];
      list = list.where((j) => j.domain == selectedDomain).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final asyncJobs = ref.watch(jobsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(showBack: true),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.of(context)
              .pushNamed(AppRoutes.createJob);
          if (created == true && mounted) {
            ref.invalidate(jobsProvider);
          }
        },
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(PhosphorIcons.plus, size: 24),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                Text('Emplois',
                    style: AppTextStyles.headlineLg
                        .copyWith(color: AppColors.onSurface, fontSize: 28)),
                const SizedBox(height: 2),
                Text('Opportunités dans le réseau Peul mondial.',
                    style: AppTextStyles.bodyMd
                        .copyWith(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.stackMd),
                // Search
                const FcSearchBar(placeholder: 'Rechercher poste, entreprise...',
                    showFilterButton: true),
                const SizedBox(height: AppSpacing.stackMd),
                // Dual dropdowns
                Row(
                  children: [
                    Expanded(
                      child: _DropdownFilter(
                        label: _countries[_selectedCountry],
                        icon: PhosphorIcons.globe,
                        items: _countries,
                        onSelect: (i) => setState(() => _selectedCountry = i),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.stackSm),
                    Expanded(
                      child: _DropdownFilter(
                        label: _domains[_selectedDomain],
                        icon: PhosphorIcons.briefcase,
                        items: _domains,
                        onSelect: (i) => setState(() => _selectedDomain = i),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackMd),
              ],
            ),
          ),
          // Role filter chips
          FcChipRow(
            labels: _roleFilters,
            onSelectionChanged: (i) => setState(() => _selectedRole = i),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          // Job cards (Riverpod)
          Expanded(
            child: asyncJobs.when(
              data: (jobs) {
                final filtered = _filter(jobs);
                if (filtered.isEmpty) return const _EmptyState();
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(jobsProvider);
                    await ref.read(jobsProvider.future);
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(
                      left: AppSpacing.marginMobile,
                      right: AppSpacing.marginMobile,
                      bottom: 100,
                    ),
                    itemCount: filtered.length + 1,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.stackMd),
                    itemBuilder: (_, i) {
                      if (i == filtered.length) {
                        return const _LoadMoreButton();
                      }
                      return _JobCard(job: filtered[i]);
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.stackLg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(strokeWidth: 2.4),
                      SizedBox(height: AppSpacing.stackMd),
                      Text('Chargement des offres...',
                          style: TextStyle(color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
              error: (e, _) => _ErrorView(
                message: e is AppException
                    ? e.message
                    : 'Impossible de charger les offres d\'emploi.',
                onRetry: () => ref.invalidate(jobsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownFilter extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<String> items;
  final ValueChanged<int> onSelect;
  const _DropdownFilter(
      {required this.label,
      required this.icon,
      required this.items,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusXl)),
          ),
          builder: (_) => ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackLg),
            children: items
                .asMap()
                .entries
                .map((e) => ListTile(
                      title: Text(e.value,
                          style: AppTextStyles.bodyMd
                              .copyWith(color: AppColors.onSurface)),
                      onTap: () {
                        onSelect(e.key);
                        Navigator.pop(context);
                      },
                    ))
                .toList(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.outlineVariant, width: 0.8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.onSurface, fontWeight: FontWeight.w500)),
            ),
            const Icon(PhosphorIcons.caretDown,
                size: 16, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final Job job;
  const _JobCard({required this.job});

  Color get _badgeColor {
    switch (job.badgeType) {
      case 'alumni':
        return AppColors.primaryContainer;
      case 'partner':
        return AppColors.secondary;
      case 'student':
        return AppColors.tertiary;
      default:
        return AppColors.outline;
    }
  }

  Color get _badgeBgColor {
    switch (job.badgeType) {
      case 'alumni':
        return AppColors.primaryFixed.withValues(alpha: 0.6);
      case 'partner':
        return AppColors.secondaryContainer.withValues(alpha: 0.5);
      case 'student':
        return AppColors.tertiaryFixed.withValues(alpha: 0.6);
      default:
        return AppColors.surfaceContainerHigh;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company logo
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Center(
                  child: Text(
                    job.companyInitials ?? '??',
                    style: AppTextStyles.labelMd.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.title,
                        style: AppTextStyles.labelMd.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(job.company,
                        style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 13)),
                  ],
                ),
              ),
              if (job.badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _badgeBgColor,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(job.badge!,
                      style: AppTextStyles.labelSm
                          .copyWith(color: _badgeColor, fontSize: 10)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          Wrap(
            spacing: AppSpacing.stackSm,
            runSpacing: AppSpacing.stackSm,
            children: [
              _InfoTag(icon: PhosphorIcons.mapPin, label: job.location),
              _InfoTag(icon: PhosphorIcons.clock, label: job.type),
              _InfoTag(icon: PhosphorIcons.clock, label: job.postedAgo),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                textStyle: AppTextStyles.labelMd
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              child: const Text('Postuler →'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 3),
        Text(label,
            style: AppTextStyles.labelSm.copyWith(
                color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w400)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(PhosphorIcons.briefcase,
              size: 64, color: AppColors.outlineVariant),
          const SizedBox(height: AppSpacing.stackMd),
          Text('Aucune offre pour ce filtre.',
              style: AppTextStyles.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.stackLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(PhosphorIcons.cloudSlash,
                size: 56, color: AppColors.outlineVariant),
            const SizedBox(height: AppSpacing.stackMd),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd
                    .copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.stackMd),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(PhosphorIcons.arrowsClockwise, size: 18),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  const _LoadMoreButton();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryContainer,
        side: const BorderSide(color: AppColors.primaryContainer, width: 1.2),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
        minimumSize: const Size(double.infinity, 0),
      ),
      child: const Text('Voir plus d\'opportunités'),
    );
  }
}
