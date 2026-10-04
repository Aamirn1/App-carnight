import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/assets.dart';
import '../core/session.dart';
import '../data/demo_catalog.dart';
import '../backend/session.dart';
import 'account.dart';
import 'auth.dart';
import 'compose.dart';
import 'photo_compose.dart';
import 'information.dart';
import 'messages.dart';
import 'components.dart';
import 'feed.dart';
import 'marketplace.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.session});
  final DemoSession session;
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _owner, _error;
  bool _initialized = false, _loading = false, _more = false;
  int _tab = 0;
  int? _followers, _following, _total;
  final List<Map<String, dynamic>> _posts = [];
  Map<String, dynamic> _preview = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final owner = BackendScope.of(context)?.account?.id;
    if (!_initialized || owner != _owner) {
      _initialized = true; _owner = owner;
      _posts.clear(); _followers = null; _following = null; _total = null;
      if (owner != null) _load();
    }
  }

  Future<void> _load({bool more = false}) async {
    final api = BackendScope.of(context)?.social;
    final owner = _owner;
    if (api == null || owner == null || _loading) return;
    setState(() { _loading = true; _error = null; });
    try {
      final rows = await api.client.from('cn_posts')
        .select('id,caption,created_at,cn_post_media(storage_path,position)')
        .eq('owner_id', owner).eq('status','published')
        .order('created_at', ascending: false).order('id', ascending: false)
        .range(more ? _posts.length : 0, (more ? _posts.length : 0) + 19);
      final counts = await Future.wait([
        api.client.from('cn_follows').count(CountOption.exact).eq('followed_id',owner),
        api.client.from('cn_follows').count(CountOption.exact).eq('follower_id',owner),
        api.client.from('cn_posts').count(CountOption.exact).eq('owner_id',owner).eq('status','published'),
      ]);
      if (!mounted || owner != _owner) return;
      setState(() {
        if (!more) _posts.clear();
        _posts.addAll(rows); _more = rows.length == 20;
        _followers = counts[0]; _following = counts[1]; _total = counts[2];
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Your online posts and counts could not load. Pull to refresh or retry.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String,dynamic> get _details => BackendScope.of(context)?.social?.client.auth.currentUser?.userMetadata ?? _preview;

  Future<void> _save(Map<String,dynamic> values) async {
    final api = BackendScope.of(context)?.social;
    if (_owner == null) { setState(() => _preview = {..._preview,...values}); return; }
    if (api == null || api.me != _owner) throw StateError('Sign in again');
    if (values['display_name'] != null) {
      await api.client.from('cn_profiles').upsert({'id':_owner,'display_name':values['display_name']});
    }
    await api.client.auth.updateUser(UserAttributes(data: values));
    if (mounted) setState(() {});
  }

  Future<void> _edit() async {
    final details = _details;
    final values = await pushPage<Map<String,dynamic>>(context, _ProfileEditor(
      name: details['display_name'] as String? ?? BackendScope.of(context)?.account?.displayName ?? 'Car enthusiast',
      bio: details['cn_bio'] as String? ?? '', city: details['city'] as String? ?? '',
      car: details['cn_dream_car'] as String? ?? '', save: _save,
    ));
    if (mounted && values != null) setState(() {});
  }

  List<String> _images(Map<String,dynamic> post) =>
    (post['cn_post_media'] as List<dynamic>? ?? []).map((e) => e['storage_path'] as String).toList();

  Widget _photo(String path, {BoxFit fit = BoxFit.cover}) {
    if (NightAssets.photos.contains(path)) return Image.asset(path, fit:fit, cacheWidth:720);
    final api = BackendScope.of(context)?.social;
    if (api == null || !path.startsWith('${_owner ?? ''}/')) return const Icon(Icons.person_outline,size:48);
    return Image.network(api.imageUrl(path),fit:fit,cacheWidth:720,
      errorBuilder: (_,e,s) => const Icon(Icons.broken_image_outlined));
  }

  Future<void> _chooseImage(bool cover) async {
    final choices = [...NightAssets.photos, ..._posts.expand(_images)];
    final selection = await showModalBottomSheet<String>(context:context,isScrollControlled:true,
      builder:(context) => SafeArea(child: Padding(padding:const EdgeInsets.all(20),child:Column(
        mainAxisSize:MainAxisSize.min,children:[
          Text(cover ? 'Choose cover' : 'Choose profile photo',style:Theme.of(context).textTheme.titleLarge),
          const SizedBox(height:8),
          const Text('Choose an illustration or one of your loaded published photos. Use Create to publish a new photo.'),
          const SizedBox(height:16),
          SizedBox(height:240,child:GridView.count(crossAxisCount:3,mainAxisSpacing:8,crossAxisSpacing:8,
            children: choices.map((p)=>InkWell(onTap:()=>Navigator.pop(context,p),child:ClipRRect(borderRadius:BorderRadius.circular(12),child:_photo(p)))).toList())),
        ]))));
    if(selection == null || !mounted) return;
    try { await _save({cover ? 'cn_cover' : 'cn_avatar':selection}); }
    catch (_) { if(mounted) setState(()=>_error='Could not save your photo selection. Try again.'); }
  }

  Future<void> _create() async {
    final backend=BackendScope.of(context);
    if (backend != null && _owner == null) { await pushPage<void>(context,const AuthPage()); return; }
    if (_owner != null) {
      await pushPage<bool>(context,PhotoComposePage(ownerId:_owner!));
      if(mounted) await _load();
    } else {
      await pushPage<bool>(context,ComposePage(session:widget.session));
      if(mounted) setState((){});
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable:widget.session,builder:(context,_) {
    final account=BackendScope.of(context)?.account;
    final details=_details;
    final name=details['display_name'] as String? ?? account?.displayName ?? 'Car enthusiast';
    final bio=details['cn_bio'] as String? ?? '';
    final city=details['city'] as String? ?? account?.city ?? '';
    final dream=details['cn_dream_car'] as String? ?? '';
    final cover=details['cn_cover'] as String? ?? NightAssets.hero;
    final avatar=details['cn_avatar'] as String?;
    final own=widget.session.posts.where((p)=>p.author=='You').toList();
    final photos=_owner == null ? own.expand((p)=>p.imageAssets).toList() : _posts.expand(_images).toList();
    return RefreshIndicator(onRefresh:_load,child:ListView(padding:EdgeInsets.zero,children:[
      SizedBox(height:250,child:Stack(children:[
        Positioned(left:0,right:0,top:0,height:190,child:_photo(cover)),
        Positioned(top:12,right:12,child:IconButton.filled(tooltip:'Profile options',onPressed:()=>pushPage<void>(context,SettingsPage(session:widget.session)),icon:const Icon(Icons.settings_outlined))),
        Positioned(right:16,top:136,child:IconButton.filled(tooltip:'Change cover',onPressed:()=>_chooseImage(true),icon:const Icon(Icons.camera_alt_outlined))),
        Positioned(bottom:0,left:24,child:Stack(children:[
          Container(width:128,height:128,padding:const EdgeInsets.all(5),decoration:BoxDecoration(shape:BoxShape.circle,color:Theme.of(context).scaffoldBackgroundColor),
            child:ClipOval(child:avatar == null ? Container(color:Theme.of(context).colorScheme.primaryContainer,child:Center(child:Text(name.isEmpty?'C':name.characters.first,style:TextStyle(fontSize:48,color:Theme.of(context).colorScheme.onPrimaryContainer)))) : _photo(avatar))),
          Positioned(bottom:0,right:0,child:IconButton.filled(tooltip:'Change profile photo',onPressed:()=>_chooseImage(false),icon:const Icon(Icons.camera_alt_outlined,size:20))),
        ])),
      ])),
      Padding(padding:const EdgeInsets.fromLTRB(20,12,20,20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(name,style:Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.w800)),
        const SizedBox(height:6),
        Text(_owner == null ? 'Preview profile · changes last for this session' : 'Cars Night member',style:TextStyle(color:Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height:16),
        Wrap(spacing:24,runSpacing:12,children:[
          _Stat(value:_owner==null?'—':(_followers?.toString()??'—'),label:'Followers'),
          _Stat(value:_owner==null?'—':(_following?.toString()??'—'),label:'Following'),
          _Stat(value:_owner==null?'${own.length}':(_total?.toString()??'—'),label:'Posts'),
        ]),
        const SizedBox(height:16),
        Text(bio.isEmpty ? 'Every car has a story. Tell yours.' : bio),
        const SizedBox(height:12),
        Wrap(spacing:8,runSpacing:4,children:[
          const Chip(avatar:Icon(Icons.directions_car_outlined,size:18),label:Text('Car enthusiast')),
          if(city.isNotEmpty) Chip(avatar:const Icon(Icons.location_on_outlined,size:18),label:Text(city)),
        ]),
        const SizedBox(height:12),
        Row(children:[Expanded(child:FilledButton.icon(onPressed:_edit,icon:const Icon(Icons.edit_outlined),label:const Text('Edit profile'))),const SizedBox(width:10),
          Expanded(child:OutlinedButton.icon(onPressed:_create,icon:const Icon(Icons.add),label:const Text('Create')))]),
        Wrap(spacing:8,children:[
          TextButton.icon(onPressed:()=>pushPage<void>(context,const PeoplePage()),icon:const Icon(Icons.people_outline),label:const Text('Find car lovers')),
          TextButton.icon(onPressed:()=>pushPage<void>(context,SavedPage(session:widget.session)),icon:const Icon(Icons.bookmark_border),label:const Text('Saved')),
          TextButton.icon(onPressed:()=>pushPage<void>(context,const AccountPage()),icon:const Icon(Icons.manage_accounts_outlined),label:Text(account==null?'Sign in':'Account')),
        ]),
        const Divider(),
        Wrap(spacing:8,children:[for(final entry in [(0,'Posts'),(1,'Photos'),(2,'About')]) ChoiceChip(label:Text(entry.$2),selected:_tab==entry.$1,onSelected:(_)=>setState(()=>_tab=entry.$1))]),
        const SizedBox(height:16),
        if(_loading) const LinearProgressIndicator(),
        if(_error!=null) ...[InfoNote(_error!),TextButton(onPressed:()=>_load(),child:const Text('Retry'))],
        if(_tab==2) ...[
          Text('About your garage',style:Theme.of(context).textTheme.titleLarge),
          ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.location_on_outlined),title:Text(city.isEmpty?'Add your city':city)),
          ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.directions_car_outlined),title:Text(dream.isEmpty?'Add your dream car':dream)),
          const InfoNote('Bio, photo choices and dream car are currently saved to your account details. Public profile sharing is not enabled yet.'),
          OutlinedButton(onPressed:_edit,child:const Text('Edit details')),
        ] else if(_tab==1) ...[
          if(photos.isEmpty) const EmptyState(title:'Your photos belong here',message:'Publish your first car photo.',icon:Icons.photo_library_outlined),
          GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:3,mainAxisSpacing:6,crossAxisSpacing:6,
            children:photos.map((p)=>InkWell(onTap:()=>showDialog<void>(context:context,builder:(context)=>Dialog(child:AspectRatio(aspectRatio:1,child:_photo(p,fit:BoxFit.contain)))),child:ClipRRect(borderRadius:BorderRadius.circular(10),child:_photo(p)))).toList()),
        ] else ...[
          if(_owner==null) ...own.map((p)=>Padding(padding:const EdgeInsets.only(bottom:16),child:PostCard(post:p,session:widget.session))),
          if(_owner!=null) ..._posts.map((p)=>Padding(padding:const EdgeInsets.only(bottom:16),child:NightCard(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
            Padding(padding:const EdgeInsets.all(14),child:Text(p['caption'] as String)),
            for(final image in _images(p)) AspectRatio(aspectRatio:1,child:_photo(image,fit:BoxFit.contain)),
          ])))),
          if(!_loading && _error==null && (_owner==null?own.isEmpty:_posts.isEmpty)) const EmptyState(title:'Your story starts here',message:'Tap Create to share your first photo.',icon:Icons.add_photo_alternate_outlined),
        ],
        if(_more && _tab!=2) TextButton(onPressed:_loading?null:()=>_load(more:true),child:const Text('Load more')),
      ])),
    ]));
  });
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value,required this.label});
  final String value,label;
  @override
  Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(value,style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800)),Text(label,style:Theme.of(context).textTheme.bodySmall),
  ]);
}

