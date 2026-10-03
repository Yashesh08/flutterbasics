import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_service.dart';
import 'home_screen.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'screens/admin_dashboard_screen.dart';

void main() => runApp(const CanteenApp());

class CanteenApp extends StatelessWidget {
  const CanteenApp({super.key, this.authService});

  final AuthService? authService;

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => OrderProvider()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Campus Canteen',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006C4F)),
            useMaterial3: true,
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
              filled: true,
            ),
          ),
          home: LoginScreen(authService: authService ?? AuthService()),
        ),
      );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final result = await widget.authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      if (!mounted) return;
      final user = result.user;
      final isStaff = user.role == 'staff' || user.role == 'admin';
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => isStaff
            ? ChangeNotifierProvider(
                create: (_) => OrderProvider(),
                child: AdminDashboardScreen(staffUser: user),
              )
            : HomeScreen(user: user),
      ));
    } on AuthException catch (error) {
      _showError(error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

  @override
  Widget build(BuildContext context) => AuthScaffold(
        title: 'Welcome back',
        subtitle: 'Log in to order from your campus canteen.',
        form: Form(
          key: _formKey,
          child: Column(children: [
            EmailField(controller: _emailController),
            const SizedBox(height: 16),
            PasswordField(
              controller: _passwordController,
              obscure: _obscurePassword,
              onVisibilityChanged: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            const SizedBox(height: 24),
            SubmitButton(label: 'Log in', loading: _submitting, onPressed: _login),
            const SizedBox(height: 16),
            DemoAccountPanel(
              onUseAccount: (account) {
                setState(() {
                  _emailController.text = account.user.email;
                  _passwordController.text = account.password;
                });
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _submitting
                  ? null
                  : () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => SignupScreen(authService: widget.authService),
                      )),
              child: const Text("New here? Create an account"),
            ),
          ]),
        ),
      );
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'student';
  bool _obscurePassword = true;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final result = await widget.authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _role,
      );
      if (!mounted) return;
      if (!mounted) return;
      final user = result.user;
      final isStaff = user.role == 'staff' || user.role == 'admin';
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => isStaff
              ? ChangeNotifierProvider(
                  create: (_) => OrderProvider(),
                  child: AdminDashboardScreen(staffUser: user),
                )
              : HomeScreen(user: user),
        ),
        (_) => false,
      );
    } on AuthException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthScaffold(
        title: 'Create your account',
        subtitle: 'Join the campus canteen and skip the queue.',
        form: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline)),
              validator: (value) => (value == null || value.trim().length < 2)
                  ? 'Enter your full name'
                  : null,
            ),
            const SizedBox(height: 16),
            EmailField(controller: _emailController),
            const SizedBox(height: 16),
            PasswordField(
              controller: _passwordController,
              obscure: _obscurePassword,
              onVisibilityChanged: () => setState(() => _obscurePassword = !_obscurePassword),
              helperText: 'Use at least 8 characters.',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'I am a', prefixIcon: Icon(Icons.badge_outlined)),
              items: const [
                DropdownMenuItem(value: 'student', child: Text('Student')),
                DropdownMenuItem(value: 'staff', child: Text('Canteen staff')),
              ],
              onChanged: _submitting ? null : (value) => setState(() => _role = value!),
            ),
            const SizedBox(height: 24),
            SubmitButton(label: 'Create account', loading: _submitting, onPressed: _register),
          ]),
        ),
      );
}

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.title, required this.subtitle, required this.form});

  final String title;
  final String subtitle;
  final Widget form;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Icon(Icons.restaurant_menu, size: 64, color: Color(0xFF006C4F)),
                  const SizedBox(height: 20),
                  Text(title, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(subtitle, textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  form,
                ]),
              ),
            ),
          ),
        ),
      );
}

class EmailField extends StatelessWidget {
  const EmailField({super.key, required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.email_outlined)),
        validator: (value) => value != null && RegExp(r'^\S+@\S+\.\S+$').hasMatch(value.trim())
            ? null
            : 'Enter a valid email address',
      );
}

class PasswordField extends StatelessWidget {
  const PasswordField({super.key, required this.controller, required this.obscure, required this.onVisibilityChanged, this.helperText});
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onVisibilityChanged;
  final String? helperText;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        obscureText: obscure,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: 'Password',
          helperText: helperText,
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            tooltip: obscure ? 'Show password' : 'Hide password',
            icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            onPressed: onVisibilityChanged,
          ),
        ),
        validator: (value) => value != null && value.length >= 8 ? null : 'Password must be at least 8 characters',
      );
}

class SubmitButton extends StatelessWidget {
  const SubmitButton({super.key, required this.label, required this.loading, required this.onPressed});
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        child: loading ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2)) : Text(label),
      );
}


class DemoAccountPanel extends StatelessWidget {
  const DemoAccountPanel({super.key, required this.onUseAccount});

  final ValueChanged<SeedAccount> onUseAccount;

  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Demo accounts', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            const Text('Use these while the database is not connected.'),
            const SizedBox(height: 8),
            ...seedAccounts.map((account) => TextButton(
                  onPressed: () => onUseAccount(account),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${account.user.role}: ${account.user.email} / ${account.password}',
                    ),
                  ),
                )),
          ]),
        ),
      );
}
