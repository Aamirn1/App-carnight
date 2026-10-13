import {createClient} from 'npm:@supabase/supabase-js@2.57.4';
import {deletionHandler} from './handler.ts';
const url=Deno.env.get('SUPABASE_URL')!;
const service=Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const admin=createClient(url,service,{auth:{persistSession:false,autoRefreshToken:false}});
Deno.serve(deletionHandler({
 user:async(token)=>{const {data,error}=await admin.auth.getUser(token);return error?null:data.user;},
 session:async(actor,token)=>{
  // getUser above has already verified the signed token. Require a live session
  // too, since refresh-session revocation does not itself invalidate JWTs.
  try {
   const raw=token.split('.')[1].replace(/-/g,'+').replace(/_/g,'/');
   const session=JSON.parse(atob(raw.padEnd(Math.ceil(raw.length/4)*4,'='))).session_id;
   if(typeof session!=='string')return false;
   const r=await admin.rpc('cn_account_session_valid',{actor,session});return !r.error && r.data===true;
  }catch{return false;}
 },
 attempt:async(actor)=>{const r=await admin.rpc('cn_account_delete_attempt',{actor});return !r.error;},
 verify:async(email,password)=>{
  // A separate client prevents password sign-in from replacing admin credentials.
  const verifier=createClient(url,Deno.env.get('SUPABASE_ANON_KEY')||service,{auth:{persistSession:false,autoRefreshToken:false}});
  const r=await verifier.auth.signInWithPassword({email,password});
  return r.error||!r.data.session?null:{id:r.data.session.user.id,token:r.data.session.access_token};
 },
 revoke:async(token)=>{const r=await admin.auth.admin.signOut(token,'global');return !r.error;},
 remove:async(id)=>{const r=await admin.auth.admin.deleteUser(id,false);return !r.error;},
}));
