import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/locale_service.dart';
import '../services/migration_service.dart';
import '../widgets/app_logo.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final VoidCallback onSkip;

  const LoginPage({
    super.key,
    required this.onLoginSuccess,
    required this.onSkip,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      final result = await AuthService.signInWithGoogle();
      if (result != null) {
        await MigrationService.migrateIfNeeded();
        if (mounted) widget.onLoginSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr('auth.sign_in_failed')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Spacer(flex: 3),
                const AppLogo(size: 80),
                const SizedBox(height: 20),
                Text(
                  'Faktura',
                  style: theme.textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  tr('auth.sign_in_subtitle'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 40),
                // Google Sign-In button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signIn,
                    icon: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : Image.network(
                            'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                            width: 20,
                            height: 20,
                            errorBuilder: (_, _, _) => Icon(
                              Icons.g_mobiledata,
                              size: 24,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                    label: Text(
                      _isLoading
                          ? tr('auth.signing_in')
                          : tr('auth.sign_in'),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF333647)
                            : const Color(0xFFDDDFE4),
                      ),
                      foregroundColor: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading ? null : widget.onSkip,
                  child: Text(tr('auth.skip')),
                ),
                const Spacer(flex: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
