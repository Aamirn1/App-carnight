import 'package:flutter_test/flutter_test.dart';
import 'package:cars_night/core/assets.dart';
import 'package:cars_night/core/session.dart';
import 'package:cars_night/data/demo_catalog.dart';
import 'package:cars_night/domain/models.dart';
import 'package:cars_night/ui/marketplace.dart';

void main() {
  test(
    'calendar-day calculation crosses month boundaries without rounding',
    () {
      final period = RentalPeriod(
        DateTime(2026, 10, 31, 23),
        DateTime(2026, 11, 2, 1),
      );
      expect(period.days, 2);
      expect(period.estimateMinor(45000), 90000);
    },
  );
  test('zero-day and reversed rental ranges are rejected', () {
    expect(
      () => RentalPeriod(DateTime(2026, 10, 2), DateTime(2026, 10, 2)),
      throwsArgumentError,
    );
    expect(
      () => RentalPeriod(DateTime(2026, 10, 3), DateTime(2026, 10, 2)),
      throwsArgumentError,
    );
  });
  test('rental location filter is independent of model query', () {
    expect(
      filterListings(
        DemoCatalog.listings,
        kind: ListingKind.rental,
        city: '  DUBAI ',
        query: 'range',
      ).single.id,
      'rent-2',
    );
    expect(
      filterListings(
        DemoCatalog.listings,
        kind: ListingKind.rental,
        city: 'London',
      ),
      isEmpty,
    );
  });
  test('demo money retains cents rather than rounding away value', () {
    expect(formatDemoMoney(123456, 'USD'), 'USD 1,234.56');
    expect(formatDemoMoney(45000, 'USD'), 'USD 450');
    expect(formatDemoMoney(5, 'USD'), 'USD 0.05');
  });
  test('local post captures a copy of the selected media', () {
    final session = DemoSession();
    addTearDown(session.dispose);
    final selected = [NightAssets.hero];
    final post = session.addDemoPost('  New drive  ', selected);
    selected.clear();
    expect(post.caption, 'New drive');
    expect(post.imageAssets, [NightAssets.hero]);
    expect(session.posts.first.id, post.id);
  });
  test(
    'composer rejects empty caption, missing images and non-image inputs',
    () {
      final session = DemoSession();
      addTearDown(session.dispose);
      expect(
        () => session.addDemoPost('  ', [NightAssets.hero]),
        throwsArgumentError,
      );
      expect(() => session.addDemoPost('A drive', []), throwsArgumentError);
      expect(
        () => session.addDemoPost('A drive', ['video.mp4']),
        throwsArgumentError,
      );
      expect(
        () => session.addDemoPost('A drive', List.filled(5, NightAssets.hero)),
        throwsArgumentError,
      );
    },
  );
  test('deleting a local post removes its reactions, saves and comments', () {
    final session = DemoSession();
    addTearDown(session.dispose);
    final post = session.addDemoPost('A drive', [NightAssets.hero]);
    session.toggleSaved(post.id);
    session.toggleLiked(post.id);
    session.addComment(post.id, '  Nice car  ');
    expect(session.commentsFor(post.id), ['Nice car']);
    session.removeDemoPost(post.id);
    expect(session.posts.any((p) => p.id == post.id), isFalse);
    expect(session.isSaved(post.id), isFalse);
    expect(session.isLiked(post.id), isFalse);
    expect(session.commentsFor(post.id), isEmpty);
  });
  test('comments require existing posts and nonempty content', () {
    final session = DemoSession();
    addTearDown(session.dispose);
    expect(() => session.addComment('missing', 'Hello'), throwsArgumentError);
    expect(() => session.addComment('post-1', '   '), throwsArgumentError);
  });
}
