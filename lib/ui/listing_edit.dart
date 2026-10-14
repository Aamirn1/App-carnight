import 'package:flutter/material.dart';
import '../backend/social.dart';
import '../backend/session.dart';
import '../backend/market.dart';
import '../backend/supabase_repositories.dart';
import 'components.dart';

class EditListingPage extends StatefulWidget {
 const EditListingPage({super.key,required this.api,required this.row});
 final SocialRepository api; final Map<String,dynamic> row;
 @override State<EditListingPage> createState()=>_EditListingPageState();
}
class _EditListingPageState extends State<EditListingPage>{
 final _form=GlobalKey<FormState>();
 late final _title=TextEditingController(text:widget.row['title'] as String);
 late final _description=TextEditingController(text:widget.row['description'] as String);
 late final _city=TextEditingController(text:widget.row['city'] as String);
 late final _price=TextEditingController(text:marketPrice(widget.row).split(' ')[1]);
 bool _busy=false;String? _error;
 @override void dispose(){for(final c in [_title,_description,_city,_price]){c.dispose();}super.dispose();}
 Future<void> _save()async{
  if(!_form.currentState!.validate())return;
  setState(()=>_busy=true);
  final row={...widget.row,'title':_title.text.trim(),'description':_description.text.trim(),'city':_city.text.trim(),'price_minor':parseMarketPrice(_price.text,widget.row['currency'] as String)};
  try{await widget.api.editListing(row);row['revision']=(row['revision'] as num).toInt()+1;if(mounted)Navigator.pop(context,row);}
  catch(e){if(mounted)setState(()=>_error='Could not save. The offer may have changed. Reopen it and try again. ${serviceError(e)}');}
  finally{if(mounted)setState(()=>_busy=false);}
 }
 @override Widget build(BuildContext context){
  if(BackendScope.of(context)?.account?.id!=widget.row['owner_id'])return const PageFrame(title:'Edit listing',children:[InfoNote('Sign in as the seller to edit this offer.')]);
  return PageFrame(title:'Edit listing',children:[
   if(_error!=null)InfoNote(_error!),
   Form(key:_form,child:Column(children:[
    TextFormField(controller:_title,enabled:!_busy,maxLength:80,decoration:const InputDecoration(labelText:'Make and model'),validator:(v)=>(v??'').trim().isEmpty?'Enter a title':null),
    TextFormField(controller:_description,enabled:!_busy,maxLength:2000,maxLines:4,decoration:const InputDecoration(labelText:'Offer details'),validator:(v)=>(v??'').trim().isEmpty?'Describe your offer':null),
    TextFormField(controller:_city,enabled:!_busy,maxLength:80,decoration:const InputDecoration(labelText:'City'),validator:(v)=>(v??'').trim().isEmpty?'Enter a city':null),
    TextFormField(controller:_price,enabled:!_busy,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:'Price (${widget.row['currency']})'),validator:(v)=>parseMarketPrice(v??'',widget.row['currency'] as String)==null?'Enter a valid price':null),
   ])),const SizedBox(height:20),GradientButton(label:'Save changes',onPressed:_busy?null:_save),
  ]);
 }
}
