import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cars_night/backend/social.dart';
import 'package:cars_night/core/theme.dart';
import 'package:cars_night/data/account_cleanup.dart';
import 'package:cars_night/ui/public_profile.dart';
import 'package:cars_night/ui/delete_account.dart';

class CommunityApi implements SocialRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
  bool following = false;
  int deletionCalls = 0;
  @override
  String get me => '11111111-1111-1111-1111-111111111111';
  @override
  Future<Map<String,dynamic>> profile(String id) async => {'id':id,'display_name':'Night Driver','bio':'Public car story','city':'Dubai','dream_car':'M4','followers':following?1:0,'following':0,'posts':0,'is_following':following};
  @override
  Future<List<CommunityPost>> collection({String? author,bool saved=false,CommunityPost? before}) async => [];
  @override
  Future<void> follow(String person,bool value) async {following=value;}
  @override
  Future<void> deleteAccount(String password) async {deletionCalls++;throw const AuthException('Wrong password',code:'invalid_credentials');}
}
void main() {
  test('legacy posts fall back to their original image; new posts use thumbnails', () {
    final data=<String,dynamic>{'id':'post','owner_id':'owner','caption':'Photo','display_name':'Driver','created_at':'2026-10-13','like_count':0,'comment_count':0,'liked':false,'following':false,'images':['owner/full.jpg']};
    expect(CommunityPost.fromJson(data).thumbnails,['owner/full.jpg']);
    final current=CommunityPost.fromJson({...data,'thumbnails':['owner/feed_thumb.jpg'],'saved':true});
    expect(current.thumbnails,['owner/feed_thumb.jpg']);expect(current.saved,true);
  });
  testWidgets('member profile displays real fields and updates follow state', (tester) async {
    final api=CommunityApi();
    await tester.pumpWidget(MaterialApp(theme:NightTheme.light,home:PublicProfilePage(api:api,user:'22222222-2222-2222-2222-222222222222')));
    await tester.pumpAndSettle();
    expect(find.text('Night Driver'),findsOneWidget);expect(find.text('Public car story'),findsOneWidget);
    await tester.tap(find.text('Follow'));await tester.pumpAndSettle();
    expect(find.text('Following'),findsOneWidget);expect(find.text('1 followers · 0 following · 0 posts'),findsOneWidget);
  });
  testWidgets('empty online saved collection is not replaced by sample posts', (tester) async {
    final api=CommunityApi();
    await tester.pumpWidget(MaterialApp(home:OnlineSavedPage(api:api)));await tester.pumpAndSettle();
    expect(find.text('Save a post from Home to find it here.'),findsOneWidget);
    expect(find.text('Alex Carter'),findsNothing);
  });
  testWidgets('account deletion needs confirmation and password; invalid password is shown', (tester) async {
    final api=CommunityApi();
    await tester.pumpWidget(MaterialApp(home:DeleteAccountPage(api:api)));await tester.pumpAndSettle();
    final button=find.widgetWithText(FilledButton,'Permanently delete app account');
    expect(tester.widget<FilledButton>(button).onPressed,isNull);
    await tester.tap(find.byType(Checkbox));await tester.pumpAndSettle();
    await tester.tap(button);await tester.pumpAndSettle();expect(api.deletionCalls,0);
    await tester.enterText(find.byType(TextField),'wrong');await tester.tap(button);await tester.pumpAndSettle();
    expect(api.deletionCalls,1);expect(find.text('Email or password is incorrect.'),findsOneWidget);
    expect(find.textContaining('website'),findsOneWidget);
  });
  test('confirmed deletion cleanup remains journaled if device cleanup fails', () async {
    SharedPreferences.setMockInitialValues({});
    await AccountCleanup.mark('11111111-1111-1111-1111-111111111111');
    await expectLater(AccountCleanup.retry(clearCache:()async{}),throwsA(anything));
    final prefs=await SharedPreferences.getInstance();
    expect(prefs.getStringList(AccountCleanup.key),['11111111-1111-1111-1111-111111111111']);
  });
}
