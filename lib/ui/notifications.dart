import 'package:flutter/material.dart';
import '../backend/session.dart';
import '../backend/social.dart';
import '../backend/supabase_repositories.dart';
import 'auth.dart';
import 'components.dart';
import 'community.dart';
import 'messages.dart';
import 'public_profile.dart';

String activityLabel(String kind)=>switch(kind){
 'like'=>'liked your photo', 'comment'=>'commented on your photo', 'follow'=>'started following you',
 'request'=>'sent a conversation request', 'message'=>'sent you a message', _=>'new activity',
};
class ActivityPage extends StatelessWidget {
 const ActivityPage({super.key});
 @override Widget build(BuildContext context){
  final backend=BackendScope.of(context);
  if(backend?.account==null||backend?.social==null)return PageFrame(title:'Notifications',children:[const EmptyState(title:'Your car community activity',message:'Sign in to see replies, likes, follows and conversation activity.',icon:Icons.notifications_none),GradientButton(label:'Sign in',onPressed:()=>pushPage<void>(context,const AuthPage()))]);
  return MemberActivity(key:ValueKey(backend!.account!.id),api:backend.social!,owner:backend.account!.id);
 }
}
class MemberActivity extends StatefulWidget {
 const MemberActivity({super.key,required this.api,required this.owner});
 final SocialRepository api; final String owner;
 @override State<MemberActivity> createState()=>_MemberActivityState();
}
class _MemberActivityState extends State<MemberActivity> with WidgetsBindingObserver {
 List<Map<String,dynamic>> _rows=[];
 bool _busy=false;String? _error;
 @override void initState(){super.initState();WidgetsBinding.instance.addObserver(this);_load();}
 @override void dispose(){WidgetsBinding.instance.removeObserver(this);super.dispose();}
 @override void didChangeAppLifecycleState(AppLifecycleState state){if(state==AppLifecycleState.resumed)_load();}
 bool get _sameAccount=>BackendScope.of(context)?.account?.id==widget.owner;
 Future<void> _load() async {
  if(_busy)return;setState((){_busy=true;_error=null;});
  try{final rows=await widget.api.activity();if(mounted&&_sameAccount)setState(()=>_rows=rows);}
  catch(e){if(mounted)setState((){_error=serviceError(e);_rows=[];});}
  finally{if(mounted)setState(()=>_busy=false);}
 }
 Future<void> _read(List<Map<String,dynamic>> rows) async {
  await widget.api.readActivity(rows.map((r)=>r['event_key'] as String).toList());
  if(mounted&&_sameAccount)setState((){for(final row in rows){row['is_read']=true;}});
 }
 Future<void> _open(Map<String,dynamic> row)async{
  if(_busy||!_sameAccount)return;setState(()=>_busy=true);
  try{
   await _read([row]);if(!mounted||!_sameAccount)return;
   if(row['conversation_id']!=null){
    final chat=await widget.api.conversation(row['conversation_id'] as String);
    if(!mounted||!_sameAccount)return;
    await pushPage<void>(context,ConversationPage(conversation:chat,name:row['display_name'] as String,owner:widget.owner));
   }else if(row['post_id']!=null){
    final post=await widget.api.activityPost(row['post_id'] as String);
    if(!mounted||!_sameAccount)return;
    await pushPage<void>(context,CommentsPage(post:post));
   }else{await pushPage<void>(context,PublicProfilePage(api:widget.api,user:row['actor_id'] as String));}
  }catch(e){if(mounted)setState(()=>_error=serviceError(e));}
  finally{if(mounted)setState(()=>_busy=false);}
 }
 @override Widget build(BuildContext context)=>Scaffold(
  appBar:AppBar(title:const Text('Notifications'),actions:[IconButton(tooltip:'Refresh notifications',onPressed:_busy?null:_load,icon:const Icon(Icons.refresh))]),
  body:RefreshIndicator(onRefresh:_load,child:ListView(padding:const EdgeInsets.all(16),children:[
   const Text('Recent activity',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
   const SizedBox(height:6),const Text('Latest 30 activities from the past 30 days. Pull to refresh.'),
   const InfoNote('These are in-app notifications. Background phone alerts are not enabled in this build.'),
   if(_busy)const LinearProgressIndicator(),if(_error!=null)InfoNote(_error!),
   if(_rows.any((r)=>r['is_read']!=true))TextButton(onPressed:_busy?null:()async{setState(()=>_busy=true);try{await _read(_rows);}catch(e){if(mounted)setState(()=>_error=serviceError(e));}finally{if(mounted)setState(()=>_busy=false);}},child:const Text('Mark displayed activity as read')),
   if(_rows.isEmpty&&!_busy&&_error==null)const EmptyState(title:'You’re all caught up',message:'New activity from your car community will appear here.',icon:Icons.notifications_none),
   for(final row in _rows)ListTile(contentPadding:const EdgeInsets.symmetric(vertical:8,horizontal:4),
    leading:Icon(row['is_read']==true?Icons.notifications_none:Icons.notifications_active_outlined),
    title:Text('${row['display_name']} ${activityLabel(row['kind'] as String)}',style:TextStyle(fontWeight:row['is_read']==true?FontWeight.normal:FontWeight.bold)),
    subtitle:Text((DateTime.tryParse(row['created_at'] as String)?.toLocal().toString()??'').split('.').first),
    trailing:const Icon(Icons.chevron_right),onTap:_busy?null:()=>_open(row)),
  ])),
 );
}
