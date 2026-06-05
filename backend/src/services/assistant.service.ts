import { config } from '../lib/config';
import { HttpError } from '../lib/http-error';
import type { AssistantChatDto } from '../dto/assistant.dto';

const SYSTEM_PROMPT = `Bạn là "Hải cẩu Sfinity" — trợ lý thân thiện giúp người dùng sử dụng ứng dụng Sfinity (nền tảng khám phá địa điểm học tập, chia sẻ tài liệu, cộng đồng học tập).

QUY TẮC BẮT BUỘC:
1. CHỈ trả lời câu hỏi về cách dùng app Sfinity (Khám phá, Địa điểm, Tài liệu, Cộng đồng, Nhóm học, Học gần tôi, Hồ sơ, Cài đặt, v.v.).
2. KHÔNG giải bài tập, không dạy kiến thức học thuật, không làm hộ bài kiểm tra.
3. KHÔNG truy cập, đọc hay suy đoán dữ liệu riêng tư của người dùng (chat nhóm, tài liệu private, thông tin cá nhân). Nếu được hỏi về nội dung riêng tư, từ chối lịch sự và hướng dẫn thao tác trong app.
4. Trả lời ngắn gọn, rõ ràng, từng bước khi cần. Dùng emoji hải cẩu 🦭 nhẹ nhàng nếu phù hợp.
5. Trả lời bằng ngôn ngữ người dùng dùng (tiếng Việt hoặc English).
6. Nếu không chắc, gợi ý người dùng vào mục Phản hồi trong app hoặc liên hệ admin.`;

const CONTEXT_HINTS: Record<string, string> = {
  explore:
    'Người dùng đang ở tab Khám phá: tìm kiếm, nội dung nổi bật, biểu đồ hoạt động, bảng xếp hạng.',
  places:
    'Người dùng đang ở tab Địa điểm: bản đồ OSM, check-in, đánh giá, Học gần tôi, địa điểm của tôi.',
  documents:
    'Người dùng đang ở tab Tài liệu: xem, tải, tạo/sửa tài liệu học tập.',
  community:
    'Người dùng đang ở tab Cộng đồng: bạn bè, nhóm học, chat nhóm, bản đồ vị trí thành viên.',
  profile:
    'Người dùng đang ở tab Cá nhân: hồ sơ, yêu thích, thông báo, phản hồi, cài đặt.',
};

const FAQ: { keywords: string[]; answer: string }[] = [
  {
    keywords: ['check-in', 'check in', 'checkin'],
    answer:
      '🦭 Để check-in địa điểm: mở tab **Địa điểm** → chọn marker trên bản đồ → vào chi tiết địa điểm → nhấn **Check-in**. Bạn cần bật quyền vị trí để app xác nhận bạn đang ở gần địa điểm.',
  },
  {
    keywords: ['học gần tôi', 'study near me', 'gần tôi', 'near me'],
    answer:
      '🦭 **Học gần tôi**: tab **Địa điểm** → nút **Học gần tôi** → cho phép GPS → app gợi ý địa điểm học tập gần bạn.',
  },
  {
    keywords: ['tải tài liệu', 'upload', 'tạo tài liệu', 'đăng tài liệu', 'document'],
    answer:
      '🦭 Để chia sẻ tài liệu: tab **Tài liệu** → nút **+** trên thanh tiêu đề → điền thông tin và chọn file → xuất bản. Bạn cũng có thể vào **Cá nhân → Bài viết của tôi** để quản lý.',
  },
  {
    keywords: ['nhóm', 'group', 'tạo nhóm', 'create group'],
    answer:
      '🦭 Tạo nhóm học: tab **Cộng đồng** → **Nhóm** → **Tạo nhóm** → đặt tên và mời thành viên. Trong nhóm có chat, lưu trữ file và bản đồ vị trí thành viên.',
  },
  {
    keywords: ['bạn bè', 'friend', 'kết bạn', 'add friend'],
    answer:
      '🦭 Kết bạn: tab **Cộng đồng** → **Bạn bè** → tìm người dùng hoặc chấp nhận lời mời. Bạn có thể xem hồ sơ và tương tác sau khi đã kết bạn.',
  },
  {
    keywords: ['yêu thích', 'favorite', 'bookmark', 'lưu'],
    answer:
      '🦭 Lưu yêu thích: mở chi tiết tài liệu hoặc địa điểm → nhấn biểu tượng **bookmark**. Xem lại tại menu **Đã lưu** hoặc tab **Cá nhân**.',
  },
  {
    keywords: ['đổi mật khẩu', 'change password', 'password'],
    answer:
      '🦭 Đổi mật khẩu: tab **Cá nhân** → **Cài đặt** → **Đổi mật khẩu**. Nếu đăng nhập Google, dùng **Thiết lập mật khẩu** trong cài đặt.',
  },
  {
    keywords: ['ngôn ngữ', 'language', 'tiếng anh', 'english', 'vietnamese'],
    answer:
      '🦭 Đổi ngôn ngữ: tab **Cá nhân** → **Cài đặt** → **Ngôn ngữ** → chọn Tiếng Việt hoặc English.',
  },
  {
    keywords: ['theme', 'giao diện', 'dark', 'sáng', 'tối'],
    answer:
      '🦭 Đổi giao diện: tab **Cá nhân** → **Cài đặt** → **Giao diện** → Sáng / Tối / Hệ thống.',
  },
  {
    keywords: ['phản hồi', 'feedback', 'báo cáo', 'report'],
    answer:
      '🦭 Gửi phản hồi: tab **Cá nhân** → **Phản hồi**. Báo cáo vi phạm: mở nội dung cần báo cáo → chọn **Báo cáo vi phạm**.',
  },
];

