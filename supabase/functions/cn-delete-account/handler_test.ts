import {deletionHandler,DeletionServices} from './handler.ts';
function assert(v:unknown){if(!v)throw new Error('Assertion failed');}
function fixture(overrides:Partial<DeletionServices>={}) {
 const calls:string[]=[];
 const api:DeletionServices={
  user:async()=>{calls.push('user');return{id:'owner',email:'owner@example.test'};},
  session:async()=>{calls.push('session');return true;},
  attempt:async()=>{calls.push('attempt');return true;},
  verify:async(email,password)=>{calls.push('verify');assert(email==='owner@example.test'&&password==='correct');return{id:'owner',token:'fresh'};},
  revoke:async(token)=>{calls.push('revoke');assert(token==='fresh');return true;},
  remove:async(id)=>{calls.push('remove');assert(id==='owner');return true;},
  ...overrides,
 };
 return{handler:deletionHandler(api),calls};
}
function request(body:object={password:'correct',confirmation:'DELETE',user_id:'someone-else'}) {
 return new Request('https://example.test',{method:'POST',headers:{Authorization:'Bearer valid'},body:JSON.stringify(body)});
}
Deno.test('delete actor is derived from verified identity and sessions revoke first',async()=>{
 const f=fixture();const r=await f.handler(request());assert(r.status===200);assert(f.calls.join(',')==='user,session,attempt,verify,revoke,remove');
});
Deno.test('wrong password cannot delete or revoke',async()=>{
 const f=fixture({verify:async()=>null});const r=await f.handler(request());assert(r.status===401);assert(!f.calls.includes('remove')&&!f.calls.includes('revoke'));
});
Deno.test('revoked session is rejected before password verification',async()=>{
 const f=fixture({session:async()=>false});assert((await f.handler(request())).status===401);assert(!f.calls.includes('verify'));
});
Deno.test('explicit confirmation is required',async()=>{
 const f=fixture();assert((await f.handler(request({password:'correct'}))).status===400);assert(!f.calls.includes('attempt'));
});
Deno.test('rate limit blocks password attempts',async()=>{
 const f=fixture({attempt:async()=>false});assert((await f.handler(request())).status===429);assert(!f.calls.includes('verify'));
});
Deno.test('failure to revoke sessions prevents deletion',async()=>{
 const f=fixture({revoke:async()=>false});assert((await f.handler(request())).status===503);assert(!f.calls.includes('remove'));
});
Deno.test('missing auth and oversized streamed bodies are rejected',async()=>{
 const f=fixture();assert((await f.handler(new Request('https://example.test',{method:'POST',body:'{}'}))).status===401);
 assert((await f.handler(request({password:'x'.repeat(9000),confirmation:'DELETE'}))).status===400);assert(!f.calls.includes('remove'));
});
