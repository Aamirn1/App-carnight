import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'core/appearance.dart';
import 'core/brand_image.dart';
import 'data/account_cleanup.dart';
import 'ui/remote_photo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'backend/config.dart';
import 'backend/social.dart';
import 'backend/session.dart';
import 'backend/supabase_repositories.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
  final appearance = Appearance();
  await appearance.restore();
  try {
    await AccountCleanup.retry(clearCache: PhotoCache.manager.emptyCache);
  } catch (_) {
    /* Retry confirmed deletion cleanup on the next startup. */
  }
  if (appearance.mode == ThemeMode.light ||
      (appearance.mode == ThemeMode.system &&
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.light)) {
    await BrandImage.light;
  }
  runApp(
    CarsNightApp(
      backend: backend,
      startupError: startupError,
      appearance: appearance,
    ),
  );
}
