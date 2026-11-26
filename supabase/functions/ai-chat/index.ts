// Edge Function: ai-chat
// Luồng: Flutter gửi {message, now, busy[], categories[]} -> Gemini hiểu ý định (JSON)
//        -> thuật toán tìm khung giờ trống (slots.ts) -> trả gợi ý cho Flutter.
// Gemini CHỈ phân tích câu chữ; việc chọn giờ không trùng lịch do code quyết định.
//
// Bảo mật: verify_jwt mặc định BẬT, nên chỉ người đã đăng nhập (kể cả khách ẩn danh)
// mới gọi được. GEMINI_API_KEY chỉ nằm ở secret của Supabase, không có trong app.

import { corsHeaders } from '../_shared/cors.ts';
import { findFreeSlots, fromMin, type Interval, toMin } from './slots.ts';

const GEMINI_URL = 'https://generativelanguage.googleapis.com/v1beta/interactions';
const MODEL = Deno.env.get('GEMINI_MODEL') ?? 'gemini-3.5-flash-lite';
// Model dự phòng khi model chính quá tải (503), không tồn tại (404) hoặc hết hạn mức (429)
const FALLBACK_MODEL = Deno.env.get('GEMINI_FALLBACK_MODEL') ?? 'gemini-2.5-flash-lite';
const RETRYABLE = new Set([500, 503, 504]); // lỗi tạm thời: thử lại cùng model
const RETRY_DELAYS_MS = [600, 1500];

const MAX_MESSAGE_CHARS = 500;
const MAX_BUSY = 2000;
const MAX_RANGE_DAYS = 14;
const WEEKDAYS = ['Chủ nhật', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy'];

// ---------------------------------------------------------------------------
// Kiểu dữ liệu
// ---------------------------------------------------------------------------
interface RequestBody {
  message?: string;
  now?: string; // giờ địa phương người dùng: "YYYY-MM-DDTHH:mm"
  busy?: { start: string; end: string }[]; // các sự kiện đã có (giờ địa phương)
  categories?: string[];
  default_duration_minutes?: number;
  style?: string;
}

interface Intent {
  intent: 'schedule' | 'chat';
  reply: string;
  title: string;
  duration_minutes: number;
  category: string;
  earliest: string;
  latest: string;
  day_start_hour: number;
  day_end_hour: number;
}

// Schema JSON để Gemini trả đúng cấu trúc
const INTENT_SCHEMA = {
  type: 'object',
  properties: {
    intent: { type: 'string', enum: ['schedule', 'chat'] },
    reply: { type: 'string', description: 'Câu trả lời ngắn bằng tiếng Việt (chỉ dùng khi intent = chat).' },
    title: { type: 'string', description: 'Tên sự kiện cần lên lịch.' },
    duration_minutes: { type: 'integer', description: 'Thời lượng sự kiện, tính bằng phút.' },
    category: { type: 'string', description: 'Một trong các danh mục hợp lệ, hoặc chuỗi rỗng.' },
    earliest: { type: 'string', description: 'Sớm nhất, dạng YYYY-MM-DDTHH:mm, giờ địa phương.' },
    latest: { type: 'string', description: 'Muộn nhất, dạng YYYY-MM-DDTHH:mm, giờ địa phương.' },
    day_start_hour: { type: 'integer', description: 'Giờ bắt đầu cho phép trong ngày (0-23).' },
    day_end_hour: { type: 'integer', description: 'Giờ kết thúc cho phép trong ngày (1-24).' },
  },
  required: [
    'intent', 'reply', 'title', 'duration_minutes', 'category',
    'earliest', 'latest', 'day_start_hour', 'day_end_hour',
  ],
};

// ---------------------------------------------------------------------------
// Tiện ích
// ---------------------------------------------------------------------------
const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });

const clamp = (n: number, lo: number, hi: number) => Math.min(hi, Math.max(lo, n));

/** Giới hạn tạm: 20 lượt / 10 phút / user (trong bộ nhớ, chỉ mang tính tham khảo). */
const hits = new Map<string, number[]>();
function allow(userId: string): boolean {
  const now = Date.now();
  const recent = (hits.get(userId) ?? []).filter((t) => now - t < 10 * 60 * 1000);
  if (recent.length >= 20) {
    hits.set(userId, recent);
    return false;
  }
  recent.push(now);
  hits.set(userId, recent);
  return true;
}