const rateLimitMap = new Map<string, { count: number; resetAt: number }>();
const RATE_LIMIT = 30;
const RATE_WINDOW_MS = 60_000;

function checkRateLimit(userId: string): void {
  const now = Date.now();
  const entry = rateLimitMap.get(userId);
  if (!entry || now > entry.resetAt) {
    rateLimitMap.set(userId, { count: 1, resetAt: now + RATE_WINDOW_MS });
    return;
  }
  if (entry.count >= RATE_LIMIT) {
    throw new HttpError(429, 'Too many requests. Please wait a moment.', 'Too Many Requests');
  }
  entry.count += 1;
}

function normalize(text: string): string {
  return text.toLowerCase().normalize('NFD').replace(/\p{M}/gu, '');
}

function fallbackReply(message: string, context?: string): string {
  const normalized = normalize(message);

  for (const item of FAQ) {
    if (item.keywords.some((kw) => normalized.includes(normalize(kw)))) {
      return item.answer;
    }
  }

  const contextHint = context && CONTEXT_HINTS[context] ? `\n\n${CONTEXT_HINTS[context]}` : '';
  return (
    '🦭 Mình là Hải cẩu Sfinity — chỉ hỗ trợ hướng dẫn dùng app thôi nhé! ' +
    'Bạn có thể hỏi: "Check-in thế nào?", "Tạo nhóm học?", "Tải tài liệu?", "Học gần tôi?"' +
    contextHint +
    '\n\n(Lưu ý: mình không giải bài tập và không xem được dữ liệu riêng tư của bạn.)'
  );
}

function rejectAcademicRequest(message: string): string | null {
  const normalized = normalize(message);
  const academicPatterns = [
    'giai bai',
    'lam bai',
    'bai tap',
    'homework',
    'solve this',
    'giai phuong trinh',
    'tinh toan',
    'exam answer',
    'quiz answer',
    'lam ho',
    'chep bai',
  ];
  if (academicPatterns.some((p) => normalized.includes(p))) {
    return '🦭 Xin lỗi nhé! Mình chỉ hướng dẫn cách dùng app Sfinity, không giải bài tập hay nội dung học thuật. Bạn thử hỏi về tính năng app xem sao?';
  }
  return null;
}

function rejectPrivateDataRequest(message: string): string | null {
  const normalized = normalize(message);
  const privatePatterns = [
    'chat nhom',
    'tin nhan',
    'message cua toi',
    'tai lieu rieng',
    'private document',
    'group chat',
    'noi dung chat',
    'doc tin nhan',
    'xem chat',
  ];
  if (privatePatterns.some((p) => normalized.includes(p))) {
    return '🦭 Mình không thể truy cập chat nhóm, tài liệu riêng hay dữ liệu cá nhân của bạn. Hãy mở trực tiếp trong app để xem nhé!';
  }
  return null;
}

async function callOpenAI(
  message: string,
  context: string | undefined,
  history: AssistantChatDto['history'],
): Promise<string> {
  const contextLine =
    context && CONTEXT_HINTS[context] ? `\n\nNgữ cảnh màn hình hiện tại: ${CONTEXT_HINTS[context]}` : '';

  const messages: { role: 'system' | 'user' | 'assistant'; content: string }[] = [
    { role: 'system', content: SYSTEM_PROMPT + contextLine },
  ];

  for (const item of history ?? []) {
    messages.push({ role: item.role, content: item.content });
  }
  messages.push({ role: 'user', content: message });

  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${config.openaiApiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: config.openaiModel,
      messages,
      max_tokens: 600,
      temperature: 0.4,
    }),
  });

  if (!response.ok) {
    const errText = await response.text().catch(() => '');
    throw new HttpError(
      502,
      'AI service temporarily unavailable',
      errText.slice(0, 120) || 'Bad Gateway',
    );
  }

  const data = (await response.json()) as {
    choices?: { message?: { content?: string } }[];
  };
  const reply = data.choices?.[0]?.message?.content?.trim();
  if (!reply) {
    throw new HttpError(502, 'Empty AI response', 'Bad Gateway');
  }
  return reply;
}

export const assistantService = {
  async chat(userId: string, dto: AssistantChatDto): Promise<{ reply: string; source: 'ai' | 'faq' }> {
    checkRateLimit(userId);

    const academicBlock = rejectAcademicRequest(dto.message);
    if (academicBlock) return { reply: academicBlock, source: 'faq' };

    const privateBlock = rejectPrivateDataRequest(dto.message);
    if (privateBlock) return { reply: privateBlock, source: 'faq' };

    if (!config.openaiApiKey) {
      return { reply: fallbackReply(dto.message, dto.context), source: 'faq' };
    }

    try {
      const reply = await callOpenAI(dto.message, dto.context, dto.history);
      return { reply, source: 'ai' };
    } catch (err) {
      if (err instanceof HttpError) throw err;
      return { reply: fallbackReply(dto.message, dto.context), source: 'faq' };
    }
  },
};
