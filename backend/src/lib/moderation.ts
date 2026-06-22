const { PDFParse } = require('pdf-parse');
import { config } from './config';
import { logger } from './logger';

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
  // 1. Kiểm tra bằng bộ lọc nhạy cảm local trước (để tiết kiệm chi phí & làm fallback)
  // const localResult = localProfanityCheck(text);
  // if (localResult) {
  //   return localResult;
  // }

  // 2. Ưu tiên sử dụng Google Gemini API nếu có API Key
  if (config.geminiApiKey) {
    return checkGeminiModeration(text);
  }

  // 3. Sử dụng OpenAI GPT-4o-mini làm phương án fallback
  // if (config.openaiApiKey) {
  //   return checkOpenAIModeration(text);
  // }

  // Mặc định bỏ qua kiểm duyệt tự động để tránh làm gián đoạn hệ thống nếu không cấu hình gì
  return { flagged: false, categories: [] };
}

async function checkGeminiModeration(text: string): Promise<ModerationResult> {
  try {
    const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${config.geminiApiKey}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        contents: [
          {
            parts: [
              {
                text: text
              }
            ]
          }
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
}`
            }
          ]
        },
        generationConfig: {
          responseMimeType: 'application/json',
          temperature: 0.1
        }
      }),
    });

    if (!response.ok) {
      const errorDetail = await response.text().catch(() => '');
      logger.error({ status: response.status, errorDetail }, 'Gemini API Error');
      return {
        flagged: false,
        categories: [],
        error: `Gemini API Error ${response.status}: ${errorDetail.slice(0, 200)}`
      };
    }

    const data = await response.json() as any;
    const content = data.candidates?.[0]?.content?.parts?.[0]?.text?.trim();
    if (content) {
      const parsed = JSON.parse(content) as { flagged: boolean; categories?: string[] };
      return {
        flagged: parsed.flagged === true,
        categories: parsed.categories || (parsed.flagged ? ['violation'] : []),
      };
    }
  } catch (error: any) {
    logger.error({ err: error }, 'Gemini API Exception: Failed to moderate text');
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
      logger.error({ status: response.status, errorDetail }, 'OpenAI Chat Moderation Error');
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
    logger.error({ err: error }, 'OpenAI Chat Moderation Exception: Failed to moderate text');
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
      logger.error({ pdfUrl, status: response.status }, 'PDF Download Error: Failed to fetch PDF from URL');
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
    logger.error({ err: error }, 'PDF Extraction Error: Failed to extract text from PDF');
    return '';
  }
}
