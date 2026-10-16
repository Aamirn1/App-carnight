import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cars_night/backend/session.dart';
import 'package:cars_night/backend/repositories.dart';
import 'package:cars_night/backend/social.dart';
import 'package:cars_night/core/theme.dart';
import 'package:cars_night/ui/notifications.dart';
import 'backend_test.dart' as fixtures;

class ActivityApi implements SocialRepository {
 bool fail=false;final marked=<String>[];
 @override Future<void> ensureProfile(String name)async{}
 @override Future<List<Map<String,dynamic>>> activity()async {
  if(fail)throw StateError('network unavailable');
  return [{'event_key':'comment:event','kind':'comment','actor_id':'other','display_name':'Driver','post_id':'post','conversation_id':null,'created_at':'2026-10-16T00:00:00Z','is_read':false}];
 }
 @override Future<void> readActivity(List<String> keys)async {marked.addAll(keys);}
 @override dynamic noSuchMethod(Invocation invocation)=>throw UnimplementedError();
}
void main(){
 testWidgets('guest notifications request sign in without invented activity',(tester)async{
  await tester.pumpWidget(MaterialApp(home:const ActivityPage()));await tester.pumpAndSettle();
  expect(find.text('Sign in'),findsOneWidget);expect(find.textContaining('Driver'),findsNothing);
 });
 for(final dark in [false,true]){
  testWidgets('activity read states, retry and signout in ${dark?'dark':'light'} theme',(tester)async{
   final accounts=fixtures.FakeAccounts();accounts.restored.complete(const AccountSummary(id:fixtures.owner,displayName:'Owner'));
   final api=ActivityApi();final backend=BackendSession(accounts:accounts,drafts:fixtures.FakeDrafts(),social:api);
   tester.view.physicalSize=const Size(320,800);tester.view.devicePixelRatio=1;
   addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
   await tester.pumpWidget(BackendScope(session:backend,child:MaterialApp(theme:dark?NightTheme.data:NightTheme.light,home:MediaQuery(data:const MediaQueryData(size:Size(320,800),textScaler:TextScaler.linear(1.6)),child:const ActivityPage()))));
   await tester.pumpAndSettle();
   await tester.ensureVisible(find.text('Mark displayed activity as read'));await tester.tap(find.text('Mark displayed activity as read'));await tester.pumpAndSettle();
   expect(api.marked,['comment:event']);
   api.fail=true;await tester.tap(find.byTooltip('Refresh notifications'));await tester.pumpAndSettle();
   expect(find.textContaining('Driver commented'),findsNothing);
   api.fail=false;await tester.tap(find.byTooltip('Refresh notifications'));await tester.pumpAndSettle();
   expect(find.textContaining('Driver commented'),findsOneWidget);
   accounts.changes.add(null);await tester.pumpAndSettle();expect(find.textContaining('Driver commented'),findsNothing);expect(tester.takeException(),isNull);
   await tester.pumpWidget(const SizedBox());backend.dispose();await accounts.dispose();
  });
 }
}
