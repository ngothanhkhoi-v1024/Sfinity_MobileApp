const { PDFParse } = require('pdf-parse');
import { config } from './config';
import { downloadFirebaseStorageObject } from './firebase-storage';
import { extractGeminiText, geminiGenerateContent } from './gemini-client';

export interface ModerationResult {
  flagged: boolean;
  categories: string[];
  error?: string;
}

function removeDiacritics(str: string): string {
  return str
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/đ/g, 'd')
    .replace(/Đ/g, 'D');
}

function localProfanityCheck(text: string): ModerationResult | null {
  const lowercaseText = text.toLowerCase();
  const normalizedText = removeDiacritics(lowercaseText);

  // Bộ lọc từ khóa cấm tiếng Việt (cả dạng có dấu và không dấu)
  const toxicKeywords = [
    // Có dấu
    'con cặc', 'đụ má', 'dụ má', 'mẹ mày béo', 'mẹ mày',
    'chó đẻ', 'vcl', 'đéo', 'đm', 'dmm', 'cứt',
    'chế tạo pháo', 'chế tạo bom', 'thuốc nổ',

    // Không dấu tương ứng
    'con cac', 'du ma', 'me may beo', 'me may',
    'cho de', 'che tao phao', 'che tao bom', 'thuoc no'
  ];

  const matched = new Set<string>();
  for (const keyword of toxicKeywords) {
    if (lowercaseText.includes(keyword) || normalizedText.includes(keyword)) {
      matched.add(keyword);
    }
  }

  if (matched.size > 0) {
    return {
      flagged: true,
      categories: Array.from(matched).map(w => `local_blacklist:${w}`),
    };
  }
  return null;
}

/**
 * Sử dụng Google Gemini API hoặc OpenAI GPT-4o-mini làm fallback để kiểm duyệt nội dung văn bản.
 * Tự động chặn trước bằng bộ lọc nhạy cảm local.
 * @param text Nội dung cần kiểm duyệt
 */
export async function checkContentModeration(text: string): Promise<ModerationResult> {
  const trimmed = text.trim();
  if (!trimmed) {
    return { flagged: false, categories: [] };
  }

  const localResult = localProfanityCheck(trimmed);
  if (localResult) {
    return localResult;
  }

  if (config.geminiApiKey) {
    return checkGeminiModeration(trimmed);
  }

  return { flagged: false, categories: [] };
}

function scanCombinedText(...parts: Array<string | undefined | null>): ModerationResult | null {
  const combined = parts
    .map((p) => p?.trim())
    .filter(Boolean)
    .join(' ');
  if (!combined) return null;
  return localProfanityCheck(combined);
}

async function checkGeminiModeration(text: string): Promise<ModerationResult> {
  try {
    const result = await geminiGenerateContent({
      contents: [
        {
          parts: [{ text }],
        },
      ],
      systemInstruction: {
        parts: [
          {
            text: `Bạn là hệ thống kiểm duyệt nội dung (tài liệu, địa điểm học tập) tự động cho ứng dụng Sfinity.
Nhiệm vụ của bạn là phân tích nội dung văn bản và xác định xem nó có chứa các nội dung cấm sau hay không:
1. Từ ngữ thô tục, tục tĩu, chửi bậy tiếng Việt (bao gồm cả các từ viết tắt, tiếng lóng tục tĩu như: con cặc, đụ má, mẹ mày béo, v.v.).
2. Hướng dẫn hành vi nguy hại, chế tạo vũ khí, chất nổ, pháo nổ, hoặc chất cấm.
3. Nội dung kích động thù địch, quấy rối cá nhân, hoặc khiêu dâm.

Hãy trả về duy nhất một đối tượng JSON có định dạng sau:
{
  "flagged": true hoặc false,
  "categories": ["danh_sách_danh_mục_vi_phạm_bằng_tiếng_anh_hoặc_tiếng_viet"]
}`,
          },
        ],
      },
      generationConfig: {
        responseMimeType: 'application/json',
        temperature: 0.1,
      },
    });

    if (!result.ok) {
      return {
        flagged: false,
        categories: [],
        error: result.error,
      };
    }

    const content = extractGeminiText(result.data);
    if (content) {
      const parsed = JSON.parse(content) as { flagged: boolean; categories?: string[] };
      return {
        flagged: parsed.flagged === true,
        categories: parsed.categories || (parsed.flagged ? ['violation'] : []),
      };
    }
  } catch (error: any) {
    console.error('[Gemini API Exception] Failed to moderate text:', error);
    return {
      flagged: false,
      categories: [],
      error: error.message || String(error)
    };
  }

  return { flagged: false, categories: [] };
}