class _ProfileEditor extends StatefulWidget {
  const _ProfileEditor({required this.name,required this.bio,required this.city,required this.car,required this.save});
  final String name,bio,city,car;
  final Future<void> Function(Map<String,dynamic>) save;
  @override
  State<_ProfileEditor> createState()=>_ProfileEditorState();
}
class _ProfileEditorState extends State<_ProfileEditor> {
  final _form=GlobalKey<FormState>();
  late final _name=TextEditingController(text:widget.name), _bio=TextEditingController(text:widget.bio),
    _city=TextEditingController(text:widget.city), _car=TextEditingController(text:widget.car);
  bool _busy=false;
  String? _error;
  @override
  void dispose(){_name.dispose();_bio.dispose();_city.dispose();_car.dispose();super.dispose();}
  @override
  Widget build(BuildContext context)=>PopScope(canPop:!_busy,child:PageFrame(title:'Edit profile',children:[
    Form(key:_form,child:Column(children:[
      TextFormField(controller:_name,enabled:!_busy,maxLength:80,decoration:const InputDecoration(labelText:'Display name'),validator:(v)=>v==null||v.trim().isEmpty?'Enter your name':null),
      const SizedBox(height:16),TextFormField(controller:_bio,enabled:!_busy,maxLength:160,maxLines:3,decoration:const InputDecoration(labelText:'Bio')),
      const SizedBox(height:16),TextFormField(controller:_city,enabled:!_busy,maxLength:80,decoration:const InputDecoration(labelText:'City')),
      const SizedBox(height:16),TextFormField(controller:_car,enabled:!_busy,maxLength:80,decoration:const InputDecoration(labelText:'Dream car')),
    ])),
    if(_error!=null) InfoNote(_error!),
    GradientButton(label:_busy?'Saving…':'Save profile',onPressed:_busy?null:() async {
      if(!_form.currentState!.validate())return;
      setState(()=>_busy=true);
      final values=<String,dynamic>{'display_name':_name.text.trim(),'cn_bio':_bio.text.trim(),'city':_city.text.trim(),'cn_dream_car':_car.text.trim()};
      try{await widget.save(values);if(context.mounted)Navigator.pop(context,values);}
      catch(_){if(mounted)setState(()=>_error='Could not finish saving. Check your connection and retry.');}
      finally{if(mounted)setState(()=>_busy=false);}
    }),
  ]));
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
      final posts = session.posts
          .where((post) => session.isSaved(post.id))
          .toList();
      return PageFrame(
        title: 'Saved collection',
        children: [
          if (cars.isEmpty && posts.isEmpty)
            const EmptyState(
              title: 'Keep your favorites close',
              message: 'Save cars and posts to find them here.',
              icon: Icons.bookmark_border,
            ),
          if (cars.isNotEmpty) ...[
            Text('Cars', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final car in cars)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ListingCard(car: car, session: session, compact: true),
              ),
          ],
          if (posts.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Posts', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final post in posts)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PostCard(post: post, session: session),
              ),
          ],
        ],
      );
    },
  );
}