/** Lấy user id (sub) từ JWT. Platform đã xác thực chữ ký, ở đây chỉ đọc payload. */
function userIdFrom(req: Request): string {
  try {
    const token = (req.headers.get('Authorization') ?? '').replace(/^Bearer\s+/i, '');
    const payload = JSON.parse(atob(token.split('.')[1].replace(/-/g, '+').replace(/_/g, '/')));
    return String(payload.sub ?? 'unknown');
  } catch {
    return 'unknown';
  }
}

class UpstreamError extends Error {
  constructor(public status: number) {
    super(`Gemini trả về lỗi ${status}`);
  }
}

// ---------------------------------------------------------------------------
// Gọi Gemini (Interactions API)
// ---------------------------------------------------------------------------
async function askGemini(prompt: string): Promise<Intent> {
  const apiKey = Deno.env.get('GEMINI_API_KEY');
  if (!apiKey) throw new Error('Máy chủ chưa cấu hình GEMINI_API_KEY');

  const models = [...new Set([MODEL, FALLBACK_MODEL])];
  let lastStatus = 0;

  for (const model of models) {
    for (let attempt = 0; attempt <= RETRY_DELAYS_MS.length; attempt++) {
      const res = await fetch(GEMINI_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-goog-api-key': apiKey },
        body: JSON.stringify({
          model,
          input: prompt,
          store: false, // không lưu hội thoại phía Google
          response_format: { type: 'text', mime_type: 'application/json', schema: INTENT_SCHEMA },
        }),
      });

      if (res.ok) return parseIntent(await res.json());

      lastStatus = res.status;
      console.error(`Gemini error [${model}] attempt ${attempt + 1}:`, res.status, (await res.text()).slice(0, 400));

      if (RETRYABLE.has(res.status) && attempt < RETRY_DELAYS_MS.length) {
        await new Promise((r) => setTimeout(r, RETRY_DELAYS_MS[attempt]));
        continue; // thử lại cùng model
      }
      if (RETRYABLE.has(res.status) || res.status === 404 || res.status === 429) {
        break; // chuyển sang model dự phòng
      }
      throw new UpstreamError(res.status); // lỗi cấu hình (400/401/403...): dừng, không thử tiếp
    }
  }
  throw new UpstreamError(lastStatus);
}

function parseIntent(data: any): Intent {
  const steps: any[] = Array.isArray(data?.steps) ? data.steps : [];
  for (let i = steps.length - 1; i >= 0; i--) {
    if (steps[i]?.type !== 'model_output') continue;
    const text = (steps[i].content ?? [])
      .filter((c: any) => c?.type === 'text')
      .map((c: any) => c.text)
      .join('');
    if (text) return JSON.parse(text) as Intent;
  }
  throw new Error('Gemini không trả về nội dung');
}

function buildPrompt(b: Required<Pick<RequestBody, 'message' | 'now'>> & {
  categories: string[];
  durationDefault: number;
  style: string;
}): string {
  const weekday = WEEKDAYS[new Date(toMin(b.now) * 60000).getUTCDay()];
  return `Bạn là trợ lý lên lịch cho ứng dụng lịch tuần. Luôn dùng tiếng Việt.
Thời điểm hiện tại (giờ địa phương của người dùng): ${b.now}, ${weekday}.
Danh mục hợp lệ: ${b.categories.join(', ') || '(chưa có)'}.
Phong cách trả lời: ${b.style}.
Thời lượng mặc định nếu người dùng không nói: ${b.durationDefault} phút.

Nhiệm vụ: đọc yêu cầu của người dùng rồi điền JSON theo schema.
- intent = "schedule" nếu người dùng muốn tạo hoặc tìm giờ cho một việc. Ngược lại intent = "chat" và chỉ cần điền reply (các trường khác để rỗng hoặc 0).
- earliest và latest: khoảng thời gian cho phép, định dạng YYYY-MM-DDTHH:mm theo giờ địa phương, tính từ thời điểm hiện tại. Nếu người dùng không nói rõ thì earliest là bây giờ và latest là 7 ngày sau.
- Quy đổi các cách nói như "ngày mai", "thứ Năm tuần sau", "cuối tuần" thành ngày cụ thể dựa trên thời điểm hiện tại.
- day_start_hour và day_end_hour: khung giờ trong ngày. Mặc định 8 và 21. "buổi sáng" là 8 đến 12, "buổi chiều" là 13 đến 18, "buổi tối" là 18 đến 22. Nếu người dùng nêu giờ cụ thể thì đặt khung quanh giờ đó.
- category phải là một trong các danh mục hợp lệ, nếu không chắc thì để chuỗi rỗng.
- Không tự bịa khung giờ trống: việc tìm giờ trống do hệ thống thực hiện.

Yêu cầu của người dùng: """${b.message}"""`;
}

