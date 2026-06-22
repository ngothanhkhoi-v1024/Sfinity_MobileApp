import { config } from './config';

const VISION_MODEL_FALLBACKS = ['gemini-2.0-flash', 'gemini-2.5-flash', 'gemini-1.5-flash'];

function modelCandidates(preferred?: string): string[] {
  const primary = preferred ?? config.geminiModel;
  return [primary, ...VISION_MODEL_FALLBACKS.filter((m) => m !== primary)];
}

export async function geminiGenerateContent(
  body: Record<string, unknown>,
  options?: { models?: string[] },
): Promise<
  | { ok: true; data: unknown; model: string }
  | { ok: false; status: number; error: string; model?: string }
> {
  const apiKey = config.geminiApiKey;
  if (!apiKey) {
    return { ok: false, status: 0, error: 'GEMINI_API_KEY not configured' };
  }

  const models = options?.models ?? modelCandidates();
  let lastError = 'No compatible Gemini model';

  for (const model of models) {
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;
    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        },
        body: JSON.stringify(body),
      });

      if (response.ok) {
        return { ok: true, data: await response.json(), model };
      }

      const errText = await response.text().catch(() => '');
      lastError = `Gemini ${model} HTTP ${response.status}: ${errText.slice(0, 300)}`;
      console.error('[gemini-client]', lastError);

      // Chỉ thử model khác khi model không tồn tại — không retry khi 429/503 (tránh đốt gấp quota).
      if (response.status === 404 || errText.includes('not found')) {
        continue;
      }

      return { ok: false, status: response.status, error: lastError, model };
    } catch (err: any) {
      lastError = err?.message || String(err);
      console.error('[gemini-client] Exception:', model, lastError);
    }
  }

  return { ok: false, status: 502, error: lastError };
}

export function extractGeminiText(data: unknown): string | null {
  const payload = data as {
    candidates?: {
      content?: { parts?: { text?: string }[] };
      finishReason?: string;
    }[];
    promptFeedback?: { blockReason?: string };
  };

  if (payload.promptFeedback?.blockReason) {
    return JSON.stringify({
      flagged: true,
      categories: [`blocked:${payload.promptFeedback.blockReason}`],
    });
  }

  const text = payload.candidates?.[0]?.content?.parts
    ?.map((p) => p.text)
    .filter(Boolean)
    .join('')
    .trim();

  return text || null;
}
