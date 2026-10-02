import 'package:flutter/material.dart';
import 'app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'backend/config.dart';
import 'backend/social.dart';
import 'backend/session.dart';
import 'backend/supabase_repositories.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const config = BackendConfig.environment();
  BackendSession? backend;
  String? startupError;
  if (config.isConfigured) {
    startupError = config.validationError;
    if (startupError == null) {
      try {
        await Supabase.initialize(url: config.url, publishableKey: config.key);
        final client = Supabase.instance.client;
        backend = BackendSession(
          accounts: SupabaseAccountsRepository(client),
          drafts: SupabaseDraftsRepository(client),
          social: SocialRepository(client),
        );
      } catch (_) {
        startupError =
            'Online accounts could not start. Restart the app to retry. '
            'You can still explore the sample content.';
      }
    }
  }
  runApp(CarsNightApp(backend: backend, startupError: startupError));
}
