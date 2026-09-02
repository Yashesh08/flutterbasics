import 'package:flutter/material.dart';

import 'auth_service.dart';

void main() => runApp(const CanteenApp());

class CanteenApp extends StatelessWidget {
  const CanteenApp({super.key, this.authService});

  final AuthService? authService;

  @override
  Widget build(BuildContext context) => MaterialApp(
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
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => WelcomeScreen(user: result.user),
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
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => WelcomeScreen(user: result.user)),
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

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.user});
  final AuthUser user;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Campus Canteen')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.check_circle_outline, size: 72, color: Color(0xFF006C4F)),
              const SizedBox(height: 16),
              Text('Welcome, ${user.name}!', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('Signed in as ${user.role}. Your canteen features are ready.'),
            ]),
          ),
        ),
      );
}
