import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'components.dart';
import '../backend/session.dart';
import '../backend/supabase_repositories.dart';

enum AuthMode { signIn, signUp, recovery, updatePassword }

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
  bool _busy = false;
  String? _message;

  Future<void> _submit() async {
    final backend = BackendScope.of(context);
    if (_busy || backend == null || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      switch (widget.mode) {
        case AuthMode.signIn:
          await backend.accounts.signIn(
            email: _email.text,
            password: _password.text,
          );
          if (!mounted) return;
          Navigator.maybePop(context);
          break;
        case AuthMode.signUp:
          await backend.accounts.signUp(
            email: _email.text,
            password: _password.text,
            displayName: _name.text,
          );
          _message =
              'Request received. Check your email to confirm your account, '
              'then return here to sign in.';
          break;
        case AuthMode.recovery:
          await backend.accounts.sendPasswordReset(_email.text);
          _message =
              'If an account exists for this email, you will receive a reset link. '
              'Open it on this phone.';
          break;
        case AuthMode.updatePassword:
          await backend.accounts.updatePassword(_password.text);
          backend.finishRecovery();
          break;
      }
      if (mounted) _password.clear();
    } catch (error) {
      _message = serviceError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final signup = widget.mode == AuthMode.signUp;
    final recovery = widget.mode == AuthMode.recovery;
    final update = widget.mode == AuthMode.updatePassword;
    final backend = BackendScope.of(context);
    final title = update
        ? 'Choose a new password'
        : recovery
        ? 'Reset password'
        : signup
        ? 'Create account'
        : 'Welcome back';
    return PageFrame(
      title: title,
      children: [
        const Center(child: Brand(large: true)),
        const SizedBox(height: 20),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          recovery
              ? 'Get back to your car community.'
              : 'Your next connection starts here.',
          style: const TextStyle(color: NightTheme.muted),
        ),
        if (backend == null)
          const InfoNote(
            'Online accounts are not enabled in this build. You can explore the sample feed.',
          ),
        if (_message != null)
          Semantics(liveRegion: true, child: InfoNote(_message!)),
        Form(
          key: _form,
          child: Column(
            children: [
              if (signup) ...[
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 80,
                  decoration: const InputDecoration(labelText: 'Display name'),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Enter your name.' : null,
                ),
                const SizedBox(height: 12),
              ],
              if (!update)
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) =>
                      RegExp(
                        r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                      ).hasMatch((v ?? '').trim())
                      ? null
                      : 'Enter a valid email address.',
                ),
              if (!recovery) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'Show password' : 'Hide password',
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (v) =>
                      (v ?? '').length < (signup || update ? 8 : 1)
                      ? (signup || update
                            ? 'Use at least 8 characters.'
                            : 'Enter your password.')
                      : null,
                ),
              ],
            ],
          ),
        ),
        if (!signup && !recovery && !update)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => pushPage<void>(
                context,
                const AuthPage(mode: AuthMode.recovery),
              ),
              child: const Text('Forgot password?'),
            ),
          ),
        const SizedBox(height: 20),
        GradientButton(
          label: _busy
              ? 'Please wait…'
              : update
              ? 'Save password'
              : recovery
              ? 'Send reset link'
              : signup
              ? 'Create account'
              : 'Sign in',
          onPressed: backend == null || _busy ? null : _submit,
        ),
        if (update && !_busy)
          TextButton(
            onPressed: () async {
              try {
                await backend?.accounts.signOut();
              } catch (error) {
                if (mounted) setState(() => _message = serviceError(error));
              }
            },
            child: const Text('Cancel and sign out'),
          ),
        if (!signup && !recovery && !update)
          TextButton(
            onPressed: () =>
                pushPage<void>(context, const AuthPage(mode: AuthMode.signUp)),
            child: const Text('New here? Create an account'),
          ),
      ],
    );
  }
}
