import 'package:flutter/material.dart';
import '../core/assets.dart';
import '../core/session.dart';
import '../core/theme.dart';
import 'components.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.session});
  final DemoSession session;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (context, _) => PageFrame(
      title: 'Settings',
      children: [
        NightCard(
          child: SwitchListTile(
            value: session.dataSaver,
            onChanged: session.setDataSaver,
            title: const Text('Lower-detail images'),
            subtitle: const Text(
              'Reduce image decoding memory in this preview.',
            ),
          ),
        ),
        const InfoNote(
          'Images are bundled locally. This switch does not change network usage '
          'or file size. The preference lasts for this demo session.',
        ),
        const SizedBox(height: 12),
        NightCard(
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.language),
                title: Text('Language'),
                subtitle: Text('English · additional languages planned'),
              ),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Notifications'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => pushPage<void>(context, const NotificationsPage()),
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showUnavailable(
                  context,
                  'Privacy in this preview',
                  'There is no connected backend, analytics service or public account. '
                      'The production privacy policy will be provided before sign-up launches.',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person_remove_outlined),
                title: const Text('Delete account'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showUnavailable(
                  context,
                  'No account to delete',
                  'You are viewing a guest demo. Account and image deletion will be '
                      'implemented together with authentication.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Cars Night · Community preview 0.4.0',
          style: TextStyle(color: NightTheme.muted),
        ),
      ],
    ),
  );
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context) => const PageFrame(
    title: 'Notifications',
    children: [
      EmptyState(
        title: 'No demo notifications',
        message:
            'Replies, activity and listing '
            'updates will appear here once notifications are connected.',
        icon: Icons.notifications_none,
      ),
    ],
  );
}

class PlanPage extends StatelessWidget {
  const PlanPage({super.key});
  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Your plan',
    children: [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF243566), Color(0xFF47224E)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.workspace_premium_outlined,
              size: 40,
              color: NightTheme.magenta,
            ),
            const SizedBox(height: 16),
            Text(
              'A bigger garage.\nMore possibilities.',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'Premium is planned. Pricing and benefits are not yet available.',
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const NightCard(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Explore the essentials',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 12),
            Text(
              '• Discover image posts\n• Browse sale and rental listings\n• Save your favorites',
            ),
          ],
        ),
      ),
      const InfoNote(
        'No paid plan is active in this demo. No payment will be requested or collected.',
      ),
    ],
  );
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'About Cars Night',
    children: [
      const Center(child: Brand(large: true)),
      const SizedBox(height: 16),
      Text(
        'Car lovers. Real connections.',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 12),
      const Text(
        'A place to share your car stories and discover your next drive. '
        'Cars Night brings community, buying and renting into one experience.',
      ),
      const SizedBox(height: 24),
      const NightCard(
        padding: EdgeInsets.all(18),
        child: Text(
          'Built around images\n\nThe first release focuses on photo posts and car listings. '
          'Video, reels and livestreaming are outside the launch scope.',
        ),
      ),
      const InfoNote(
        'Development preview. Marketplace offers and the sample feed are illustrative. '
        'Public photo posting is not enabled yet.',
      ),
    ],
  );
}

const _articles = [
  (
    'A community built around the drive',
    'Cars Night is designed around photographs '
        'and conversations: the car you love, the road you remember and the details '
        'that make every journey yours.\n\nThis demo lets you explore image posts, '
        'local comments and saved collections. Public posting arrives with the connected service.',
  ),
  (
    'Find your next car, your way',
    'The marketplace separates cars for sale from '
        'rental listings. Search by a make, model or city and narrow results by category.\n\n'
        'Rental dates in this prototype demonstrate a base-price estimate. Actual '
        'availability, seller contact and rental terms are not connected yet.',
  ),
];

class BlogPage extends StatelessWidget {
  const BlogPage({super.key});
  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'The night journal',
    children: [
      const InfoNote('Sample editorial content for reviewing article layouts.'),
      for (var index = 0; index < _articles.length; index++)
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: NightCard(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => pushPage<void>(
                  context,
                  PageFrame(
                    title: 'Journal',
                    children: [
                      AssetPhoto(
                        asset: index == 0
                            ? NightAssets.hero
                            : NightAssets.violet,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _articles[index].$1,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _articles[index].$2,
                        style: const TextStyle(height: 1.7),
                      ),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AssetPhoto(
                      asset: index == 0 ? NightAssets.hero : NightAssets.violet,
                      ratio: 2,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _articles[index].$1,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});
  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _form = GlobalKey<FormState>();
  final _message = TextEditingController();
  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Contact',
    children: [
      Text(
        'Let’s talk cars.',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 12),
      const Text(
        'Questions, ideas or feedback? This is where you’ll reach our team.',
      ),
      const InfoNote(
        'Contact delivery is not connected. Do not enter private information '
        'in this sample form. No message will be sent.',
      ),
      Form(
        key: _form,
        child: TextFormField(
          controller: _message,
          minLines: 4,
          maxLines: 8,
          maxLength: 1000,
          decoration: const InputDecoration(labelText: 'Your message'),
          validator: (v) =>
              (v ?? '').trim().isEmpty ? 'Write a message first.' : null,
        ),
      ),
      const SizedBox(height: 16),
      GradientButton(
        label: 'Send message',
        onPressed: () {
          if (!_form.currentState!.validate()) return;
          showUnavailable(
            context,
            'Message not sent',
            'The contact service is not connected. Your message has not been submitted.',
          );
        },
      ),
    ],
  );
}
