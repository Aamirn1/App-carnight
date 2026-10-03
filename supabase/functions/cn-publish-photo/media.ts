import { Image } from 'jsr:@matmen/imagescript@1.3.1';

export const MAX_INPUT = 2 * 1024 * 1024;
export const MAX_OUTPUT = 512 * 1024;

// Check SOF dimensions before decompression to reject oversized allocation bombs.
export function jpegDimensions(bytes: Uint8Array): [number, number] {
  if (bytes.length < 4 || bytes[0] !== 255 || bytes[1] !== 216) throw new Error('JPEG required');
  let p = 2;
  while (p + 4 <= bytes.length) {
    if (bytes[p++] !== 255) throw new Error('Invalid JPEG marker');
    while (bytes[p] === 255) p++;
    const marker = bytes[p++];
    if (marker === 217 || marker === 218) break;
    if (marker === 1 || (marker >= 208 && marker <= 215)) continue;
    const length = (bytes[p] << 8) | bytes[p + 1];
    if (length < 2 || p + length > bytes.length) throw new Error('Invalid segment');
    if ([192,193,194].includes(marker)) {
      if (length < 8) throw new Error('Invalid frame');
      const h = (bytes[p + 3] << 8) | bytes[p + 4];
      const w = (bytes[p + 5] << 8) | bytes[p + 6];
      if (w < 1 || h < 1 || w > 1600 || h > 1600) throw new Error('Resize photo before upload');
      return [w,h];
    }
    p += length;
  }
  throw new Error('JPEG frame missing');
}

export async function sanitizePhoto(bytes: Uint8Array) {
  if (bytes.length > MAX_INPUT) throw new Error('Too large');
  const [width,height] = jpegDimensions(bytes);
  const decoded = await Image.decode(bytes);
  if (decoded.width !== width || decoded.height !== height) throw new Error('Dimensions mismatch');
  // Copy pixels into a fresh image: do not carry EXIF/GPS or ancillary metadata.
  const clean = new Image(width,height);
  clean.bitmap.set(decoded.bitmap);
  for (const quality of [78,65,50]) {
    const jpeg = await clean.encodeJPEG(quality);
    if (jpeg.length <= MAX_OUTPUT) return {jpeg,width,height};
  }
  throw new Error('Photo too complex');
}

export async function readLimitedBody(req: Request, limit: number): Promise<Uint8Array> {
  const reader = req.body?.getReader();
  if (!reader) throw new Error('Body required');
  const chunks: Uint8Array[] = [];
  let size = 0;
  try {
    while (true) {
      const {value,done} = await reader.read();
      if (done) break;
      size += value.length;
      if (size > limit) { await reader.cancel(); throw new Error('Too large'); }
      chunks.push(value);
    }
  } finally { reader.releaseLock(); }
  const body = new Uint8Array(size);
  let offset = 0;
  for (const chunk of chunks) {body.set(chunk,offset); offset += chunk.length;}
  return body;
}