async function checkOpenAIModeration(text: string): Promise<ModerationResult> {
  try {
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${config.openaiApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: config.openaiModel || 'gpt-4o-mini',
        messages: [
          {
            role: 'system',
            content: `Bạn là hệ thống kiểm duyệt nội dung tài liệu học tập tự động cho ứng dụng Sfinity.
Nhiệm vụ của bạn là phân tích nội dung văn bản và xác định xem nó có chứa các nội dung cấm sau hay không:
1. Từ ngữ thô tục, tục tĩu, chửi bậy tiếng Việt (bao gồm cả các từ viết tắt, tiếng lóng tục tĩu như: con cặc, đụ má, v.v.).
2. Hướng dẫn hành vi nguy hại, chế tạo vũ khí, chất nổ, pháo nổ, hoặc chất cấm.
3. Nội dung kích động thù địch, quấy rối cá nhân, hoặc khiêu dâm.

Hãy trả về duy nhất một đối tượng JSON có định dạng sau:
{
  "flagged": true hoặc false,
  "categories": ["danh_sách_danh_mục_vi_phạm_bằng_tiếng_anh_hoặc_tiếng_viet"]
}`
          },
          {
            role: 'user',
            content: text
          }
        ],
        temperature: 0.1,
        response_format: { type: 'json_object' }
      }),
    });

    if (!response.ok) {
      const errorDetail = await response.text().catch(() => '');
      console.error('[OpenAI Chat Moderation Error] API error status:', response.status, errorDetail);
      return {
        flagged: false,
        categories: [],
        error: `OpenAI API Error ${response.status}: ${errorDetail.slice(0, 200)}`
      };
    }

    const data = (await response.json()) as {
      choices?: { message?: { content?: string } }[];
    };

    const content = data.choices?.[0]?.message?.content?.trim();
    if (content) {
      const parsed = JSON.parse(content) as { flagged: boolean; categories?: string[] };
      return {
        flagged: parsed.flagged === true,
        categories: parsed.categories || (parsed.flagged ? ['violation'] : []),
      };
    }
  } catch (error: any) {
    console.error('[OpenAI Chat Moderation Exception] Failed to moderate text:', error);
    return {
      flagged: false,
      categories: [],
      error: error.message || String(error)
    };
  }

  return { flagged: false, categories: [] };
}

/**
 * Tải file PDF từ URL và trích xuất nội dung văn bản bên trong (giới hạn 15000 ký tự đầu tiên).
 * @param pdfUrl URL liên kết trực tiếp của file PDF
 */
export async function extractTextFromPdf(pdfUrl: string): Promise<string> {
  try {
    const response = await fetch(pdfUrl);
    if (!response.ok) {
      console.error('[PDF Download Error] Failed to fetch PDF from URL:', pdfUrl, 'Status:', response.status);
      return '';
    }

    const arrayBuffer = await response.arrayBuffer();
    const uint8Array = new Uint8Array(arrayBuffer);

    // Trích xuất text từ file PDF sử dụng class PDFParse
    const parser = new PDFParse(uint8Array);
    const parsedData = await parser.getText();
    const text = parsedData.text ?? '';

    // Dọn dẹp khoảng trắng thừa và cắt ngắn để tránh tràn token OpenAI
    return text.replace(/\s+/g, ' ').trim().slice(0, 15000);
  } catch (error) {
    console.error('[PDF Extraction Error] Failed to extract text from PDF:', error);
    return '';
  }
}

export interface ImageModerationResult extends ModerationResult {
  mimeType?: string;
  imageFetched?: boolean;
  /** Gemini trả 429 — hết quota free tier, không thể OCR ảnh lúc này. */
  quotaExceeded?: boolean;
}

function isGeminiQuotaError(status: number, error?: string): boolean {
  if (status === 429) return true;
  const msg = (error ?? '').toLowerCase();
  return msg.includes('429') || msg.includes('quota') || msg.includes('resource_exhausted');
}

const IMAGE_MAX_BYTES = 5 * 1024 * 1024;
const IMAGE_FETCH_TIMEOUT_MS = 20_000;

const IMAGE_MODERATION_PROMPT = `Bạn là hệ thống kiểm duyệt ảnh tự động cho ứng dụng Sfinity (địa điểm học tập).

BƯỚC 1 — OCR: Đọc TOÀN BỘ chữ/nhãn/text trong ảnh vào trường visible_text (chuỗi rỗng nếu không có chữ).

BƯỚC 2 — Đánh giá vi phạm. flagged=true nếu ẢNH hoặc CHỮ trong ảnh có:
1. Khoả thân, gợi cảm, nội dung khiêu dâm.
2. Bạo lực, máu, vũ khí, hướng dẫn chế tạo bom/pháo/thuốc nổ/vũ khí.
3. Ma túy, chất cấm, hành vi phạm pháp rõ ràng.
4. Nội dung thù hận, phân biệt đối xử.
5. Spam/quảng cáo rõ ràng không liên quan địa điểm học tập.

Cho phép: quán cafe, thư viện, lớp học, sách, bàn ghế, phong cảnh, selfie bình thường.

Trả về DUY NHẤT JSON:
{
  "flagged": true hoặc false,
  "categories": ["danh_muc_vi_pham"],
  "visible_text": "mọi chữ đọc được trong ảnh"
}`;

