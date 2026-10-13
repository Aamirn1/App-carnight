import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'photo_draft.dart';

/// Records only confirmed server deletions, never passwords or access tokens.
/// Failed device cleanup remains journaled and retries on the next startup.
abstract final class AccountCleanup {
  static const key = 'carsnight.deleted-account-cleanup';
  static Future<void> mark(String owner) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = {...?prefs.getStringList(key), owner}.toList();
    if (!await prefs.setStringList(key,pending)) throw StateError('Cleanup journal unavailable');
  }
  static Future<void> retry({required Future<void> Function() clearCache}) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(key) ?? [];
    if (pending.isEmpty) return;
    final root = await getApplicationSupportDirectory();
    final store = PhotoDraftStore(Directory('${root.path}/photo-drafts'));
    for (final owner in pending) await store.clear(owner);
    await clearCache();
    if (!await prefs.remove(key)) throw StateError('Cleanup journal could not be cleared');
  }
}
