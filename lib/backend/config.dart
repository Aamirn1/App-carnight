import 'dart:convert';

class BackendConfig {
  const BackendConfig({required this.url, required this.key});
  const BackendConfig.environment()
      : url = const String.fromEnvironment('SUPABASE_URL',
            defaultValue: 'https://romhqgmsoabzowwvuvvp.supabase.co'),
        key = const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  final String url;
  final String key;

  bool get isConfigured => key.isNotEmpty;

  String? get validationError {
    if (!isConfigured) return 'Online accounts are not enabled in this build.';
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty ||
        uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment) {
      return 'The online service address is invalid.';
    }
    if (key.startsWith('sb_publishable_') && key.length > 25) return null;
    // Legacy anon JWTs are public too. Refuse privileged keys in client builds.
    try {
      final parts = key.split('.');
      if (parts.length == 3) {
        final payload = jsonDecode(utf8.decode(base64Url.decode(
            base64Url.normalize(parts[1])))) as Map<String, dynamic>;
        if (payload['role'] == 'anon') return null;
      }
    } catch (_) {
      // Invalid configuration must never be sent to a service.
    }
    return 'A valid public Supabase key is required for online accounts.';
  }
}
