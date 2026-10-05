import { createClient } from 'npm:@supabase/supabase-js@2.57.4';

// Scheduler-only endpoint. The high-entropy credential stays in Vault and is
// checked server-side. No object path or user ID is accepted from callers.
Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') return new Response(null, { status: 405 });
  const secret = req.headers.get('x-cn-worker-key');
  if (!secret || secret.length > 200) return new Response(null, { status: 401 });
  const url = Deno.env.get('SUPABASE_URL');
  const key = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!url || !key) return new Response(null, { status: 503 });
  const admin = createClient(url, key, { auth: { persistSession: false, autoRefreshToken: false } });
  try {
    const auth = await admin.rpc('cn_cleanup_authorized', { candidate: secret });
    if (auth.error || auth.data !== true) return new Response(null, { status: 401 });
    const claim = await admin.rpc('cn_claim_media_cleanup');
    if (claim.error) return new Response(null, { status: 503 });
    let failed = false;
    for (const job of claim.data ?? []) {
      // Only server-enqueued paths from the mobile bucket may be removed.
      const removed = await admin.storage.from('cn-media').remove([job.storage_path]);
      const finish = await admin.rpc('cn_finish_media_cleanup', {
        job: job.id, lease: job.lease_token, succeeded: !removed.error,
      });
      if (removed.error || finish.error) failed = true;
    }
    return new Response(null, { status: failed ? 503 : 204 });
  } catch { return new Response(null, { status: 503 }); }
});
