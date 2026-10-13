type User = {id:string,email?:string};
export interface DeletionServices {
 user(token:string): Promise<User|null>;
 session(user:string,token:string): Promise<boolean>;
 attempt(user:string): Promise<boolean>;
 verify(email:string,password:string): Promise<{id:string,token:string}|null>;
 revoke(token:string): Promise<boolean>;
 remove(user:string): Promise<boolean>;
}
const cors={'Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'authorization, apikey, content-type, x-client-info','Access-Control-Allow-Methods':'POST, OPTIONS'};
const reply=(status:number,code:string)=>Response.json({code},{status,headers:cors});
async function payload(req:Request) {
 const reader=req.body?.getReader(); if(!reader) throw new Error();
 const chunks:Uint8Array[]=[];let size=0;
 try {while(true){const r=await reader.read();if(r.done)break;size+=r.value.length;if(size>8192){await reader.cancel();throw new Error();}chunks.push(r.value);}}
 finally {reader.releaseLock();}
 const data=new Uint8Array(size);let offset=0;for(const chunk of chunks){data.set(chunk,offset);offset+=chunk.length;}
 return JSON.parse(new TextDecoder().decode(data));
}
export function deletionHandler(api:DeletionServices) {
 return async(req:Request)=>{
  if(req.method==='OPTIONS')return new Response(null,{status:204,headers:cors});
  if(req.method!=='POST')return reply(405,'method');
  const token=req.headers.get('Authorization')?.replace(/^Bearer\s+/i,'');
  if(!token)return reply(401,'session_expired');
  try {
   const user=await api.user(token);
   if(!user?.email || !await api.session(user.id,token))return reply(401,'session_expired');
   let data;try{data=await payload(req);}catch{return reply(400,'invalid_request');}
   if(data?.confirmation!=='DELETE' || typeof data.password!=='string' || !data.password || data.password.length>1024)return reply(400,'invalid_request');
   if(!await api.attempt(user.id))return reply(429,'rate_limit');
   // Email and actor come exclusively from the verified token, never the body.
   const verified=await api.verify(user.email,data.password);
   if(!verified || verified.id!==user.id)return reply(401,'invalid_credentials');
   if(!await api.revoke(verified.token))return reply(503,'retry');
   if(!await api.remove(user.id))return reply(503,'retry');
   return reply(200,'deleted');
  }catch{return reply(503,'retry');}
 };
}
