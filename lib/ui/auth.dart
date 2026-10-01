import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'components.dart';

enum AuthMode { signIn, signUp, recovery }

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.mode = AuthMode.signIn});
  final AuthMode mode;
  @override
  State<AuthPage> createState() => _AuthPageState();
}
class _AuthPageState extends State<AuthPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _obscure = true;
  @override
  void dispose() { _email.dispose(); _password.dispose(); _name.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final signup = widget.mode == AuthMode.signUp;
    final recovery = widget.mode == AuthMode.recovery;
    final title = recovery ? 'Reset password' : signup ? 'Create account' : 'Welcome back';
    return PageFrame(title: title, children: [
      const Center(child: Brand(large: true)), const SizedBox(height: 20),
      Text(title, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 8),
      Text(recovery ? 'Get back to your car community.' : 'Your next connection starts here.',
        style: const TextStyle(color: NightTheme.muted)),
      const InfoNote('Form preview only. Use sample details. Authentication is not connected '
        'and this form does not send or store credentials.'),
      Form(key: _form, child: Column(children: [
        if (signup) ...[
          TextFormField(controller: _name, textCapitalization: TextCapitalization.words,
            maxLength: 80, decoration: const InputDecoration(labelText: 'Display name'),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Enter your name.' : null),
          const SizedBox(height: 12),
        ],
        TextFormField(controller: _email, keyboardType: TextInputType.emailAddress,
          autocorrect: false, decoration: const InputDecoration(labelText: 'Email'),
          validator: (v) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch((v ?? '').trim()) ?
            null : 'Enter a valid email address.'),
        if (!recovery) ...[
          const SizedBox(height: 16),
          TextFormField(controller: _password, obscureText: _obscure,
            enableSuggestions: false, autocorrect: false,
            decoration: InputDecoration(labelText: 'Password',
              suffixIcon: IconButton(tooltip: _obscure ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined))),
            validator: (v) => (v ?? '').length < 8 ? 'Use at least 8 characters for this preview.' : null),
        ],
      ])),
      if (!signup && !recovery) Align(alignment: Alignment.centerRight,
        child: TextButton(onPressed: () => pushPage<void>(context,
          const AuthPage(mode: AuthMode.recovery)), child: const Text('Forgot password?'))),
      const SizedBox(height: 20),
      GradientButton(label: recovery ? 'Send reset link' : signup ? 'Create account' : 'Sign in',
        onPressed: () {
          if (!_form.currentState!.validate()) return;
          _password.clear();
          showUnavailable(context, 'Authentication is not connected',
            recovery ? 'No reset email was sent. This screen is a form preview.' :
              'No account was created or signed in. This screen is a form preview.');
        }),
      if (!signup && !recovery) TextButton(onPressed: () => pushPage<void>(context,
        const AuthPage(mode: AuthMode.signUp)), child: const Text('New here? Create an account')),
    ]);
  }
}
