import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
// On masque `AuthException` de gotrue car on utilise notre propre hiérarchie
// d'exceptions (voir `core/errors/app_exception.dart`), exposée via AuthService.

import '../../core/auth/auth_service.dart';
import '../../core/data/countries.dart';
import '../../core/errors/app_exception.dart';
import '../../core/services/location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  // Text Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Localisation (pays + ville en cascade)
  String? _selectedCountry;
  String? _selectedCity;

  // Localisation GPS
  final _locationService = const LocationService();
  bool _isLocating = false;
  String? _locationHint;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _showEmailConfirmation = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _errorMessage = null;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int && args >= 0 && args < 2) {
      _tabController.index = args;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) {
        // Pop back to AuthGate, which will trigger navigation to MainShell
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on AppException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        city: _selectedCity ?? '',
        country: _selectedCountry ?? '',
      );

      if (!mounted) return;

      if (response.session != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inscription réussie ! Connexion automatique...'),
            backgroundColor: AppColors.primaryContainer,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        setState(() => _showEmailConfirmation = true);
      }
    } on AppException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Ramène l'utilisateur à l'écran de connexion après avoir cliqué
  /// sur le lien de confirmation dans son email.
  void _goToLogin() {
    setState(() {
      _showEmailConfirmation = false;
      _tabController.index = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIcons.arrowLeft, color: AppColors.onPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Background dot grid
          Positioned.fill(
            child: CustomPaint(painter: _GridPatternPainter()),
          ),
          // Scrollable Container for inputs
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header logo
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.secondaryContainer.withValues(alpha: 0.12),
                        border: Border.all(
                          color: AppColors.secondaryContainer.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        PhosphorIcons.globe,
                        size: 32,
                        color: AppColors.secondaryContainer,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                    Text(
                      'Fulɓe Connect',
                      style: AppTextStyles.headlineLgMobile.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackLg),

                    // Custom glassmorphic tab selector
                    if (!_showEmailConfirmation) ...[
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: AppColors.secondaryContainer,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: AppColors.onSecondaryContainer,
                          unselectedLabelColor: AppColors.primaryFixedDim,
                          labelStyle: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w700),
                          unselectedLabelStyle: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w500),
                          tabs: const [
                            Tab(text: 'Connexion'),
                            Tab(text: 'Inscription'),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.stackLg),
                    ],

                    // Error Message box
                    if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: AppSpacing.stackMd),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(color: AppColors.error),
                        ),
                        child: Row(
                          children: [
                            const Icon(PhosphorIcons.warningCircle, color: AppColors.onErrorContainer),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: AppTextStyles.bodyMd.copyWith(
                                  color: AppColors.onErrorContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Form Views
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: _showEmailConfirmation
                          ? _buildEmailConfirmationScreen()
                          : (_tabController.index == 0
                              ? _buildLoginForm()
                              : _buildRegisterForm()),
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

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _emailController,
            label: 'Adresse email',
            hint: 'exemple@domaine.com',
            icon: PhosphorIcons.envelope,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Veuillez saisir votre email';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Veuillez saisir une adresse email valide';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.stackMd),
          _buildTextField(
            controller: _passwordController,
            label: 'Mot de passe',
            hint: '••••••••',
            icon: PhosphorIcons.lockSimple,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? PhosphorIcons.eyeSlash : PhosphorIcons.eye,
                color: AppColors.primaryFixedDim,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Veuillez saisir votre mot de passe';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.stackLg),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryContainer,
                foregroundColor: AppColors.onSecondaryContainer,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
                disabledBackgroundColor: AppColors.secondaryContainer.withValues(alpha: 0.5),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.onSecondaryContainer),
                      ),
                    )
                  : Text(
                      'Se connecter',
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.onSecondaryContainer,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.stackMd),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _nameController,
            label: 'Nom complet',
            hint: 'Aaliyah Sow',
            icon: PhosphorIcons.user,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Veuillez saisir votre nom';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.stackSm),
          _buildCountryDropdown(),
          const SizedBox(height: AppSpacing.stackSm),
          _buildLocationButton(),
          const SizedBox(height: AppSpacing.stackSm),
          _buildCityDropdown(),
          const SizedBox(height: AppSpacing.stackSm),
          _buildTextField(
            controller: _emailController,
            label: 'Adresse email',
            hint: 'exemple@domaine.com',
            icon: PhosphorIcons.envelope,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Veuillez saisir votre email';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Veuillez saisir une adresse email valide';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.stackSm),
          _buildTextField(
            controller: _passwordController,
            label: 'Mot de passe',
            hint: '••••••••',
            icon: PhosphorIcons.lockSimple,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? PhosphorIcons.eyeSlash : PhosphorIcons.eye,
                color: AppColors.primaryFixedDim,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Veuillez saisir un mot de passe';
              if (value.length < 6) return 'Le mot de passe doit contenir au moins 6 caractères';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.stackSm),
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Confirmer le mot de passe',
            hint: '••••••••',
            icon: PhosphorIcons.lockSimple,
            obscureText: _obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? PhosphorIcons.eyeSlash : PhosphorIcons.eye,
                color: AppColors.primaryFixedDim,
              ),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Les mots de passe ne correspondent pas';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.stackLg),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryContainer,
                foregroundColor: AppColors.onSecondaryContainer,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
                disabledBackgroundColor: AppColors.secondaryContainer.withValues(alpha: 0.5),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.onSecondaryContainer),
                      ),
                    )
                  : Text(
                      'Créer un compte',
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.onSecondaryContainer,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.stackMd),
        ],
      ),
    );
  }

  /// Écran affiché après inscription : invite l'utilisateur à vérifier
  /// sa boîte email et cliquer sur le lien de confirmation envoyé par Supabase.
  Widget _buildEmailConfirmationScreen() {
    final email = _emailController.text.trim();
    return Column(
      key: const ValueKey('email_confirmation'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: AppSpacing.stackLg),
        // Icône email
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.secondaryContainer.withValues(alpha: 0.15),
            border: Border.all(
              color: AppColors.secondaryContainer.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: const Icon(
            PhosphorIcons.envelope,
            size: 40,
            color: AppColors.secondaryContainer,
          ),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        Text(
          'Vérifiez votre email',
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.onPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Nous avons envoyé un lien de confirmation à',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.primaryFixedDim,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.secondaryContainer,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Cliquez sur le lien contenu dans l\'email pour activer votre compte, puis connectez-vous.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.primaryFixedDim,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.stackLg),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _goToLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryContainer,
              foregroundColor: AppColors.onSecondaryContainer,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
            ),
            child: Text(
              'Se connecter',
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.onSecondaryContainer,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _showEmailConfirmation = false;
              });
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
            ),
            child: Text(
              'Retour à l\'inscription',
              style: AppTextStyles.labelMd.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSm.copyWith(
            color: AppColors.primaryFixedDim,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.onPrimary),
          enabled: !_isLoading,
          validator: validator,
          cursorColor: AppColors.secondaryContainer,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.primaryFixedDim.withValues(alpha: 0.5)),
            prefixIcon: Icon(icon, color: AppColors.primaryFixedDim, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.secondaryContainer, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            errorStyle: AppTextStyles.labelSm.copyWith(color: Colors.redAccent, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  /// Wrapper commun pour les [DropdownButtonFormField] (pays, ville, ...).
  ///
  /// Réutilise le style glassmorphique de [_buildTextField] (fond sombre,
  /// bordures blanches subtiles, focus doré via [AppColors.secondaryContainer]).
  Widget _buildDropdown({
    required String label,
    required String hint,
    required IconData icon,
    required List<String> items,
    required String? value,
    required ValueChanged<String?>? onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSm.copyWith(
            color: AppColors.primaryFixedDim,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          onChanged: _isLoading ? null : onChanged,
          validator: validator,
          iconEnabledColor: AppColors.primaryFixedDim,
          iconDisabledColor: AppColors.primaryFixedDim.withValues(alpha: 0.4),
          dropdownColor: AppColors.primary,
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.onPrimary),
          selectedItemBuilder: (context) => items
              .map((s) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      s,
                      style: AppTextStyles.bodyMd
                          .copyWith(color: AppColors.onPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          decoration: InputDecoration(
            hintText: items.isEmpty ? hint : hint,
            hintStyle: AppTextStyles.bodyMd.copyWith(
              color: AppColors.primaryFixedDim.withValues(alpha: 0.5),
            ),
            prefixIcon: Icon(icon, color: AppColors.primaryFixedDim, size: 20),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(
                  color: AppColors.secondaryContainer, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            errorStyle: AppTextStyles.labelSm.copyWith(
                color: Colors.redAccent, fontWeight: FontWeight.w500),
          ),
          items: items
              .map((s) => DropdownMenuItem<String>(
                    value: s,
                    child: Text(
                      s,
                      style: AppTextStyles.bodyMd
                          .copyWith(color: AppColors.onPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  /// Dropdown du pays — basé sur [Countries.names].
  Widget _buildCountryDropdown() {
    return _buildDropdown(
      label: 'Pays de résidence',
      hint: 'Sélectionnez votre pays',
      icon: PhosphorIcons.globe,
      items: Countries.names,
      value: _selectedCountry,
      onChanged: (newCountry) {
        setState(() {
          _selectedCountry = newCountry;
          // Reset ville si elle n'appartient plus au nouveau pays
          if (_selectedCity != null &&
              !Countries.citiesFor(newCountry ?? '')
                  .contains(_selectedCity)) {
            _selectedCity = null;
          }
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez sélectionner votre pays de résidence';
        }
        return null;
      },
    );
  }

  /// Dropdown de la ville — filtré par le pays sélectionné.
  ///
  /// **Palier 1 (fix bug)** : si aucun pays n'est sélectionné, on rend un
  /// [TextFormField] désactivé (lecture seule) plutôt qu'un
  /// [DropdownButtonFormField] avec `items: []` + `value: null` qui lève une
  /// exception runtime silencieuse.
  Widget _buildCityDropdown() {
    if (_selectedCountry == null) {
      // Pas de pays → on rend un TextFormField désactivé qui sert de placeholder.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ville de résidence',
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.primaryFixedDim,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            enabled: false,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.primaryFixedDim.withValues(alpha: 0.5),
            ),
            decoration: InputDecoration(
              hintText: "Sélectionnez d'abord un pays",
              hintStyle: AppTextStyles.bodyMd.copyWith(
                color: AppColors.primaryFixedDim.withValues(alpha: 0.5),
              ),
              prefixIcon: const Icon(PhosphorIcons.buildings,
                  color: AppColors.primaryFixedDim, size: 20),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.04),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.10)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.10)),
              ),
            ),
          ),
        ],
      );
    }

    final cities = Countries.citiesFor(_selectedCountry!);
    return _buildDropdown(
      label: 'Ville de résidence',
      hint: cities.isEmpty
          ? 'Aucune ville connue pour ce pays (saisie libre plus tard)'
          : 'Sélectionnez votre ville',
      icon: PhosphorIcons.buildings,
      items: cities,
      value: _selectedCity,
      onChanged: cities.isEmpty
          ? null
          : (newCity) => setState(() => _selectedCity = newCity),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez sélectionner votre ville de résidence';
        }
        return null;
      },
    );
  }

  /// Bouton **📍 Utiliser ma position actuelle** — demande la permission GPS,
  /// récupère la position, fait un reverse-geocoding, et peuple les dropdowns.
  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLocating = true;
      _locationHint = null;
    });

    try {
      final result = await _locationService.resolveCurrent();
      if (result == null || !mounted) return;

      setState(() {
        _selectedCountry = result.country;
        // Si la ville détectée est dans la liste, on la sélectionne ;
        // sinon on la stocke dans _locationHint pour affichage ultérieur.
        final knownCities = Countries.citiesFor(result.country);
        if (knownCities.contains(result.city)) {
          _selectedCity = result.city;
          _locationHint = null;
        } else {
          _selectedCity = null;
          _locationHint = result.city.isNotEmpty
              ? '📍 ${result.city} détecté (hors liste, non sélectionnable)'
              : '📍 Pays détecté : ${result.country} (ville non trouvée)';
        }
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _locationHint = '⚠️ ${e.message}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _locationHint =
          '⚠️ Erreur inattendue lors de la géolocalisation.');
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  /// Bouton GPS + hint contextuel.
  Widget _buildLocationButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: (_isLoading || _isLocating) ? null : _useCurrentLocation,
          icon: _isLocating
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.secondaryContainer),
                  ),
                )
              : const Icon(PhosphorIcons.crosshair, size: 16),
          label: Text(
            _isLocating
                ? 'Localisation en cours…'
                : 'Utiliser ma position actuelle',
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.secondaryContainer,
            side: BorderSide(
              color: AppColors.secondaryContainer.withValues(alpha: 0.5),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            textStyle: AppTextStyles.labelSm
                .copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        if (_locationHint != null) ...[
          const SizedBox(height: 6),
          Text(
            _locationHint!,
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.primaryFixedDim,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.secondaryContainer.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;
    const spacing = 28.0;
    const radius = 1.2;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
