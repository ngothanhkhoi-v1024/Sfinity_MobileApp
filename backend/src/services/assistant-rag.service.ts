import { ASSISTANT_KNOWLEDGE_CHUNKS } from '../data/assistant-knowledge';

function normalize(text: string): string {
  return text
    .toLowerCase()
    .normalize('NFD')
    .replace(/\p{M}/gu, '')
    .replace(/[^a-z0-9\s]/g, ' ');
}

function tokenize(text: string): string[] {
  return normalize(text)
    .split(/\s+/)
    .filter((t) => t.length > 1);
}

export const assistantRagService = {
  retrieve(query: string, limit = 3): { chunks: string[]; chunkIds: string[] } {
    const queryTokens = new Set(tokenize(query));
    if (queryTokens.size === 0) {
      return { chunks: [], chunkIds: [] };
    }

    const scored = ASSISTANT_KNOWLEDGE_CHUNKS.map((chunk) => {
      let score = 0;
      const normalizedKeywords = chunk.keywords.map(normalize);
      for (const kw of normalizedKeywords) {
        if (normalize(query).includes(kw)) score += 3;
      }
      for (const token of tokenize(chunk.text)) {
        if (queryTokens.has(token)) score += 1;
      }
      return { chunk, score };
    })
      .filter((s) => s.score > 0)
      .sort((a, b) => b.score - a.score)
      .slice(0, limit);

    return {
      chunks: scored.map((s) => s.chunk.text),
      chunkIds: scored.map((s) => s.chunk.id),
    };
  },
};
