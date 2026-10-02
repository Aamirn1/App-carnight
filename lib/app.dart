import 'package:flutter/material.dart';
import 'core/assets.dart';
import 'core/session.dart';
import 'core/theme.dart';
import 'backend/repositories.dart';
import 'ui/account.dart';
import 'ui/community.dart';
import 'ui/messages.dart';
import 'ui/auth.dart';
import 'ui/components.dart';
import 'ui/compose.dart';
import 'ui/feed.dart';
import 'ui/information.dart';
import 'ui/marketplace.dart';
import 'ui/profile.dart';
import 'backend/session.dart';

class CarsNightApp extends StatelessWidget {
  const CarsNightApp({super.key, this.backend, this.startupError});
  final BackendSession? backend;
  final String? startupError;
  @override
  Widget build(BuildContext context) => BackendScope(
    session: backend,
    child: MaterialApp(
      title: 'Cars Night',
      debugShowCheckedModeBanner: false,
      theme: NightTheme.data,
      builder: (context, child) => BackendScope.of(context)?.recovering == true
          ? const AuthPage(mode: AuthMode.updatePassword)
          : child!,
      home: WelcomePage(startupError: startupError),
    ),
  );
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key, this.startupError});
  final String? startupError;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Stack(
                  children: [
                    const AssetPhoto(
                      asset: NightAssets.hero,
                      ratio: 0.95,
                      label: 'Blue sports car against a neon city skyline',
                    ),
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.transparent,
                              NightTheme.background,
                            ],
                            stops: [0, 0.62, 1],
                          ),
                        ),
                      ),
                    ),
                    const Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Center(child: Brand(large: true)),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    children: [
                      Text(
                        'The community for\ncar lovers',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      if (startupError != null) InfoNote(startupError!),
                      const Text(
                        'Share. Connect. Discover.',
                        style: TextStyle(color: NightTheme.muted),
                      ),
                      const SizedBox(height: 28),
                      GradientButton(
                        label: 'Get Started',
                        onPressed: () =>
                            pushPage<void>(context, const AppShell()),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () =>
                            pushPage<void>(context, const AuthPage()),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                        child: const Text('Sign in'),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'SAMPLE FEED · PREVIEW BUILD',
                        style: TextStyle(
                          color: NightTheme.muted,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
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
  void initState() {
    super.initState();
    _pages[0] = CommunityPage(demo: _session);
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  Future<void> _select(int index) async {
    if (index == 2) {
      final backend = BackendScope.of(context);
      if (backend != null) {
        final account = backend.account;
        if (account == null) {
          await pushPage<void>(context, const AuthPage());
        } else {
          await pushPage<bool>(
            context,
            DraftEditor(kind: DraftKind.post, ownerId: account.id),
          );
        }
        return;
      }
      final added = await pushPage<bool>(
        context,
        ComposePage(session: _session),
      );
      if (!mounted || added != true) return;
      setState(() => _selected = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added to the local demo feed. Nothing was uploaded.'),
        ),
      );
      return;
    }
    setState(() {
      _selected = index;
      _pages.putIfAbsent(
        index,
        () => switch (index) {
          1 => const MessagesPage(),
          3 => MarketplaceHub(session: _session),
          4 => ProfilePage(session: _session),
          _ => CommunityPage(demo: _session),
        },
      );
    });
  }

  void _openDrawerPage(Widget page) {
    Navigator.pop(context);
    pushPage<void>(context, page);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Brand(),
      toolbarHeight: 64,
      leading: Builder(
        builder: (context) => IconButton(
          tooltip: 'Open menu',
          onPressed: () => Scaffold.of(context).openDrawer(),
          icon: const Icon(Icons.menu),
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Search community',
          icon: const Icon(Icons.search),
          onPressed: () =>
              pushPage<void>(context, BackendScope.of(context)?.social == null
                  ? CommunitySearchPage(session: _session)
                  : const PeoplePage()),
        ),
        IconButton(
          tooltip: 'Notifications',
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => pushPage<void>(context, const NotificationsPage()),
        ),
      ],
    ),
    drawer: Drawer(
      backgroundColor: NightTheme.background,
      width: MediaQuery.sizeOf(context).width.clamp(280, 350).toDouble() * 0.92,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Align(alignment: Alignment.centerLeft, child: Brand()),
                ),
                IconButton(
                  tooltip: 'Close menu',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF352650),
                child: Icon(Icons.person_outline, color: NightTheme.cyan),
              ),
              title: Text(
                BackendScope.of(context)?.account?.displayName ??
                    'Car enthusiast',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                BackendScope.of(context)?.account == null
                    ? 'Browse as guest'
                    : 'Signed in',
              ),
            ),
            const SizedBox(height: 12),
            for (final item in const [
              (0, 'Home', Icons.home_outlined),
              (1, 'Messages', Icons.forum_outlined),
              (3, 'Marketplace', Icons.storefront_outlined),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: _selected == item.$1
                        ? const LinearGradient(
                            colors: [Color(0xFF243B89), Color(0xFF43204C)],
                          )
                        : null,
                  ),
                  child: ListTile(
                    leading: Icon(
                      item.$3,
                      color: _selected == item.$1
                          ? NightTheme.cyan
                          : NightTheme.muted,
                    ),
                    title: Text(item.$2),
                    selected: _selected == item.$1,
                    selectedColor: Colors.white,
                    onTap: () {
                      Navigator.pop(context);
                      _select(item.$1);
                    },
                  ),
                ),
              ),
            ListTile(
              leading: const Icon(Icons.bookmark_border),
              title: const Text('Saved'),
              onTap: () => _openDrawerPage(SavedPage(session: _session)),
            ),
            ListTile(
              leading: const Icon(Icons.workspace_premium_outlined),
              title: const Text('Plan'),
              onTap: () => _openDrawerPage(const PlanPage()),
            ),
            ListTile(
              leading: const Icon(Icons.article_outlined),
              title: const Text('Blog'),
              onTap: () => _openDrawerPage(const BlogPage()),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              onTap: () => _openDrawerPage(const AboutPage()),
            ),
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('Contact'),
              onTap: () => _openDrawerPage(const ContactPage()),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () => _openDrawerPage(SettingsPage(session: _session)),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Back to welcome'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            const InfoNote(
              'Sample marketplace offers and saved items are for preview.',
            ),
          ],
        ),
      ),
    ),
    body: SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          // A tab is constructed only on first visit, then retains scroll/form state.
          child: IndexedStack(
            index: _selected,
            children: List.generate(
              5,
              (index) => _pages[index] ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _selected,
      onDestinationSelected: _select,
      destinations: const [
        NavigationDestination(
          key: ValueKey('nav-home'),
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          key: ValueKey('nav-messages'),
          icon: Icon(Icons.forum_outlined),
          selectedIcon: Icon(Icons.forum),
          label: 'Messages',
        ),
        NavigationDestination(
          key: ValueKey('nav-create'),
          icon: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: NightTheme.gradient,
            ),
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.add, color: Colors.white),
            ),
          ),
          label: 'Create',
        ),
        NavigationDestination(
          key: ValueKey('nav-marketplace'),
          icon: Icon(Icons.storefront_outlined),
          selectedIcon: Icon(Icons.storefront),
          label: 'Marketplace',
        ),
        NavigationDestination(
          key: ValueKey('nav-profile'),
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    ),
  );
}
