import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:cars_night/data/photo_draft.dart';

void main() {
  late Directory directory;
  late PhotoDraftStore store;
  final photo = Uint8List.fromList([255, 216, 255, 0]);
  PhotoDraft draft({bool attempted = false, String caption = 'Night drive'}) => PhotoDraft(
    requestId: '12345678-1234-4234-8234-123456789abc', caption: caption,
    photo: photo, attempted: attempted);
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('cars-night-draft-test');
    store = PhotoDraftStore(directory);
  });
  tearDown(() async => directory.delete(recursive: true));
  test('restart restores exact payload and attempted retry ID', () async {
    await store.save('owner-a', draft(attempted: true));
    final restored = await PhotoDraftStore(directory).read('owner-a');
    expect(restored!.requestId, draft().requestId);
    expect(restored.caption, 'Night drive');
    expect(restored.photo, photo);
    expect(restored.attempted, isTrue);
  });
  test('accounts cannot restore or delete each other drafts', () async {
    await store.save('owner-a', draft());
    expect(await store.read('owner-b'), isNull);
    await store.clear('owner-b');
    expect(await store.read('owner-a'), isNotNull);
    expect(() => store.read('../owner-a'), throwsFormatException);
  });
  test('replacement and discard remove completed draft', () async {
    await store.save('owner-a', draft());
    await store.save('owner-a', draft(caption: 'Updated'));
    expect((await store.read('owner-a'))!.caption, 'Updated');
    await store.clear('owner-a');
    expect(await store.read('owner-a'), isNull);
  });
  test('invalid data does not overwrite a good saved draft', () async {
    await store.save('owner-a', draft());
    await expectLater(store.save('owner-a', PhotoDraft(requestId: draft().requestId,
      caption: 'bad', photo: Uint8List(2 * 1024 * 1024 + 1))), throwsFormatException);
    expect((await store.read('owner-a'))!.caption, 'Night drive');
  });
  test('corrupt saved data is reported and preserved', () async {
    final file = File('${directory.path}/photo-owner-a.json');
    await file.writeAsString('broken');
    await expectLater(store.read('owner-a'), throwsFormatException);
    expect(await file.readAsString(), 'broken');
  });
}
