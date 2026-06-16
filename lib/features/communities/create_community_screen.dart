// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers/data_providers.dart';
import '../../core/theme/app_colors.dart';

/// Écran de création d'une communauté.
class CreateCommunityScreen extends ConsumerStatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  ConsumerState<CreateCommunityScreen> createState() =>
      _CreateCommunityScreenState();
}

class _CreateCommunityScreenState
    extends ConsumerState<CreateCommunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'Tech';
  bool _isPrivate = false;
  bool _isSubmitting = false;

  static const _categories = [
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
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final member = await ref.read(currentMemberProvider.future);
    if (member == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vous devez être connecté.')),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(communitiesRepositoryProvider);
      await repo.create(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _category,
        visibility: _isPrivate ? 'private' : 'public',
        createdBy: member.id,
      );

      if (mounted) {
        ref.invalidate(communitiesProvider);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIcons.x,
              color: AppColors.onSurfaceVariant, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Nouvelle communauté',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              height: 34,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Créer',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nom
              Text(
                'Nom du groupe',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameCtrl,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requis' : null,
                style: TextStyle(fontSize: 15, color: AppColors.onSurface),
                decoration: InputDecoration(
                  hintText: 'Ex: Tech Fulɓe Cameroon',
                  hintStyle: TextStyle(
                      fontSize: 15, color: AppColors.outlineVariant),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: AppColors.outlineVariant, width: 0.5),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),

              // Description
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requis' : null,
                style: TextStyle(fontSize: 15, color: AppColors.onSurface),
                decoration: InputDecoration(
                  hintText: 'Décrivez le groupe...',
                  hintStyle: TextStyle(
                      fontSize: 15, color: AppColors.outlineVariant),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: AppColors.outlineVariant, width: 0.5),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),

              // Catégorie
              Text(
                'Catégorie',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final selected = cat == _category;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: selected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? Colors.white : AppColors.onSurfaceVariant,
                    ),
                    side: BorderSide(
                      color: selected
                          ? AppColors.primary
                          : AppColors.outlineVariant,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    onSelected: (_) => setState(() => _category = cat),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Visibilité
              Text(
                'Visibilité',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.outlineVariant, width: 0.5),
                ),
                child: Column(
                  children: [
                    RadioListTile<bool>(
                      title: Row(
                        children: [
                          Icon(PhosphorIcons.globe,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Text(
                            'Public',
                            style: TextStyle(
                                fontSize: 14,
                                color: AppColors.onSurface),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        'Visible par tout le monde',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant),
                      ),
                      value: false,
                      groupValue: _isPrivate,
                      activeColor: AppColors.primary,
                      onChanged: (v) =>
                          setState(() => _isPrivate = v ?? false),
                    ),
                    Divider(
                        height: 1, color: AppColors.outlineVariant),
                    RadioListTile<bool>(
                      title: Row(
                        children: [
                          Icon(PhosphorIcons.lock,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Text(
                            'Privé',
                            style: TextStyle(
                                fontSize: 14,
                                color: AppColors.onSurface),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        'Accès sur demande ou invitation',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant),
                      ),
                      value: true,
                      groupValue: _isPrivate,
                      activeColor: AppColors.primary,
                      onChanged: (v) =>
                          setState(() => _isPrivate = v ?? false),
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
}
