import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui/photo_compose.dart';
import 'core/assets.dart';
import 'core/session.dart';
import 'core/theme.dart';
import 'core/appearance.dart';
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
  const CarsNightApp({super.key, this.backend, this.startupError, this.appearance});
  final Appearance? appearance;
  final BackendSession? backend;
  final String? startupError;
  @override
  Widget build(BuildContext context) => BackendScope(
    session: backend,
    child: appearance == null ? _SessionApp(startupError: startupError) : AppearanceScope(controller: appearance!, child: _SessionApp(startupError: startupError)),
  );
}

class _SessionApp extends StatelessWidget {
  const _SessionApp({this.startupError});
  final String? startupError;
  @override
  Widget build(BuildContext context) {
    final backend = BackendScope.of(context);
    final restoring = backend?.initializing == true;
    final recovery = backend?.recovering == true;
    final id = backend?.account?.id;
    final verified = backend?.emailVerifiedNotice == true;
    return MaterialApp(
      // Recreate the navigation stack only on identity/recovery transitions.
      // Token refreshes keep the same key and do not reset pages.
      key: ValueKey('session:$restoring:$recovery:$verified:${id ?? 'guest'}'),
      title: 'Cars Night',
      debugShowCheckedModeBanner: false,
      theme: NightTheme.light,
      darkTheme: NightTheme.data,
      themeMode: AppearanceScope.of(context)?.mode ?? ThemeMode.dark,
      home: restoring
          ? Scaffold(body: Center(child: CircularProgressIndicator()))
          : recovery
          ? AuthPage(mode: AuthMode.updatePassword)
          : id != null && verified
          ? PageFrame(
              title: 'Account verified',
              children: [
                SizedBox(height: 40),
                Icon(
                  Icons.verified_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 64,
                ),
                SizedBox(height: 24),
                Text(
                  'Welcome to Cars Night',
                  style: TextStyle(fontSize: 24, color: NightTheme.ink(context)),
                ),
                SizedBox(height: 16),
                Text('Your email is verified and you are signed in.'),
                SizedBox(height: 24),
                GradientButton(
                  label: 'Continue to Home',
                  onPressed: backend!.dismissEmailVerified,
                ),
              ],
            )
          : id != null
          ? AppShell()
          : WelcomePage(startupError: startupError),
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key, this.startupError});
  final String? startupError;
  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
    child: Scaffold(
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    children: [
                      AssetPhoto(
                        asset: NightAssets.hero,
                        ratio: 0.95,
                        label: 'Blue sports car against a neon city skyline',
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.transparent,
                                NightTheme.canvas(context),
                              ],
                              stops: [0, 0.62, 1],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Center(child: Brand(large: true)),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: Column(
                      children: [
                        Text(
                          'The community for\ncar lovers',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 16),
                        if (startupError != null) InfoNote(startupError!),
                        Text(
                          'Share. Connect. Discover.',
                          style: TextStyle(color: NightTheme.secondaryText(context)),
                        ),
                        SizedBox(height: 28),
                        GradientButton(
                          label: 'Get Started',
                          onPressed: () =>
                              pushPage<void>(context, AppShell()),
                        ),
                        SizedBox(height: 12),
                        GradientOutlineButton(
                          onPressed: () =>
                              pushPage<void>(context, AuthPage()),
                          label: 'Sign in',
                        ),
                        SizedBox(height: 16),
                        Text(
                          'SAMPLE FEED · PREVIEW BUILD',
                          style: TextStyle(
                            color: NightTheme.secondaryText(context),
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
          await pushPage<void>(context, AuthPage());
        } else {
          final posted = await pushPage<bool>(
            context,
            PhotoComposePage(ownerId: account.id),
          );
          if (mounted && posted == true) {
            setState(() {
              _pages[0] = CommunityPage(key: UniqueKey(), demo: _session);
              _selected = 0;
            });
          }
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
        SnackBar(
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
          1 => MessagesPage(),
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
      title: Brand(),
      toolbarHeight: 64,
      leading: Builder(
        builder: (context) => IconButton(
          tooltip: 'Open menu',
          onPressed: () => Scaffold.of(context).openDrawer(),
          icon: Icon(Icons.menu),
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Search community',
          icon: Icon(Icons.search),
          onPressed: () => pushPage<void>(
            context,
            BackendScope.of(context)?.social == null
                ? CommunitySearchPage(session: _session)
                : PeoplePage(),
          ),
        ),
        IconButton(
          tooltip: 'Notifications',
          icon: Icon(Icons.notifications_outlined),
          onPressed: () => pushPage<void>(context, NotificationsPage()),
        ),
      ],
    ),
    drawer: Drawer(
      backgroundColor: NightTheme.canvas(context),
      width: MediaQuery.sizeOf(context).width.clamp(280, 350).toDouble() * 0.92,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Align(alignment: Alignment.centerLeft, child: Brand()),
                ),
                IconButton(
                  tooltip: 'Close menu',
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Color(0xFF352650),
                child: Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary),
              ),
              title: Text(
                BackendScope.of(context)?.account?.displayName ??
                    'Car enthusiast',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                BackendScope.of(context)?.account == null
                    ? 'Browse as guest'
                    : 'Signed in',
              ),
            ),
            SizedBox(height: 12),
            for (final item in [
              (0, 'Home', Icons.home_outlined),
              (1, 'Messages', Icons.forum_outlined),
              (3, 'Marketplace', Icons.storefront_outlined),
            ])
              Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: _selected == item.$1
                        ? LinearGradient(
                            colors: [Color(0xFF243B89), Color(0xFF43204C)],
                          )
                        : null,
                  ),
                  child: ListTile(
                    leading: Icon(
                      item.$3,
                      color: _selected == item.$1
                          ? Theme.of(context).colorScheme.primary
                          : NightTheme.secondaryText(context),
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
              leading: Icon(Icons.bookmark_border),
              title: Text('Saved'),
              onTap: () => _openDrawerPage(SavedPage(session: _session)),
            ),
            ListTile(
              leading: Icon(Icons.workspace_premium_outlined),
              title: Text('Plan'),
              onTap: () => _openDrawerPage(PlanPage()),
            ),
            ListTile(
              leading: Icon(Icons.article_outlined),
              title: Text('Blog'),
              onTap: () => _openDrawerPage(BlogPage()),
            ),
            ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('About'),
              onTap: () => _openDrawerPage(AboutPage()),
            ),
            ListTile(
              leading: Icon(Icons.mail_outline),
              title: Text('Contact'),
              onTap: () => _openDrawerPage(ContactPage()),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),
            ListTile(
              leading: Icon(Icons.settings_outlined),
              title: Text('Settings'),
              onTap: () => _openDrawerPage(SettingsPage(session: _session)),
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Back to welcome'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            InfoNote(
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
          constraints: BoxConstraints(maxWidth: 640),
          // A tab is constructed only on first visit, then retains scroll/form state.
          child: IndexedStack(
            index: _selected,
            children: List.generate(
              5,
              (index) => _pages[index] ?? SizedBox.shrink(),
            ),
          ),
        ),
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _selected,
      onDestinationSelected: _select,
      destinations: [
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
          label: 'Market',
          tooltip: 'Marketplace — Buy and Rent',
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
