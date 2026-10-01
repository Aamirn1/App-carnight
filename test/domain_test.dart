import 'package:flutter_test/flutter_test.dart';
import 'package:cars_night/core/session.dart';
import 'package:cars_night/data/demo_catalog.dart';
import 'package:cars_night/domain/models.dart';

void main() {
  test('rental search cannot return a sale listing', () {
    final results = filterListings(
      DemoCatalog.listings,
      kind: ListingKind.rental,
      query: '  DUBAI ',
      category: 'SUV',
    );
    expect(results.map((car) => car.id), ['rent-2']);
  });
  test('unknown query returns no results', () {
    expect(
      filterListings(
        DemoCatalog.listings,
        kind: ListingKind.sale,
        query: 'no-such-car',
      ),
      isEmpty,
    );
  });
  test('video and invalid sizes/counts are rejected by client policy', () {
    expect(
      UploadPolicy.validate(mimeType: 'video/mp4', bytes: 100, imageCount: 1),
      isNotNull,
    );
    for (final bytes in [0, -1, UploadPolicy.maxInputBytes + 1]) {
      expect(
        UploadPolicy.validate(
          mimeType: 'image/jpeg',
          bytes: bytes,
          imageCount: 1,
        ),
        isNotNull,
      );
    }
    for (final count in [0, 5]) {
      expect(
        UploadPolicy.validate(
          mimeType: 'image/jpeg',
          bytes: 100,
          imageCount: count,
        ),
        isNotNull,
      );
    }
    expect(
      UploadPolicy.validate(
        mimeType: 'image/jpeg',
        bytes: UploadPolicy.maxInputBytes,
        imageCount: 4,
      ),
      isNull,
    );
  });
  test('likes and saved items toggle independently', () {
    final session = DemoSession();
    addTearDown(session.dispose);
    session.toggleLiked('post-1');
    session.toggleSaved('post-1');
    session.toggleSaved('post-1');
    expect(session.isLiked('post-1'), isTrue);
    expect(session.savedCount, 0);
  });
}
