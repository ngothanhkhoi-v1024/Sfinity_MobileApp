import { config } from '../lib/config';
import { HttpError } from '../lib/http-error';
import type { AssistantChatDto } from '../dto/assistant.dto';
import {
  assistantToolsService,
  GEMINI_TOOL_DECLARATIONS,
  type AssistantAction,
  type AssistantSource,
  type ToolContext,
} from './assistant-tools.service';
import { assistantRagService } from './assistant-rag.service';

const MAX_TOOL_ROUNDS = 3;
const MAX_ACTIONS = 5;

const SYSTEM_PROMPT = `Bạn là "Hải cẩu Sfinity" — trợ lý thân thiện giúp người dùng sử dụng ứng dụng Sfinity (nền tảng khám phá địa điểm học tập, chia sẻ tài liệu, cộng đồng học tập).

QUY TẮC BẮT BUỘC:
1. CHỈ trả lời về cách dùng app Sfinity và dữ liệu CÔNG KHAI (địa điểm/tài liệu đã xuất bản) qua các công cụ (tools).
2. KHÔNG giải bài tập, không dạy kiến thức học thuật, không làm hộ bài kiểm tra.
3. KHÔNG truy cập chat nhóm, tài liệu private hay dữ liệu riêng tư. Từ chối lịch sự nếu được hỏi.
4. Khi người dùng hỏi về địa điểm, thời tiết, đường đi, tài liệu — HÃY GỌI TOOL phù hợp thay vì đoán.
5. Nếu có vị trí GPS người dùng, ưu tiên dùng cho "gần tôi", thời tiết, chỉ đường.
6. Trả lời ngắn gọn, cụ thể (tên địa điểm, km, °C, phút đi). Emoji 🦭 nhẹ nhàng.
7. Trả lời bằng ngôn ngữ người dùng (tiếng Việt hoặc English).
8. Nếu tool báo lỗi hoặc thiếu GPS, hướng dẫn bật quyền vị trí hoặc vào Phản hồi.`;

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

export interface AssistantChatResponse {
  reply: string;
  source: 'ai' | 'faq' | 'tool';
  sources?: AssistantSource[];
  actions?: AssistantAction[];
}

const rateLimitMap = new Map<string, { count: number; resetAt: number }>();
const RATE_LIMIT = 30;
const RATE_WINDOW_MS = 60_000;

type GeminiPart =
  | { text: string }
  | { functionCall: { name: string; args: Record<string, unknown> } }
  | { functionResponse: { name: string; response: unknown } };

type GeminiContent = { role: 'user' | 'model'; parts: GeminiPart[] };

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

function mergeActions(actions: AssistantAction[]): AssistantAction[] {
  const seen = new Set<string>();
  const out: AssistantAction[] = [];
  for (const action of actions) {
    const key = JSON.stringify(action);
    if (seen.has(key)) continue;
    seen.add(key);
    out.push(action);
    if (out.length >= MAX_ACTIONS) break;
  }
  return out;
}

function mergeSources(sources: AssistantSource[]): AssistantSource[] {
  return [...new Set(sources)];
}

