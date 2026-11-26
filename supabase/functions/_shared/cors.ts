// CORS cho phép trình duyệt (Flutter Web) gọi Edge Function.
// Khi deploy thật, nên đổi '*' thành đúng domain của bạn (ví dụ https://schedulai.vercel.app).
export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type, x-supabase-api-version',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};
