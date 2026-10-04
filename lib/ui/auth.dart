import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import '../core/platform_actions.dart';
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
  final _city = TextEditingController();
  final _code = TextEditingController();
  Country? _country;
  bool _sent = false;
  bool _obscure = true;
  bool _busy = false;
  String? _message;

  Future<void> _submit() async {
    final backend = BackendScope.of(context);
    if (_busy || backend == null || !_form.currentState!.validate()) return;
    if (widget.mode == AuthMode.signUp && _country == null) {
      setState(() => _message = 'Choose your country.');
      return;
    }
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
          Navigator.of(context).popUntil((route) => route.isFirst);
          break;
        case AuthMode.signUp:
          await backend.accounts.signUp(
            email: _email.text,
            password: _password.text,
            displayName: _name.text,
            countryCode: _country!.countryCode,
            city: _city.text,
          );
          _sent = true;
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

  Future<void> _verifyCode() async {
    final backend = BackendScope.of(context);
    if (_busy || backend == null) return;
    if (!RegExp(r'^\d{6,10}$').hasMatch(_code.text.trim())) {
      setState(() => _message = 'Enter the verification code from your email.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await backend.accounts.verifyEmailCode(
        email: _email.text,
        code: _code.text,
      );
      backend.showEmailVerified();
    } catch (_) {
      if (mounted)
        setState(
          () => _message =
              'This code is invalid or expired. Check your latest email and try again.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _confirmation() => PageFrame(
    title: 'Check your email',
    children: [
      const Center(child: Brand(large: true)),
      const SizedBox(height: 24),
      Icon(
        Icons.mark_email_unread_outlined,
        size: 52,
        color: Theme.of(context).colorScheme.primary,
      ),
      const SizedBox(height: 20),
      Text('One last step', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 12),
      Text(
        'If this address is eligible, a confirmation email has been sent to ${_email.text.trim()}. '
        'Tap Confirm account in the email, or enter its code below.',
      ),
      const SizedBox(height: 24),
      GradientButton(
        label: 'Open Gmail',
        onPressed: () async {
          final opened = await PlatformActions.openEmail();
          if (!opened && mounted)
            setState(
              () => _message =
                  'Open your email app manually and look for Cars Night.',
            );
        },
      ),
      const SizedBox(height: 20),
      TextField(
        enabled: !_busy,
        controller: _code,
        keyboardType: TextInputType.number,
        maxLength: 10,
        decoration: const InputDecoration(
          labelText: 'Verification code',
          helperText: 'Available in the new Cars Night confirmation email.',
        ),
      ),
      if (_message != null)
        Semantics(liveRegion: true, child: InfoNote(_message!)),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: _busy ? null : _verifyCode,
        child: Text(_busy ? 'Verifying…' : 'Verify account'),
      ),
      TextButton(
        onPressed: _busy
            ? null
            : () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(builder: (_) => const AuthPage()),
              ),
        child: const Text('Already confirmed? Sign in'),
      ),
      TextButton(
        onPressed: _busy
            ? null
            : () => setState(() {
                _sent = false;
                _message = null;
              }),
        child: const Text('Use a different email'),
      ),
      Text(
        'Check Spam if the email is missing. Existing accounts can sign in or reset their password.',
        style: TextStyle(color: NightTheme.secondaryText(context)),
      ),
    ],
  );

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _city.dispose();
    _code.dispose();
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
    if (_sent) return _confirmation();
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
          style: TextStyle(color: NightTheme.secondaryText(context)),
        ),
        const SizedBox(height: 24),
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
                  enabled: !_busy,
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 80,
                  decoration: const InputDecoration(labelText: 'Display name'),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Enter your name.' : null,
                ),
                const SizedBox(height: 12),
                FormField<Country>(
                  validator: (_) =>
                      _country == null ? 'Choose your country.' : null,
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OutlinedButton.icon(
                        key: const ValueKey('signup-country'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                        ),
                        onPressed: _busy
                            ? null
                            : () => showCountryPicker(
                                context: context,
                                showPhoneCode: false,
                                onSelect: (country) {
                                  setState(() => _country = country);
                                  field.didChange(country);
                                },
                              ),
                        icon: const Icon(Icons.public),
                        label: Text(_country?.name ?? 'Choose country'),
                      ),
                      if (field.hasError)
                        Text(
                          field.errorText!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  enabled: !_busy,
                  controller: _city,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    helperText:
                        'Used to find cars in your area. You can browse other locations.',
                  ),
                  validator: (v) =>
                      (v ?? '').trim().length < 2 ? 'Enter your city.' : null,
                ),
                const SizedBox(height: 12),
              ],
              if (!update)
                TextFormField(
                  enabled: !_busy,
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
                  enabled: !_busy,
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
