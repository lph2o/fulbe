import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/data/mock_jobs.dart';
import '../../shared/widgets/fc_card.dart';
import '../../shared/widgets/fc_chip.dart';
import '../../shared/widgets/fc_search_bar.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  int _selectedRole = 0;
  int _selectedCountry = 0;
  int _selectedDomain = 0;

  List<Job> get _filtered {
    if (_selectedRole == 0) return MockJobs.all;
    final role = MockJobs.roleFilters[_selectedRole];
    return MockJobs.all.where((j) => j.type == role).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.95),
        elevation: 0.5,
        centerTitle: true,
        leading: const Padding(
          padding: EdgeInsets.only(left: AppSpacing.marginMobile),
          child: CircleAvatar(
            backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=150&h=150&fit=crop&q=80'),
            radius: 20,
          ),
        ),
        title: Text('Fulɓe Connect',
            style: AppTextStyles.headlineLgMobile
                .copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: AppColors.onSurfaceVariant),
            onPressed: () {},
            padding: const EdgeInsets.only(right: AppSpacing.marginMobile),
          ),
        ],
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
                        label: MockJobs.countries[_selectedCountry],
                        icon: Icons.public,
                        items: MockJobs.countries,
                        onSelect: (i) => setState(() => _selectedCountry = i),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.stackSm),
                    Expanded(
                      child: _DropdownFilter(
                        label: MockJobs.domains[_selectedDomain],
                        icon: Icons.work_outline,
                        items: MockJobs.domains,
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
            labels: MockJobs.roleFilters,
            onSelectionChanged: (i) => setState(() => _selectedRole = i),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          // Job cards
          Expanded(
            child: _filtered.isEmpty
                ? _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.marginMobile,
                      right: AppSpacing.marginMobile,
                      bottom: 100,
                    ),
                    itemCount: _filtered.length + 1,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.stackMd),
                    itemBuilder: (_, i) {
                      if (i == _filtered.length) {
                        return _LoadMoreButton();
                      }
                      return _JobCard(job: _filtered[i]);
                    },
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
            const Icon(Icons.expand_more,
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
              _InfoTag(icon: Icons.location_on_outlined, label: job.location),
              _InfoTag(icon: Icons.access_time, label: job.type),
              _InfoTag(icon: Icons.schedule, label: job.postedAgo),
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
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.work_off_outlined,
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

class _LoadMoreButton extends StatelessWidget {
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
