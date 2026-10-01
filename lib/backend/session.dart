import 'dart:async';
import 'package:flutter/material.dart';
import 'repositories.dart';

class BackendSession extends ChangeNotifier {
  BackendSession({required this.accounts, required this.drafts}) {
    _accountSub = accounts.accountChanges.listen((value) {
      _generation++;
      account = value;
      if (value == null) recovering = false;
      notifyListeners();
    }, onError: (Object _) {
      // Do not expose SDK errors or tokens in the UI/logs.
      notifyListeners();
    });
    _recoverySub = accounts.recoveryChanges.listen((value) {
      recovering = value;
      notifyListeners();
    }, onError: (Object _) {});
    _restore();
  }
  final AccountsRepository accounts;
  final DraftsRepository drafts;
  AccountSummary? account;
  bool recovering = false;
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
      notifyListeners();
    } catch (_) { /* A later successful auth event can recover. */ }
  }
  void finishRecovery() { recovering = false; notifyListeners(); }
  @override
  void dispose() {
    _disposed = true;
    _accountSub.cancel();
    _recoverySub.cancel();
    super.dispose();
  }
}

class BackendScope extends InheritedNotifier<BackendSession> {
  const BackendScope({super.key, required BackendSession? session, required super.child})
      : super(notifier: session);
  static BackendSession? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BackendScope>()?.notifier;
}
