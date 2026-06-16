import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/auth/auth_service.dart';
import '../../core/data/providers/data_providers.dart';
import '../../core/errors/app_exception.dart';
import '../../core/logging/app_logger.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EditProfileScreen — Premium edit form
// ─────────────────────────────────────────────────────────────────────────────

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late TextEditingController _nameCtrl;
  late TextEditingController _professionCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _countryCtrl;
  late TextEditingController _linkedInCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _skillCtrl;
  late List<String> _skills;
  File? _avatarImage;
  File? _coverImage;
  bool _coverRemoved = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final suUser = auth.currentUser;
    final name = suUser?.userMetadata?['full_name'] as String? ??
        suUser?.email?.split('@').first ??
        '';
    _nameCtrl = TextEditingController(text: name);
    _professionCtrl = TextEditingController(
      text: suUser?.userMetadata?['profession'] as String? ?? '',
    );
    _cityCtrl = TextEditingController(
      text: suUser?.userMetadata?['city'] as String? ?? '',
    );
    _countryCtrl = TextEditingController(
      text: suUser?.userMetadata?['country'] as String? ?? '',
    );
    _linkedInCtrl = TextEditingController(
      text: suUser?.userMetadata?['linkedin'] as String? ?? '',
    );
    _bioCtrl = TextEditingController(
      text: suUser?.userMetadata?['bio'] as String? ?? '',
    );
    _skillCtrl = TextEditingController();
    _skills = List<String>.from(
      suUser?.userMetadata?['skills'] as List? ?? ['Réseautage', 'Solidarité'],
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _professionCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    _linkedInCtrl.dispose();
    _bioCtrl.dispose();
    _skillCtrl.dispose();
    super.dispose();
  }

  void _addSkill() {
    final text = _skillCtrl.text.trim();
    if (text.isNotEmpty && !_skills.contains(text)) {
      setState(() => _skills.add(text));
      _skillCtrl.clear();
    }
  }

  void _removeSkill(String skill) {
    setState(() => _skills.remove(skill));
  }

  Future<void> _pickAvatarFromGallery() async {
    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (xFile != null && mounted) {
        setState(() => _avatarImage = File(xFile.path));
      }
    } catch (e) {
      _showPickerError(e);
    }
  }

  Future<void> _pickCoverFromGallery() async {
    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (xFile != null && mounted) {
        setState(() => _coverImage = File(xFile.path));
      }
    } catch (e) {
      _showPickerError(e);
    }
  }

  Future<void> _pickCoverFromCamera() async {
    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (xFile != null && mounted) {
        setState(() => _coverImage = File(xFile.path));
      }
    } catch (e) {
      _showPickerError(e);
    }
  }

  void _showCoverSourceSheet() {
    final hasExistingCover =
        (auth.currentUser?.userMetadata?['cover_url'] as String?)
                ?.isNotEmpty ==
            true;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Photo de couverture',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryFixed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(PhosphorIcons.images,
                      color: AppColors.secondary, size: 24),
                ),
                title: const Text('Galerie',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface)),
                subtitle: const Text('Choisir une image',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant)),
                onTap: () {
                  Navigator.pop(context);
                  _pickCoverFromGallery();
                },
              ),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(PhosphorIcons.camera,
                      color: AppColors.primary, size: 24),
                ),
                title: const Text('Appareil photo',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface)),
                subtitle: const Text('Prendre une photo',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant)),
                onTap: () {
                  Navigator.pop(context);
                  _pickCoverFromCamera();
                },
              ),
              if (_coverImage != null || hasExistingCover)
                ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(PhosphorIcons.trash,
                        color: AppColors.error, size: 24),
                  ),
                  title: const Text('Supprimer la couverture',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _coverImage = null;
                      _coverRemoved = hasExistingCover;
                    });
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAvatarFromCamera() async {
    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (xFile != null && mounted) {
        setState(() => _avatarImage = File(xFile.path));
      }
    } catch (e) {
      _showPickerError(e);
    }
  }

  void _showAvatarSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Photo de profil',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(PhosphorIcons.images, color: AppColors.primary, size: 24),
                ),
                title: const Text(
                  'Galerie',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                subtitle: const Text(
                  'Choisir une image',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickAvatarFromGallery();
                },
              ),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryFixed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(PhosphorIcons.camera, color: AppColors.secondary, size: 24),
                ),
                title: const Text(
                  'Appareil photo',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                subtitle: const Text(
                  'Prendre une photo',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickAvatarFromCamera();
                },
              ),
              if (_avatarImage != null)
                ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(PhosphorIcons.trash, color: AppColors.error, size: 24),
                  ),
                  title: const Text(
                    'Supprimer la photo',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _avatarImage = null);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showPickerError(Object e) {
    if (!mounted) return;
    final errMsg = e.toString();
    final shortMsg = errMsg.split('\n').first;
    final isPermission = shortMsg.contains('permission') ||
        shortMsg.contains('Permission') ||
        shortMsg.contains('denied');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isPermission
              ? 'Permission refusée. Activez l\'accès à la caméra/galerie dans les réglages.'
              : 'Erreur : ${shortMsg.length > 80 ? '${e.runtimeType}' : shortMsg}',
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final user = auth.currentUser;
      if (user == null) throw const AuthException('Utilisateur non connecté.');

      // Upload avatar si une nouvelle image a été sélectionnée
      String? avatarUrl;
      if (_avatarImage != null) {
        avatarUrl = await ref.read(membersRepositoryProvider).updateAvatar(_avatarImage!);
      }

      // Upload cover si une nouvelle image a été sélectionnée
      String? coverUrl;
      if (_coverRemoved) {
        // Supprimer l'ancienne cover du storage
        try {
          final currentUrl =
              user.userMetadata?['cover_url'] as String?;
          if (currentUrl != null && currentUrl.isNotEmpty) {
            final uri = Uri.parse(currentUrl);
            final bucketIdx = uri.pathSegments.indexOf('covers');
            if (bucketIdx != -1 && bucketIdx + 1 < uri.pathSegments.length) {
              final fileName =
                  uri.pathSegments.sublist(bucketIdx + 1).join('/');
              await sb.Supabase.instance.client.storage
                  .from('covers')
                  .remove([fileName]);
            }
          }
        } catch (_) {
          // Silencieux
        }
        // coverUrl reste null → on va syncer null
      } else if (_coverImage != null) {
        coverUrl = await ref
            .read(membersRepositoryProvider)
            .updateCover(_coverImage!);
      }

      // Update user metadata via Supabase Auth
      final userData = <String, dynamic>{
        'full_name': _nameCtrl.text.trim(),
        'profession': _professionCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'country': _countryCtrl.text.trim(),
        'linkedin': _linkedInCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'skills': _skills,
      };
      if (avatarUrl != null) {
        userData['avatar_url'] = avatarUrl;
      }
      if (coverUrl != null) {
        userData['cover_url'] = coverUrl;
      } else if (_coverRemoved) {
        userData['cover_url'] = null;
      }

      await sb.Supabase.instance.client.auth.updateUser(
        sb.UserAttributes(data: userData),
      );

      // Synchroniser les champs vers la table members
      // (auth metadata est la source pour le trigger de création, mais les
      // updates doivent être poussées explicitement vers members).
      try {
        final data = await sb.Supabase.instance.client
            .from('members')
            .select('id')
            .eq('user_id', user.id)
            .limit(1);
        final rows = data as List<dynamic>;
        if (rows.isNotEmpty) {
          final memberId = (rows.first as Map<String, dynamic>)['id'] as String;
          await sb.Supabase.instance.client.from('members').update({
            'full_name': _nameCtrl.text.trim(),
            'profession': _professionCtrl.text.trim(),
            'city': _cityCtrl.text.trim(),
            'country': _countryCtrl.text.trim(),
            'linkedin': _linkedInCtrl.text.trim(),
            'bio': _bioCtrl.text.trim(),
            if (avatarUrl != null) 'avatar_url': avatarUrl,
            if (coverUrl != null) 'cover_url': coverUrl,
            if (_coverRemoved) 'cover_url': null,
          }).eq('id', memberId);
        }
      } catch (e) {
        log.warn('Failed to sync members table', tag: 'profile', error: e);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour avec succès !'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      ref.invalidate(currentMemberProvider);
      Navigator.of(context).pop();
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour : $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── AppBar ──────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 100,
            backgroundColor: AppColors.primary,
            leading: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: IconButton(
                icon: const Icon(PhosphorIcons.arrowLeft,
                    color: Colors.white, size: 22),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(bottom: 14, left: 56),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Modifier le profil',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Mettez à jour vos informations',
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

          // ── Form ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.marginMobile,
                AppSpacing.stackLg,
                AppSpacing.marginMobile,
                AppSpacing.bottomNavHeight + AppSpacing.stackLg,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Cover ──────────────────────────────────
                    _buildCoverSection(),
                    const SizedBox(height: AppSpacing.stackLg),

                    // ── Avatar ──────────────────────────────────
                    _buildAvatarSection(),
                    const SizedBox(height: AppSpacing.stackLg),

                    // ── Name ────────────────────────────────────
                    _buildLabel('Nom complet'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _nameCtrl,
                      icon: PhosphorIcons.user,
                      hint: 'Votre nom',
                      validator: (v) =>
                          v?.trim().isEmpty ?? true ? 'Requis' : null,
                    ),
                    const SizedBox(height: AppSpacing.stackMd),

                    // ── Profession ──────────────────────────────
                    _buildLabel('Profession'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _professionCtrl,
                      icon: PhosphorIcons.briefcase,
                      hint: 'Développeur Full Stack, Designer...',
                    ),
                    const SizedBox(height: AppSpacing.stackMd),

                    // ── City ────────────────────────────────────
                    _buildLabel('Ville'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _cityCtrl,
                      icon: PhosphorIcons.mapPin,
                      hint: 'Dakar, Paris, Milan...',
                    ),
                    const SizedBox(height: AppSpacing.stackMd),

                    // ── Country ─────────────────────────────────
                    _buildLabel('Pays'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _countryCtrl,
                      icon: PhosphorIcons.globe,
                      hint: 'Sénégal, France, Italie...',
                    ),
                    const SizedBox(height: AppSpacing.stackMd),

                    // ── LinkedIn ────────────────────────────────
                    _buildLabel('LinkedIn (optionnel)'),
                    const SizedBox(height: 6),
                    _buildTextField(
                      controller: _linkedInCtrl,
                      icon: PhosphorIcons.link,
                      hint: 'linkedin.com/in/votreprofil',
                    ),
                    const SizedBox(height: AppSpacing.stackMd),

                    // ── Bio ─────────────────────────────────────
                    _buildLabel('Bio / À propos'),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.black.withValues(alpha: 0.08),
                            width: 0.5),
                      ),
                      child: TextFormField(
                        controller: _bioCtrl,
                        maxLines: 4,
                        maxLength: 500,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: Color(0xFF1A1A1A),
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Parlez de vous...',
                          hintStyle: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: Color(0xFFBBBBBB),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(14),
                          counterStyle: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            color: Color(0xFFBBBBBB),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackMd),

                    // ── Skills ──────────────────────────────────
                    _buildLabel('Compétences'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.black.withValues(alpha: 0.08),
                            width: 0.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Current skills as chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ..._skills.map((s) => Chip(
                                    label: Text(s,
                                        style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600)),
                                    deleteIcon: const Icon(
                                        PhosphorIcons.xCircle,
                                        size: 14),
                                    onDeleted: () => _removeSkill(s),
                                    backgroundColor: const Color(0xFFE8F5EE),
                                    side: BorderSide.none,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  )),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Add skill row
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 36,
                                  child: TextField(
                                    controller: _skillCtrl,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Ajouter une compétence...',
                                      hintStyle: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        color: Color(0xFFBBBBBB),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        borderSide: BorderSide(
                                          color: Colors.black
                                              .withValues(alpha: 0.08),
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 8),
                                      isDense: true,
                                    ),
                                    onSubmitted: (_) => _addSkill(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 36,
                                height: 36,
                                child: Material(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(18),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: _addSkill,
                                    child: const Center(
                                      child: Icon(PhosphorIcons.plus,
                                          size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackLg + 8),

                    // ── Save Button ────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          disabledBackgroundColor:
                              AppColors.primary.withValues(alpha: 0.5),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Enregistrer les modifications',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackSm),

                    // ── Cancel Button ──────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Annuler',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Cover section ────────────────────────────────────────────────────────

  Widget _buildCoverSection() {
    final suUser = auth.currentUser;
    final currentCoverUrl = suUser?.userMetadata?['cover_url'] as String?;
    final hasExistingCover =
        currentCoverUrl != null && currentCoverUrl.isNotEmpty;

    return GestureDetector(
      onTap: _showCoverSourceSheet,
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background: image or gradient fallback
            if (_coverRemoved)
              _buildCoverPlaceholder()
            else if (_coverImage != null)
              Image.file(
                _coverImage!,
                fit: BoxFit.cover,
              )
            else if (hasExistingCover)
              Image.network(
                currentCoverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildCoverPlaceholder(),
              )
            else
              _buildCoverPlaceholder(),

            // Overlay gradient pour lisibilité du texte blanc éventuel
            if (!_coverRemoved)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),

            // Cover removed overlay
            if (_coverRemoved)
              Container(
                color: Colors.black.withValues(alpha: 0.35),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(PhosphorIcons.trash,
                          size: 28, color: Colors.white70),
                      const SizedBox(height: 6),
                      Text(
                        'Couverture supprimée à l\'enregistrement',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Edit button
            if (!_coverRemoved)
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIcons.camera,
                          size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Modifier la couverture',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Undo remove button (when cover is marked for removal)
            if (_coverRemoved)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(PhosphorIcons.arrowCounterClockwise,
                        size: 14, color: Colors.white),
                    onPressed: () =>
                        setState(() => _coverRemoved = false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ),

            // Remove button (only when a new image is selected)
            if (_coverImage != null && !_coverRemoved)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(PhosphorIcons.x,
                        size: 14, color: Colors.white),
                    onPressed: () => setState(() => _coverImage = null),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      color: AppColors.primary,
      child: Center(
        child: Icon(PhosphorIcons.image,
            size: 40, color: Colors.white.withValues(alpha: 0.3)),
      ),
    );
  }

  // ── Avatar section ────────────────────────────────────────────────────────

  Widget _buildAvatarSection() {
    final suUser = auth.currentUser;
    final avatarUrl = _avatarImage != null
        ? null // Show local file instead
        : suUser?.userMetadata?['avatar_url'] as String? ??
            'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=150&h=150&fit=crop&q=80';

    return Center(
      child: Stack(
        children: [
          GestureDetector(
            onTap: _showAvatarSourceSheet,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _avatarImage != null
                  ? ClipOval(
                      child: Image.file(
                        _avatarImage!,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                      ),
                    )
                  : CircleAvatar(
                      radius: 46,
                      backgroundImage: NetworkImage(avatarUrl!),
                    ),
            ),
          ),
          // Camera button overlay
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(PhosphorIcons.camera,
                    size: 14, color: Colors.white),
                onPressed: _showAvatarSourceSheet,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ),
          // Remove button (only when a new image is selected)
          if (_avatarImage != null)
            Positioned(
              top: 0,
              right: -4,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(PhosphorIcons.x, size: 12, color: Colors.white),
                  onPressed: () => setState(() => _avatarImage = null),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Label ─────────────────────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A1A),
      ),
    );
  }

  // ── Text field ────────────────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Colors.black.withValues(alpha: 0.08), width: 0.5),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: Color(0xFF1A1A1A),
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 16, color: const Color(0xFF888888)),
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: Color(0xFFBBBBBB),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}
