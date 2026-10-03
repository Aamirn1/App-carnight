import { createClient } from 'npm:@supabase/supabase-js@2.57.4';
import { MAX_INPUT, jpegDimensions, readLimitedBody, sanitizePhoto } from './media.ts';

const cors = {'Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'authorization, apikey, content-type, x-client-info','Access-Control-Allow-Methods':'POST, OPTIONS'};
const reply = (status: number, data: object) => Response.json(data,{status,headers:cors});

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response(null,{status:204,headers:cors});
  if (req.method !== 'POST') return reply(405,{code:'method'});
  const token = req.headers.get('Authorization')?.replace(/^Bearer\s+/i,'');
  if (!token) return reply(401,{code:'unauthorized'});
  const url = Deno.env.get('SUPABASE_URL');
  const key = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!url || !key) return reply(503,{code:'setup'});
  const admin = createClient(url,key,{auth:{persistSession:false,autoRefreshToken:false}});
  const {data: {user},error: authError} = await admin.auth.getUser(token);
  if (authError || !user || !user.email_confirmed_at) return reply(401,{code:'unauthorized'});
  try {
    let body;
    try {body = JSON.parse(new TextDecoder().decode(await readLimitedBody(req, 2900000)));}
    catch {return reply(400,{code:'invalid_image'});}
    const {request_id,caption,image} = body ?? {};
    if (typeof request_id !== 'string' || !/^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$/i.test(request_id)) return reply(400,{code:'conflict'});
    if (typeof caption !== 'string' || !caption.trim() || [...caption.trim()].length>500) return reply(400,{code:'invalid_caption'});
    let bytes: Uint8Array;
    try {
      if (typeof image !== 'string' || image.length>Math.ceil(MAX_INPUT/3)*4) throw new Error();
      bytes = Uint8Array.from(atob(image),c=>c.charCodeAt(0));
      if (bytes.length>MAX_INPUT) throw new Error();
      jpegDimensions(bytes);
    } catch {return reply(400,{code:'invalid_image'});}
    const hash = new Uint8Array(await crypto.subtle.digest('SHA-256',bytes));
    const digest = Array.from(hash,x=>x.toString(16).padStart(2,'0')).join('');
    const {data: reservation,error: reserveError} = await admin.rpc('cn_reserve_photo',{
      actor:user.id,request:request_id,digest,body:caption.trim(),
    });
    if (reserveError) return reply(reserveError.code==='P0001'?429:409,{code:reserveError.code==='P0001'?'quota':'conflict'});
    if (reservation.state==='published') return reply(200,{post_id:reservation.post_id});
    let photo;
    try {photo=await sanitizePhoto(bytes);} catch {return reply(400,{code:'invalid_image'});}
    const path = `${user.id}/${request_id}.jpg`;
    const {error: uploadError} = await admin.storage.from('cn-media').upload(path,photo.jpeg,{
      contentType:'image/jpeg',cacheControl:'3600',upsert:true,
    });
    if (uploadError) return reply(503,{code:'storage'});
    const {error: profileError} = await admin.from('cn_profiles').upsert({
      id:user.id,display_name:String(user.user_metadata?.display_name || 'Car enthusiast').trim().slice(0,80) || 'Car enthusiast',
    },{onConflict:'id',ignoreDuplicates:true});
    if (profileError) return reply(503,{code:'database'});
    const {data: postId,error: finishError} = await admin.rpc('cn_finish_photo',{
      actor:user.id,request:request_id,image_width:photo.width,image_height:photo.height,image_bytes:photo.jpeg.length,
    });
    // Keep the charged, deterministic object on a DB failure; a retry reconciles it.
    // Never delete here: an earlier concurrent request may already have published.
    if (finishError) return reply(503,{code:'database'});
    return reply(200,{post_id:postId});
  } catch {return reply(503,{code:'unavailable'});}
});