// ---------------------------------------------------------------------------
// Handler
// ---------------------------------------------------------------------------
Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'Chỉ hỗ trợ POST' }, 405);

  if (!allow(userIdFrom(req))) {
    return json({ error: 'Bạn gửi quá nhiều yêu cầu, vui lòng thử lại sau ít phút.' }, 429);
  }

  let body: RequestBody;
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Dữ liệu gửi lên không hợp lệ' }, 400);
  }

  const message = String(body.message ?? '').trim().slice(0, MAX_MESSAGE_CHARS);
  const nowMin = toMin(String(body.now ?? ''));
  if (!message) return json({ error: 'Tin nhắn trống' }, 400);
  if (Number.isNaN(nowMin)) return json({ error: 'Thiếu thời gian hiện tại (now)' }, 400);

  const categories = (body.categories ?? []).map(String).slice(0, 50);
  const durationDefault = clamp(Math.round(body.default_duration_minutes ?? 60), 15, 480);

  // Các khoảng bận (bỏ qua dòng sai định dạng)
  const busy: Interval[] = [];
  for (const b of (body.busy ?? []).slice(0, MAX_BUSY)) {
    const s = toMin(b.start);
    const e = toMin(b.end);
    if (!Number.isNaN(s) && !Number.isNaN(e) && e > s) busy.push([s, e]);
  }

  try {
    const intent = await askGemini(
      buildPrompt({
        message,
        now: fromMin(nowMin),
        categories,
        durationDefault,
        style: String(body.style ?? 'Concise / Brief').slice(0, 40),
      }),
    );

    // Hội thoại thông thường
    if (intent.intent !== 'schedule') {
      return json({
        reply: String(intent.reply || 'Mình có thể giúp bạn tìm khung giờ trống để lên lịch. Bạn muốn sắp xếp việc gì?'),
        suggestions: [],
      });
    }

    // Kiểm tra và chuẩn hóa tham số do Gemini trả về
    const title = String(intent.title || '').trim().slice(0, 120) || 'Sự kiện mới';
    const dur = clamp(Math.round(intent.duration_minutes || durationDefault), 15, 480);
    let from = toMin(intent.earliest);
    let to = toMin(intent.latest);
    if (Number.isNaN(from)) from = nowMin;
    if (Number.isNaN(to) || to <= from) to = from + 7 * 1440;
    from = Math.max(from, nowMin); // không gợi ý vào quá khứ
    to = Math.min(to, from + MAX_RANGE_DAYS * 1440);

    let startHour = clamp(Math.round(intent.day_start_hour ?? 8), 0, 23);
    let endHour = clamp(Math.round(intent.day_end_hour ?? 21), 1, 24);
    if (endHour <= startHour) [startHour, endHour] = [8, 21];

    const category = categories.includes(intent.category) ? intent.category : (categories[0] ?? '');
    const slots = findFreeSlots(busy, from, to, dur, startHour, endHour, 3);

    if (slots.length === 0) {
      return json({
        reply: `Mình không tìm được khung giờ trống ${dur} phút cho "${title}" trong khoảng bạn yêu cầu. Bạn thử mở rộng thời gian hoặc rút ngắn thời lượng nhé.`,
        suggestions: [],
      });
    }

    return json({
      reply: `Mình tìm được ${slots.length} khung giờ trống cho "${title}" (${dur} phút). Bạn chọn một khung để lên lịch:`,
      suggestions: slots.map(([s, e]) => ({
        title,
        category,
        start: fromMin(s),
        end: fromMin(e),
      })),
    });
  } catch (err) {
    console.error('ai-chat error:', err);
    if (err instanceof UpstreamError && (err.status === 503 || err.status === 500 || err.status === 504)) {
      return json({ error: 'Trợ lý AI của Google đang quá tải, vui lòng thử lại sau ít phút.' }, 503);
    }
    if (err instanceof UpstreamError && err.status === 429) {
      return json({ error: 'Trợ lý AI đang quá tải hoặc hết hạn mức miễn phí, vui lòng thử lại sau ít phút.' }, 429);
    }
    if (err instanceof UpstreamError && (err.status === 401 || err.status === 403)) {
      return json({ error: 'Khóa API Gemini không hợp lệ hoặc chưa được cấp quyền.' }, 502);
    }
    return json({ error: 'Trợ lý AI gặp sự cố, vui lòng thử lại.' }, 502);
  }
});
