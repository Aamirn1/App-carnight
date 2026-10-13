import { Image } from 'jsr:@matmen/imagescript@1.3.1';
import { jpegDimensions, readLimitedBody, sanitizePhoto, MAX_OUTPUT } from './media.ts';
function assert(value: unknown) {if(!value) throw new Error('Assertion failed');}
Deno.test('valid JPEG is re-encoded within the output budget',async()=>{
  const image = new Image(80,60).fill(0x14b5ffff);
  const input = await image.encodeJPEG(90);
  const clean = await sanitizePhoto(input);
  assert(clean.width===80 && clean.height===60 && clean.jpeg.length<=MAX_OUTPUT);
  assert(jpegDimensions(clean.jpeg)[0]===80);
});
Deno.test('reject non-image input and oversized JPEG dimensions before decode',()=>{
  for(const bytes of [new Uint8Array([1,2,3]),new Uint8Array([255,216,255,192,0,8,8,0,10,255,255,1])]){
    let rejected=false;
    try {jpegDimensions(bytes);} catch {rejected=true;}
    assert(rejected);
  }
});
Deno.test('stream size is limited without trusting Content-Length',async()=>{
  const request = new Request('https://example.test',{method:'POST',body:'123456'});
  let rejected=false;
  try {await readLimitedBody(request,3);} catch {rejected=true;}
  assert(rejected);
});
Deno.test('corrupt JPEG with plausible dimensions fails decoder',async()=>{
  let rejected=false;
  try {await sanitizePhoto(new Uint8Array([255,216,255,192,0,8,8,0,10,0,10,1]));} catch {rejected=true;}
  assert(rejected);
});
Deno.test('feed thumbnail is bounded and does not enlarge small images',async()=>{
 const image=new Image(1000,750).fill(0x14b5ffff);
 const clean=await sanitizePhoto(await image.encodeJPEG(90));
 assert(clean.thumbWidth===480&&clean.thumbHeight===360);
 assert(clean.thumb.length<=65536&&clean.jpeg.length+clean.thumb.length<=524288);
 assert(jpegDimensions(clean.thumb)[0]===480);
 const small=await sanitizePhoto(await new Image(60,40).fill(0x9058ffff).encodeJPEG(90));
 assert(small.thumbWidth===60&&small.thumbHeight===40);
});
