import 'dart:async';
import 'package:flutter/material.dart';
import 'repositories.dart';
import 'social.dart';

class BackendSession extends ChangeNotifier {
  BackendSession({required this.accounts, required this.drafts, this.social}) {
    _accountSub = accounts.accountChanges.listen(
      (value) {
        _generation++;
        account = value;
        initializing = false;
        _syncProfile(value);
        if (value == null) { recovering = false; emailVerifiedNotice = false; }
        notifyListeners();
      },
      onError: (Object _) {
        // Do not expose SDK errors or tokens in the UI/logs.
        notifyListeners();
      },
    );
    _recoverySub = accounts.recoveryChanges.listen((value) {
      recovering = value;
      notifyListeners();
    }, onError: (Object _) {});
    _restore();
  }
  final AccountsRepository accounts;
  final DraftsRepository drafts;
  final SocialRepository? social;
  AccountSummary? account;
  bool recovering = false;
  bool initializing = true;
  bool emailVerifiedNotice = false;
  void showEmailVerified() {
    if (_disposed) return;
    emailVerifiedNotice = true;
    notifyListeners();
  }
  void dismissEmailVerified() { emailVerifiedNotice = false; notifyListeners(); }
  int _generation = 0;
  bool _disposed = false;
  late final StreamSubscription<AccountSummary?> _accountSub;
  late final StreamSubscription<bool> _recoverySub;
  Future<void> _restore() async {
    final generation = _generation;
    try {
      final restored = await accounts.currentAccount();
      if (_disposed || generation != _generation) return;
      account = restored;
      _syncProfile(restored);
      notifyListeners();
    } catch (_) {
      /* A later successful auth event can recover. */
    } finally {
      if (!_disposed) {initializing = false; notifyListeners();}
    }
  }

  void _syncProfile(AccountSummary? value) {
    final api = social;
    if (value == null || api == null) return;
    // Schedule outside the auth stream callback; auth events must stay synchronous.
    unawaited(
      Future<void>(() async {
        if (_disposed || account?.id != value.id) return;
        try {
          await api.ensureProfile(value.displayName);
        } catch (_) {
          /* Schema/network recovery is handled by community screens. */
        }
      }),
    );
  }

  void finishRecovery() {
    recovering = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _accountSub.cancel();
    _recoverySub.cancel();
    super.dispose();
  }
}

class BackendScope extends InheritedNotifier<BackendSession> {
  const BackendScope({
    super.key,
    required BackendSession? session,
    required super.child,
  }) : super(notifier: session);
  static BackendSession? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BackendScope>()?.notifier;
}