async function fetchImageAsBase64(
  imageUrl: string,
): Promise<{ base64: string; mimeType: string } | { error: string }> {
  try {
    const fromAdmin = await downloadFirebaseStorageObject(imageUrl);
    if (fromAdmin) {
      if (fromAdmin.buffer.byteLength > IMAGE_MAX_BYTES) {
        return { error: 'Image too large for moderation' };
      }
      if (fromAdmin.buffer.byteLength === 0) {
        return { error: 'Empty image' };
      }
      return {
        base64: fromAdmin.buffer.toString('base64'),
        mimeType: fromAdmin.mimeType,
      };
    }

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), IMAGE_FETCH_TIMEOUT_MS);

    const response = await fetch(imageUrl, { signal: controller.signal });
    clearTimeout(timeout);

    if (!response.ok) {
      return { error: `Cannot fetch image: HTTP ${response.status}` };
    }

    const contentType = response.headers.get('content-type')?.split(';')[0]?.trim() ?? '';
    const mimeType = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'].includes(contentType)
      ? contentType
      : 'image/jpeg';

    const buffer = Buffer.from(await response.arrayBuffer());
    if (buffer.byteLength > IMAGE_MAX_BYTES) {
      return { error: 'Image too large for moderation' };
    }
    if (buffer.byteLength === 0) {
      return { error: 'Empty image' };
    }

    return { base64: buffer.toString('base64'), mimeType };
  } catch (err: any) {
    return { error: err?.message || 'Failed to fetch image' };
  }
}

async function checkGeminiImageModeration(
  imageUrl: string,
  caption?: string,
): Promise<ImageModerationResult> {
  const localCaptionHit = scanCombinedText(caption);
  if (localCaptionHit?.flagged) {
    return { ...localCaptionHit, mimeType: undefined };
  }

  const imageData = await fetchImageAsBase64(imageUrl);
  if ('error' in imageData) {
    return { flagged: false, categories: [], error: imageData.error };
  }

  const captionHint = caption?.trim()
    ? `\nChú thích ảnh từ người dùng: "${caption.trim()}"`
    : '';

  try {
    const body = {
      contents: [
        {
          parts: [
            {
              inlineData: {
                mimeType: imageData.mimeType,
                data: imageData.base64,
              },
            },
            {
              text: `Kiểm duyệt ảnh địa điểm học tập. Đọc kỹ mọi chữ trong ảnh.${captionHint}`,
            },
          ],
        },
      ],
      systemInstruction: {
        parts: [{ text: IMAGE_MODERATION_PROMPT }],
      },
      generationConfig: {
        responseMimeType: 'application/json',
        temperature: 0.1,
      },
    };

    // Một model / ảnh — free tier ~20 req/ngày/model; gọi nhiều model sẽ hết quota rất nhanh.
    const visionModel = config.geminiModel || 'gemini-2.0-flash';
    const result = await geminiGenerateContent(body, { models: [visionModel] });

    if (!result.ok) {
      const quotaExceeded = isGeminiQuotaError(result.status, result.error);
      if (quotaExceeded) {
        console.warn(
          '[Gemini Image Moderation] Quota exceeded — skipping vision check for this upload.',
        );
      }
      return {
        flagged: false,
        categories: [],
        error: result.error,
        imageFetched: true,
        quotaExceeded,
        mimeType: imageData.mimeType,
      };
    }

    const content = extractGeminiText(result.data);
    if (content) {
      const rawHit = scanCombinedText(content);
      if (rawHit?.flagged) {
        return {
          flagged: true,
          categories: rawHit.categories,
          mimeType: imageData.mimeType,
        };
      }

      const parsed = JSON.parse(content) as {
        flagged: boolean;
        categories?: string[];
        visible_text?: string;
      };

      const localTextHit = scanCombinedText(parsed.visible_text, caption);
      if (localTextHit?.flagged) {
        return {
          flagged: true,
          categories: localTextHit.categories,
          mimeType: imageData.mimeType,
        };
      }

      if (parsed.visible_text?.trim()) {
        const textMod = await checkContentModeration(parsed.visible_text);
        if (textMod.flagged) {
          return {
            flagged: true,
            categories: textMod.categories,
            mimeType: imageData.mimeType,
          };
        }
      }

      return {
        flagged: parsed.flagged === true,
        categories: parsed.categories || (parsed.flagged ? ['image_violation'] : []),
        mimeType: imageData.mimeType,
      };
    }

    return {
      flagged: false,
      categories: [],
      error: 'Empty Gemini vision response',
      imageFetched: true,
      mimeType: imageData.mimeType,
    };
  } catch (error: any) {
    console.error('[Gemini Image Moderation] Exception:', error);
    return {
      flagged: false,
      categories: [],
      error: error.message || String(error),
      imageFetched: true,
      mimeType: imageData.mimeType,
    };
  }
}

/**
 * Kiểm duyệt ảnh địa điểm qua Gemini Vision (fetch URL → base64 → model).
 */
export async function checkImageModeration(
  imageUrl: string,
  caption?: string,
): Promise<ImageModerationResult> {
  if (!imageUrl?.trim()) {
    return { flagged: false, categories: [], error: 'Missing image URL' };
  }

  if (!config.geminiApiKey) {
    return { flagged: false, categories: [] };
  }

  return checkGeminiImageModeration(imageUrl, caption);
}
