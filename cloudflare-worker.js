/**
 * Cloudflare Worker — Anthropic API 프록시
 *
 * 배포 방법:
 * 1. https://dash.cloudflare.com → Workers & Pages → Create Worker
 * 2. 이 코드 붙여넣기
 * 3. Settings → Variables → ANTHROPIC_API_KEY 추가 (secret)
 * 4. 배포 후 URL 복사해서 Quarto 사이트의 WORKER_URL에 입력
 */

const ALLOWED_ORIGINS = [
  // GitHub Pages 도메인 입력 (예: https://kkonoo.github.io)
  "https://kkonoo.github.io",
  // 로컬 개발용
  "http://localhost:4321",
  "http://localhost:8080",
  // 추가로 필요한 도메인이 있으면 여기에
];

export default {
  async fetch(request, env) {
    const origin = request.headers.get("Origin") || "";

    // CORS preflight
    if (request.method === "OPTIONS") {
      return corsResponse(null, origin, 204);
    }

    // POST만 허용
    if (request.method !== "POST") {
      return corsResponse(
        JSON.stringify({ error: "Method not allowed" }),
        origin,
        405
      );
    }

    // Origin 검사 (등록된 도메인만 허용)
    const isAllowed =
      ALLOWED_ORIGINS.some((o) => origin.startsWith(o)) ||
      origin === ""; // Worker 직접 테스트 허용

    if (!isAllowed) {
      return corsResponse(
        JSON.stringify({ error: "Origin not allowed" }),
        origin,
        403
      );
    }

    // API 키 확인
    if (!env.ANTHROPIC_API_KEY) {
      return corsResponse(
        JSON.stringify({ error: "API key not configured" }),
        origin,
        500
      );
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return corsResponse(
        JSON.stringify({ error: "Invalid JSON" }),
        origin,
        400
      );
    }

    // 요청 크기 제한 (토큰 낭비 방지)
    const maxMessages = 20;
    if (body.messages && body.messages.length > maxMessages) {
      body.messages = body.messages.slice(-maxMessages);
    }

    // Anthropic API 호출
    const anthropicRes = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": env.ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: body.model || "claude-sonnet-4-5",
        max_tokens: Math.min(body.max_tokens || 1024, 2048), // 최대 2048 제한
        system: body.system,
        messages: body.messages,
      }),
    });

    const data = await anthropicRes.json();
    return corsResponse(JSON.stringify(data), origin, anthropicRes.status);
  },
};

function corsResponse(body, origin, status) {
  const headers = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": ALLOWED_ORIGINS.some((o) =>
      origin.startsWith(o)
    )
      ? origin
      : ALLOWED_ORIGINS[0],
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
  };
  return new Response(body, { status, headers });
}
