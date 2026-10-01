import 'package:flutter/material.dart';
import 'core/assets.dart';
import 'core/session.dart';
import 'core/theme.dart';
import 'domain/models.dart';
import 'ui/auth.dart';
import 'ui/components.dart';
import 'ui/compose.dart';
import 'ui/feed.dart';
import 'ui/information.dart';
import 'ui/marketplace.dart';
import 'ui/profile.dart';

class CarsNightApp extends StatelessWidget {
  const CarsNightApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(title: 'Cars Night',
    debugShowCheckedModeBanner: false, theme: NightTheme.data,
    home: const WelcomePage());
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(
    child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480),
      child: SingleChildScrollView(child: Column(children: [
        Stack(children: [
          const AssetPhoto(asset: NightAssets.hero, ratio: 0.95,
            label: 'Blue sports car against a neon city skyline'),
          const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.transparent, NightTheme.background],
              stops: [0, 0.62, 1])))),
          const Positioned(bottom: 0, left: 0, right: 0, child: Center(child: Brand(large: true))),
        ]),
        Padding(padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(children: [
            Text('Global Car Marketplace\n& Community', textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            const Text('Buy. Rent. Connect. Share.', style: TextStyle(color: NightTheme.muted)),
            const SizedBox(height: 28),
            GradientButton(label: 'Get Started', onPressed: () =>
              pushPage<void>(context, const AppShell())),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: () => pushPage<void>(context, const AuthPage()),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: const Text('Sign in')),
            const SizedBox(height: 16),
            const Text('OFFLINE PREVIEW · SAMPLE CONTENT',
              style: TextStyle(color: NightTheme.muted, fontSize: 10, letterSpacing: 1)),
          ])),
      ])),
    )),
  ));
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}
class _AppShellState extends State<AppShell> {
  final _session = DemoSession();
  final Map<int, Widget> _pages = {};
  int _selected = 0;
  @override
  void initState() { super.initState(); _pages[0] = FeedPage(session: _session); }
  @override
  void dispose() { _session.dispose(); super.dispose(); }

  Future<void> _select(int index) async {
    if (index == 2) {
      final added = await pushPage<bool>(context, ComposePage(session: _session));
      if (!mounted || added != true) return;
      setState(() => _selected = 0);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Added to the local demo feed. Nothing was uploaded.')));
      return;
    }
    setState(() {
      _selected = index;
      _pages.putIfAbsent(index, () => switch (index) {
        1 => MarketplacePage(kind: ListingKind.sale, session: _session),
        3 => MarketplacePage(kind: ListingKind.rental, session: _session),
        4 => ProfilePage(session: _session),
        _ => FeedPage(session: _session),
      });
    });
  }

  void _openDrawerPage(Widget page) {
    Navigator.pop(context);
    pushPage<void>(context, page);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Brand(), toolbarHeight: 64,
      leading: Builder(builder: (context) => IconButton(tooltip: 'Open menu',
        onPressed: () => Scaffold.of(context).openDrawer(), icon: const Icon(Icons.menu))),
      actions: [
        IconButton(tooltip: 'Search community', icon: const Icon(Icons.search),
          onPressed: () => pushPage<void>(context, CommunitySearchPage(session: _session))),
        IconButton(tooltip: 'Notifications', icon: const Icon(Icons.notifications_outlined),
          onPressed: () => pushPage<void>(context, const NotificationsPage())),
      ]),
    drawer: Drawer(backgroundColor: NightTheme.background,
      width: MediaQuery.sizeOf(context).width.clamp(280, 350).toDouble() * 0.92,
      child: SafeArea(child: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [const Expanded(child: Align(alignment: Alignment.centerLeft, child: Brand())),
          IconButton(tooltip: 'Close menu', onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close))]),
        const SizedBox(height: 20),
        const ListTile(contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(backgroundColor: Color(0xFF352650),
            child: Icon(Icons.person_outline, color: NightTheme.cyan)),
          title: Text('Car enthusiast', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Guest preview')),
        const SizedBox(height: 12),
        for (final item in const [(0, 'Home', Icons.home_outlined),
          (1, 'Buy', Icons.shopping_cart_outlined), (3, 'Rent', Icons.car_rental)])
          Padding(padding: const EdgeInsets.only(bottom: 5),
            child: DecoratedBox(decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: _selected == item.$1 ? const LinearGradient(
                colors: [Color(0xFF243B89), Color(0xFF43204C)]) : null),
              child: ListTile(leading: Icon(item.$3,
                color: _selected == item.$1 ? NightTheme.cyan : NightTheme.muted),
                title: Text(item.$2), selected: _selected == item.$1,
                selectedColor: Colors.white,
                onTap: () { Navigator.pop(context); _select(item.$1); }))),
        ListTile(leading: const Icon(Icons.bookmark_border), title: const Text('Saved'),
          onTap: () => _openDrawerPage(SavedPage(session: _session))),
        ListTile(leading: const Icon(Icons.workspace_premium_outlined), title: const Text('Plan'),
          onTap: () => _openDrawerPage(const PlanPage())),
        ListTile(leading: const Icon(Icons.article_outlined), title: const Text('Blog'),
          onTap: () => _openDrawerPage(const BlogPage())),
        ListTile(leading: const Icon(Icons.info_outline), title: const Text('About'),
          onTap: () => _openDrawerPage(const AboutPage())),
        ListTile(leading: const Icon(Icons.mail_outline), title: const Text('Contact'),
          onTap: () => _openDrawerPage(const ContactPage())),
        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
        ListTile(leading: const Icon(Icons.settings_outlined), title: const Text('Settings'),
          onTap: () => _openDrawerPage(SettingsPage(session: _session))),
        ListTile(leading: const Icon(Icons.logout), title: const Text('Exit demo'),
          onTap: () { Navigator.pop(context); Navigator.pop(context); }),
        const InfoNote('Sample content. Changes reset when you exit.'),
      ]))),
    body: SafeArea(top: false, child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      // A tab is constructed only on first visit, then retains scroll/form state.
      child: IndexedStack(index: _selected, children: List.generate(5, (index) =>
        _pages[index] ?? const SizedBox.shrink())),
    ))),
    bottomNavigationBar: NavigationBar(selectedIndex: _selected,
      onDestinationSelected: _select, destinations: const [
        NavigationDestination(key: ValueKey('nav-home'), icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(key: ValueKey('nav-buy'), icon: Icon(Icons.shopping_bag_outlined),
          selectedIcon: Icon(Icons.shopping_bag), label: 'Buy'),
        NavigationDestination(key: ValueKey('nav-create'), icon: DecoratedBox(
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: NightTheme.gradient),
          child: Padding(padding: EdgeInsets.all(8), child: Icon(Icons.add, color: Colors.white))),
          label: 'Create'),
        NavigationDestination(key: ValueKey('nav-rent'), icon: Icon(Icons.directions_car_outlined),
          selectedIcon: Icon(Icons.directions_car), label: 'Rent'),
        NavigationDestination(key: ValueKey('nav-profile'), icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person), label: 'Profile'),
      ]),
  );
}
