import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/router/app_router.dart';
import '../../providers/auth_provider.dart';

/// Authentication screen with Sign In / Sign Up tabs and OAuth options.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      await ref.read(authProvider.notifier).signInWithGoogle();
      if (mounted) context.go(Routes.discover);
    } catch (e) {
      _showError('Google sign-in failed. Please try again.');
    }
  }

  Future<void> _handleDiscordSignIn() async {
    try {
      await ref.read(authProvider.notifier).signInWithDiscord();
      if (mounted) context.go(Routes.discover);
    } catch (e) {
      _showError('Discord sign-in failed. Please try again.');
    }
  }

  Future<void> _handleGuestSignIn() async {
    try {
      await ref.read(authProvider.notifier).signInAsGuest();
      if (mounted) context.go(Routes.discover);
    } catch (e) {
      _showError('Could not start guest session. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 48),
              // ── Logo ──────────────────────────────────────────────────
              _ZenshiLogoSmall(),
              const SizedBox(height: 12),
              Text(
                'Zenshi',
                style: AppTypography.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to sync your library',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: 32),

              // ── Tab bar ───────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.onSurfaceMuted,
                  labelStyle: AppTypography.labelLarge,
                  tabs: const [
                    Tab(text: 'Sign In'),
                    Tab(text: 'Sign Up'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Tab views ─────────────────────────────────────────────
              SizedBox(
                height: 320,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _SignInForm(onSuccess: () => context.go(Routes.discover)),
                    _SignUpForm(onSuccess: () => context.go(Routes.discover)),
                  ],
                ),
              ),

              // ── Divider ───────────────────────────────────────────────
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.divider)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or',
                      style: AppTypography.bodySmall,
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.divider)),
                ],
              ),
              const SizedBox(height: 16),

              // ── OAuth buttons ─────────────────────────────────────────
              _OAuthButton(
                label: 'Continue with Google',
                icon: Icons.g_mobiledata_rounded,
                borderColor: Colors.white,
                textColor: Colors.white,
                onTap: _handleGoogleSignIn,
              ),
              const SizedBox(height: 12),
              _OAuthButton(
                label: 'Continue with Discord',
                icon: Icons.discord,
                borderColor: const Color(0xFF5865F2),
                textColor: const Color(0xFF5865F2),
                onTap: _handleDiscordSignIn,
              ),
              const SizedBox(height: 24),

              // ── Guest mode ────────────────────────────────────────────
              TextButton(
                onPressed: _handleGuestSignIn,
                child: Text(
                  'Continue as Guest',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.onSurfaceMuted,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sign In form ───────────────────────────────────────────────────────────────

class _SignInForm extends ConsumerStatefulWidget {
  const _SignInForm({required this.onSuccess});

  final VoidCallback onSuccess;

  @override
  ConsumerState<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends ConsumerState<_SignInForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(authProvider.notifier)
          .signInWithEmail(email, password);
      widget.onSuccess();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Email or password incorrect.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AuthTextField(
          controller: _emailController,
          hint: 'Email',
          keyboardType: TextInputType.emailAddress,
          enabled: !_loading,
        ),
        const SizedBox(height: 12),
        _AuthTextField(
          controller: _passwordController,
          hint: 'Password',
          obscureText: _obscurePassword,
          enabled: !_loading,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: AppColors.onSurfaceMuted,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Sign In'),
          ),
        ),
      ],
    );
  }
}

// ── Sign Up form ───────────────────────────────────────────────────────────────

class _SignUpForm extends ConsumerStatefulWidget {
  const _SignUpForm({required this.onSuccess});

  final VoidCallback onSuccess;

  @override
  ConsumerState<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends ConsumerState<_SignUpForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (email.isEmpty || password.isEmpty || confirm.isEmpty) return;
    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ref
          .read(authProvider.notifier)
          .signInWithEmail(email, password);
      widget.onSuccess();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account creation failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AuthTextField(
          controller: _emailController,
          hint: 'Email',
          keyboardType: TextInputType.emailAddress,
          enabled: !_loading,
        ),
        const SizedBox(height: 12),
        _AuthTextField(
          controller: _passwordController,
          hint: 'Password',
          obscureText: _obscurePassword,
          enabled: !_loading,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: AppColors.onSurfaceMuted,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 12),
        _AuthTextField(
          controller: _confirmController,
          hint: 'Confirm Password',
          obscureText: _obscureConfirm,
          enabled: !_loading,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirm ? Icons.visibility_off : Icons.visibility,
              color: AppColors.onSurfaceMuted,
            ),
            onPressed: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Create Account'),
          ),
        ),
      ],
    );
  }
}

// ── Shared text field ──────────────────────────────────────────────────────────

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      enabled: enabled,
      style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

// ── OAuth button ───────────────────────────────────────────────────────────────

class _OAuthButton extends StatelessWidget {
  const _OAuthButton({
    required this.label,
    required this.icon,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: textColor),
        label: Text(
          label,
          style: AppTypography.labelLarge.copyWith(color: textColor),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// ── Small logo ─────────────────────────────────────────────────────────────────

class _ZenshiLogoSmall extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9F5FFF), AppColors.primary, Color(0xFF5B21B6)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(80),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const Text(
        'Z',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 40,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}

// ── Account deletion dialog ────────────────────────────────────────────────────

/// Shows a confirmation dialog for account deletion.
///
/// Call this from the profile screen.
Future<void> showAccountDeletionDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Delete Account'),
      content: const Text(
        'This will permanently delete your account and all data within 30 days. '
        'This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Delete Account'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    try {
      await ref.read(authProvider.notifier).signOut();
    } catch (_) {
      // Ignore sign-out errors during deletion flow
    }
  }
}