function buildSystemPrompt(context?: string, ragChunks?: string[], location?: { lat: number; lng: number }): string {
  let prompt = SYSTEM_PROMPT;
  if (context && CONTEXT_HINTS[context]) {
    prompt += `\n\nNgữ cảnh màn hình hiện tại: ${CONTEXT_HINTS[context]}`;
  }
  if (location) {
    prompt += `\n\nVị trí GPS người dùng: lat=${location.lat}, lng=${location.lng}. Dùng khi cần tìm gần, thời tiết, chỉ đường.`;
  }
  if (ragChunks && ragChunks.length > 0) {
    prompt += `\n\nTài liệu hướng dẫn liên quan:\n${ragChunks.map((c, i) => `${i + 1}. ${c}`).join('\n')}`;
  }
  return prompt;
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

function faqMatch(message: string): string | null {
  const normalized = normalize(message);
  for (const item of FAQ) {
    if (item.keywords.some((kw) => normalized.includes(normalize(kw)))) {
      return item.answer;
    }
  }
  return null;
}

function fallbackReply(message: string, context?: string): string {
  const faq = faqMatch(message);
  if (faq) return faq;

  const { chunks } = assistantRagService.retrieve(message, 2);
  if (chunks.length > 0) {
    return `🦭 ${chunks.join(' ')}`;
  }

  const contextHint = context && CONTEXT_HINTS[context] ? `\n\n${CONTEXT_HINTS[context]}` : '';
  return (
    '🦭 Mình là Hải cẩu Sfinity — hỗ trợ hướng dẫn app và gợi ý địa điểm/tài liệu công khai! ' +
    'Thử hỏi: "Gợi ý chỗ học gần tôi", "Trời có mưa không?", "Tìm thư viện", "Check-in thế nào?"' +
    contextHint +
    '\n\n(Bật GPS để mình gợi ý chính xác hơn nhé.)'
  );
}

async function detectIntentTools(
  message: string,
  toolCtx: ToolContext,
): Promise<{ reply: string; sources: AssistantSource[]; actions: AssistantAction[] } | null> {
  const n = normalize(message);

  try {
    if (
      n.includes('gan toi') ||
      n.includes('near me') ||
      n.includes('hoc gan') ||
      n.includes('study near') ||
      n.includes('goi y cho hoc')
    ) {
      const result = await assistantToolsService.findStudyPlacesNearby({}, toolCtx);
      const data = result.result as any;
      if (data.error) {
        return { reply: `🦭 ${data.error}`, sources: result.sources, actions: result.actions };
      }
      const names = (data.places ?? []).map((p: any) => p.title).filter(Boolean).slice(0, 3);
      const reply =
        names.length > 0
          ? `🦭 Trong bán kính ${data.radiusKm}km có ${data.placeCount} địa điểm. Gợi ý: ${names.join(', ')}.`
          : `🦭 Chưa có địa điểm công khai trong bán kính ${data.radiusKm}km.`;
      return { reply, sources: result.sources, actions: result.actions };
    }

    if (n.includes('thoi tiet') || n.includes('weather') || n.includes('mua') || n.includes('nang')) {
      if (!toolCtx.location) return null;
      const result = await assistantToolsService.getWeather({}, toolCtx);
      const data = result.result as any;
      if (data.error) return { reply: `🦭 ${data.error}`, sources: [], actions: [] };
      return {
        reply: `🦭 ${data.summary}. ${data.temperatureC >= 30 || data.description?.includes('Mưa') ? 'Nên học trong nhà nếu có thể nhé!' : 'Thời tiết ổn để học ngoài trời!'}`,
        sources: result.sources,
        actions: result.actions,
      };
    }

    if (n.includes('noi bat') || n.includes('featured') || n.includes('trending')) {
      const result = await assistantToolsService.getFeaturedContent();
      const data = result.result as any;
      const placeNames = (data.places ?? []).map((p: any) => p.title).slice(0, 2);
      const docNames = (data.documents ?? []).map((d: any) => d.title).slice(0, 2);
      return {
        reply: `🦭 Nội dung nổi bật: địa điểm ${placeNames.join(', ') || '—'}; tài liệu ${docNames.join(', ') || '—'}.`,
        sources: result.sources,
        actions: result.actions,
      };
    }
  } catch {
    return null;
  }

  return null;
}

async function callGeminiAgent(
  message: string,
  context: string | undefined,
  history: AssistantChatDto['history'],
  toolCtx: ToolContext,
  ragChunks: string[],
): Promise<{ reply: string; sources: AssistantSource[]; actions: AssistantAction[] }> {
  const contents: GeminiContent[] = [];

  for (const item of history ?? []) {
    contents.push({
      role: item.role === 'user' ? 'user' : 'model',
      parts: [{ text: item.content }],
    });
  }
  contents.push({ role: 'user', parts: [{ text: message }] });

  const collectedSources: AssistantSource[] = [];
  const collectedActions: AssistantAction[] = [];

  for (let round = 0; round < MAX_TOOL_ROUNDS; round += 1) {
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${config.geminiModel}:generateContent?key=${config.geminiApiKey}`;
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents,
        systemInstruction: {
          parts: [{ text: buildSystemPrompt(context, ragChunks, toolCtx.location) }],
        },
        tools: [{ functionDeclarations: GEMINI_TOOL_DECLARATIONS }],
        toolConfig: { functionCallingConfig: { mode: 'AUTO' } },
        generationConfig: {
          temperature: 0.35,
          maxOutputTokens: 700,
        },
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
      candidates?: { content?: { parts?: GeminiPart[] } }[];
    };

    const parts = data.candidates?.[0]?.content?.parts ?? [];
    const functionCalls = parts.filter(
      (p): p is { functionCall: { name: string; args: Record<string, unknown> } } =>
        'functionCall' in p && !!p.functionCall?.name,
    );

    if (functionCalls.length === 0) {
      const text = parts
        .filter((p): p is { text: string } => 'text' in p && typeof p.text === 'string')
        .map((p) => p.text)
        .join('')
        .trim();
      if (!text) {
        throw new HttpError(502, 'Empty AI response', 'Bad Gateway');
      }
      return {
        reply: text,
        sources: mergeSources(collectedSources),
        actions: mergeActions(collectedActions),
      };
    }

    contents.push({ role: 'model', parts: functionCalls });

    const responseParts: GeminiPart[] = [];
    for (const call of functionCalls) {
      const { name, args } = call.functionCall;
      try {
        const toolResult = await assistantToolsService.execute(name, args ?? {}, toolCtx);
        collectedSources.push(...toolResult.sources);
        collectedActions.push(...toolResult.actions);
        responseParts.push({
          functionResponse: { name, response: toolResult.result },
        });
      } catch (err) {
        const errMsg = err instanceof HttpError ? err.message : 'Tool execution failed';
        responseParts.push({
          functionResponse: { name, response: { error: errMsg } },
        });
      }
    }

    contents.push({ role: 'user', parts: responseParts });
  }

  throw new HttpError(502, 'AI agent exceeded tool rounds', 'Bad Gateway');
}

async function callOpenAI(
  message: string,
  context: string | undefined,
  history: AssistantChatDto['history'],
  ragChunks: string[],
  location?: { lat: number; lng: number },
): Promise<string> {
  const messages: { role: 'system' | 'user' | 'assistant'; content: string }[] = [
    { role: 'system', content: buildSystemPrompt(context, ragChunks, location) },
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
      max_tokens: 700,
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
  async chat(userId: string, dto: AssistantChatDto): Promise<AssistantChatResponse> {
    checkRateLimit(userId);

    const academicBlock = rejectAcademicRequest(dto.message);
    if (academicBlock) return { reply: academicBlock, source: 'faq' };

    const privateBlock = rejectPrivateDataRequest(dto.message);
    if (privateBlock) return { reply: privateBlock, source: 'faq' };

    const faq = faqMatch(dto.message);
    if (faq && !dto.location) {
      return { reply: faq, source: 'faq', sources: ['rag'] };
    }

    const { chunks: ragChunks } = assistantRagService.retrieve(dto.message, 2);
    const toolCtx: ToolContext = {
      userId,
      location: dto.location,
    };

    if (!config.geminiApiKey && !config.openaiApiKey) {
      const intent = await detectIntentTools(dto.message, toolCtx);
      if (intent) {
        return {
          reply: intent.reply,
          source: 'tool',
          sources: mergeSources(intent.sources),
          actions: mergeActions(intent.actions),
        };
      }
      return { reply: fallbackReply(dto.message, dto.context), source: 'faq' };
    }

    try {
      if (config.geminiApiKey) {
        const agent = await callGeminiAgent(
          dto.message,
          dto.context,
          dto.history,
          toolCtx,
          ragChunks,
        );
        return {
          reply: agent.reply,
          source: agent.sources.length > 0 ? 'tool' : 'ai',
          sources: mergeSources(agent.sources),
          actions: mergeActions(agent.actions),
        };
      }

      const intent = await detectIntentTools(dto.message, toolCtx);
      const reply = await callOpenAI(
        dto.message,
        dto.context,
        dto.history,
        ragChunks,
        dto.location,
      );
      return {
        reply,
        source: intent ? 'tool' : 'ai',
        sources: intent ? mergeSources(intent.sources) : ragChunks.length > 0 ? ['rag'] : undefined,
        actions: intent ? mergeActions(intent.actions) : undefined,
      };
    } catch (err) {
      if (err instanceof HttpError) throw err;

      const intent = await detectIntentTools(dto.message, toolCtx);
      if (intent) {
        return {
          reply: intent.reply,
          source: 'tool',
          sources: mergeSources(intent.sources),
          actions: mergeActions(intent.actions),
        };
      }
      return { reply: fallbackReply(dto.message, dto.context), source: 'faq' };
    }
  },
};
