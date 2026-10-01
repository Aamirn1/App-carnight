import 'package:flutter/material.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../data/demo_catalog.dart';
import 'auth.dart';
import 'components.dart';
import 'feed.dart';
import 'marketplace.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.session});
  final DemoSession session;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final ownPosts =
            session.posts.where((post) => post.author == 'You').toList();
        return ListView(padding: const EdgeInsets.all(20), children: [
          const Center(
              child: CircleAvatar(
                  radius: 38,
                  backgroundColor: Color(0xFF352650),
                  child: Icon(Icons.person_outline,
                      size: 38, color: NightTheme.cyan))),
          const SizedBox(height: 12),
          Text('Your garage',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          const Text('Guest preview',
              textAlign: TextAlign.center,
              style: TextStyle(color: NightTheme.muted)),
          const SizedBox(height: 20),
          NightCard(
              child: Column(children: [
            ListTile(
                leading:
                    const Icon(Icons.bookmark_border, color: NightTheme.cyan),
                title: const Text('Saved collection'),
                subtitle: Text('${session.savedCount} items'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    pushPage<void>(context, SavedPage(session: session))),
            const Divider(height: 1),
            ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Sign in or join'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => pushPage<void>(context, const AuthPage())),
          ])),
          const SizedBox(height: 24),
          Text('Your demo posts',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (ownPosts.isEmpty)
            const EmptyState(
                title: 'Your story starts here',
                message: 'Use Create to add a sample image post.',
                icon: Icons.add_photo_alternate_outlined),
          for (final post in ownPosts)
            Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PostCard(post: post, session: session)),
          const InfoNote(
              'All demo changes reset when you exit. No public profile exists yet.'),
        ]);
      });
}

class SavedPage extends StatelessWidget {
  const SavedPage({super.key, required this.session});
  final DemoSession session;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final cars = DemoCatalog.listings
            .where((car) => session.isSaved(car.id))
            .toList();
        final posts =
            session.posts.where((post) => session.isSaved(post.id)).toList();
        return PageFrame(title: 'Saved collection', children: [
          if (cars.isEmpty && posts.isEmpty)
            const EmptyState(
                title: 'Keep your favorites close',
                message: 'Save cars and posts to find them here.',
                icon: Icons.bookmark_border),
          if (cars.isNotEmpty) ...[
            Text('Cars', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final car in cars)
              Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child:
                      ListingCard(car: car, session: session, compact: true)),
          ],
          if (posts.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Posts', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final post in posts)
              Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: PostCard(post: post, session: session)),
          ],
        ]);
      });
}
