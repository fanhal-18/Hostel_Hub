// ============================================================
//  HOSTELHUB — SUPABASE GLOBAL CLIENT
//  Loaded as a regular <script> (not a module) so it works
//  with file:// URLs. Supabase CDN must be loaded first.
// ============================================================

const SUPABASE_URL  = 'https://uzcjfnmqfznzfxjiittw.supabase.co';
const SUPABASE_ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV6Y2pmbm1xZnpuemZ4amlpdHR3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYzMDk3NzIsImV4cCI6MjA5MTg4NTc3Mn0.bJaLfN_vlED5ZWSGF8FQqc9oWnwdXSLyWIQFYD7HnyQ';

// Supabase CDN exposes window.supabase = { createClient }
const _sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON);

// ── Public API (all global) ──────────────────────────────────

async function sbGetSession() {
  const { data } = await _sb.auth.getSession();
  return data.session;
}

async function sbGetMyProfile() {
  const session = await sbGetSession();
  if (!session) return null;
  const { data } = await _sb.from('profiles').select('*').eq('id', session.user.id).single();
  return data;
}

/**
 * Redirects to login.html if not authenticated.
 * Optionally enforces a required role ('student' | 'admin').
 */
async function sbRequireAuth(requiredRole) {
  const session = await sbGetSession();
  if (!session) { window.location.href = 'login.html'; return null; }

  const profile = await sbGetMyProfile();
  if (!profile) { window.location.href = 'login.html'; return null; }

  if (requiredRole && profile.role !== requiredRole) {
    window.location.href = profile.role === 'admin'
      ? 'admin-dashboard.html'
      : 'student-dashboard.html';
    return null;
  }
  return profile;
}

async function sbSignOut() {
  await _sb.auth.signOut();
  window.location.href = 'login.html';
}
