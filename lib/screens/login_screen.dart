import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import 'attendance_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;

  void _loginProcess(Future<void> Function() loginAction) async {
    setState(() => _isLoading = true);
    try {
      await loginAction();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AttendanceScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleLogin() {
    _loginProcess(() async {
      final auth = Provider.of<AuthService>(context, listen: false);
      final user = await auth.signIn(_emailCtrl.text.trim(), _passwordCtrl.text);
      if (user != null && !user.emailVerified) {
        throw Exception("Please verify your email before logging in.");
      }
    });
  }

  void _handleBiometricLogin() {
    _loginProcess(() async {
      final bioService = Provider.of<BiometricService>(context, listen: false);
      final auth = Provider.of<AuthService>(context, listen: false);
      final success = await bioService.authenticate('Authenticate to log in');
      if (success) {
        // Typically, you'd securely store credentials and log them in dynamically using Firebase.
        // For demonstration, if biometrics pass and there's a stored session or we just allow it on a real implementation:
        // We ensure there's at least an active user or we fail.
        if (auth.currentUser == null) {
          throw Exception("No active session found for biometrics. Use password first.");
        }
      } else {
        throw Exception("Biometric authentication failed or canceled.");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      body: Container(
        decoration: AppTheme.buildAuroraBackground(isDark),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                      onPressed: () => themeProvider.toggleTheme(!isDark),
                    )
                  ],
                ),
                Text(
                  'Welcome Back!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to your account',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordCtrl,
                  decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                  obscureText: true,
                ),
                const SizedBox(height: 32),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  ElevatedButton(
                    onPressed: _handleLogin,
                    child: const Text('Login'),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _handleBiometricLogin,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Login with Biometrics'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    ),
                    child: const Text("Don't have an account? Sign up"),
                  )
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
