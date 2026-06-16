// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/models/community.dart';
import '../../core/data/providers/data_providers.dart';
import '../../core/theme/app_colors.dart';

/// Écran de paramètres de la communauté.
///
/// Accessible uniquement aux admins. Permet de modifier le nom, la
/// description, la visibilité, ou de supprimer la communauté.
class CommunitySettingsScreen extends ConsumerStatefulWidget {
  final Community community;

  const CommunitySettingsScreen({super.key, required this.community});

  @override
  ConsumerState<CommunitySettingsScreen> createState() =>
      _CommunitySettingsScreenState();
}

class _CommunitySettingsScreenState
    extends ConsumerState<CommunitySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late String _visibility;
  late bool _isSaving;

  @override
  void initState() {
    super.initState();
    final c = widget.community;
    _nameCtrl = TextEditingController(text: c.name);
    _descCtrl = TextEditingController(text: c.description);
    _visibility = c.visibility;
    _isSaving = false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(communitiesRepositoryProvider);
      await repo.update(
        id: widget.community.id,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        visibility: _visibility,
      );

      if (mounted) {
        ref.invalidate(communityProvider(widget.community.id));
        ref.invalidate(communitiesProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Modifications enregistrées.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Supprimer cette communauté ?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Tous les posts et les adhésions seront supprimés. Cette action est irréversible.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final repo = ref.read(communitiesRepositoryProvider);
        await repo.delete(widget.community.id);

        if (mounted) {
          ref.invalidate(communitiesProvider);
          // Pop back to communities list (pop detail + settings)
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur : ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.community;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft,
              color: AppColors.onSurfaceVariant, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Paramètres',
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
                onPressed: _isSaving ? null : _save,
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
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Sauvegarder',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom
                _sectionLabel('Nom du groupe'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameCtrl,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requis' : null,
                  style: const TextStyle(
                      fontSize: 15, color: AppColors.onSurface),
                  decoration: _inputDecoration('Nom de la communauté'),
                ),
                const SizedBox(height: 20),

                // Description
                _sectionLabel('Description'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 4,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requis' : null,
                  style: const TextStyle(
                      fontSize: 15, color: AppColors.onSurface),
                  decoration: _inputDecoration('Description du groupe'),
                ),
                const SizedBox(height: 20),

                // Visibilité
                _sectionLabel('Visibilité'),
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
                      RadioListTile<String>(
                        title: Row(
                          children: [
                            const Icon(PhosphorIcons.globe,
                                size: 18, color: AppColors.primary),
                            const SizedBox(width: 10),
                            const Text('Public',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.onSurface)),
                          ],
                        ),
                        subtitle: const Text('Visible par tout le monde',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant)),
                        value: 'public',
                        groupValue: _visibility,
                        activeColor: AppColors.primary,
                        onChanged: (v) {
                          if (v != null) setState(() => _visibility = v);
                        },
                      ),
                      const Divider(height: 1, color: AppColors.outlineVariant),
                      RadioListTile<String>(
                        title: Row(
                          children: [
                            const Icon(PhosphorIcons.lock,
                                size: 18, color: AppColors.primary),
                            const SizedBox(width: 10),
                            const Text('Privé',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.onSurface)),
                          ],
                        ),
                        subtitle: const Text('Accès sur demande ou invitation',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant)),
                        value: 'private',
                        groupValue: _visibility,
                        activeColor: AppColors.primary,
                        onChanged: (v) {
                          if (v != null) setState(() => _visibility = v);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Zone de danger ──────────────────────────────────────────────
          const Divider(color: AppColors.outlineVariant),
          const SizedBox(height: 16),
          const Text(
            'Zone de danger',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Supprimer la communauté efface tous les posts et adhésions. '
            'Cette action est irréversible.',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _confirmDelete,
              icon: const Icon(PhosphorIcons.trash, size: 18),
              label: const Text('Supprimer cette communauté'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurfaceVariant,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          const TextStyle(fontSize: 15, color: AppColors.outlineVariant),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: AppColors.outlineVariant, width: 0.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
