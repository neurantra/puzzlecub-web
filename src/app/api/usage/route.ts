import {
  clientIp,
  configured,
  authConfigured,
  boundedBody,
  isAdmin,
  networkKey,
  noStore,
  rateLimit,
  rpc,
  sameOrigin,
} from "../../_lib/analytics/server";
import { gameNames } from "../../_lib/analytics/types";

export async function POST(request: Request) {
  if (!sameOrigin(request))
    return new Response(null, { status: 403, headers: noStore });
  if (process.env.NEXT_PUBLIC_ANALYTICS_ENABLED !== "true")
    return new Response(null, { status: 204, headers: noStore });
  if (!configured() || !authConfigured())
    return new Response(null, { status: 503, headers: noStore });
  if (await isAdmin())
    return new Response(null, { status: 204, headers: noStore });
  try {
    const raw = await boundedBody(request, 2048);
    const data = JSON.parse(raw);
    const games = (value: unknown): value is string[] =>
      Array.isArray(value) &&
      value.length <= Object.keys(gameNames).length &&
      value.every((v) => typeof v === "string" && Object.hasOwn(gameNames, v));
    if (
      !data ||
      data.consent !== true ||
      !/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(
        data.id,
      ) ||
      typeof data.path !== "string" ||
      !/^\/[a-zA-Z0-9/_-]*$/.test(data.path) ||
      data.path.length > 200 ||
      data.path.startsWith("/admin") ||
      data.path.startsWith("/api") ||
      !Number.isInteger(data.seconds) ||
      data.seconds < 0 ||
      data.seconds > 86400 ||
      !Number.isInteger(data.sequence) ||
      data.sequence < 1 ||
      data.sequence > 1000000 ||
      typeof data.visible !== "boolean" ||
      !games(data.games) ||
      !games(data.completed) ||
      data.completed.some((g: string) => !data.games.includes(g)) ||
      typeof data.referrer !== "string" ||
      data.referrer.length > 253
    )
      return new Response(null, { status: 400, headers: noStore });
    if (!(await rateLimit(`usage:${networkKey(request)}`, 240, 60)))
      return new Response(null, { status: 429, headers: noStore });
    const ua = request.headers.get("user-agent") ?? "";
    if (/bot|crawler|spider|headless/i.test(ua))
      return new Response(null, { status: 204, headers: noStore });
    let referrer = "";
    try {
      referrer = data.referrer
        ? new URL(`https://${data.referrer}`).hostname
        : "";
    } catch {}
    await rpc("usage_record", {
      p_id: data.id,
      p_ip:
        process.env.ANALYTICS_COLLECT_IP === "true" ? clientIp(request) : null,
      p_path: data.path,
      p_referrer: referrer,
      p_device: /Mobile|Android|iPhone|iPad/i.test(ua)
        ? "Mobile / tablet"
        : "Desktop / other",
      p_seconds: data.seconds,
      p_sequence: data.sequence,
      p_games: [...new Set(data.games)],
      p_completed: [...new Set(data.completed)],
      p_visible: data.visible,
    });
    return new Response(null, { status: 204, headers: noStore });
  } catch (e) {
    return new Response(null, {
      status:
        e instanceof RangeError ? 413 : e instanceof SyntaxError ? 400 : 503,
      headers: noStore,
    });
  }
}
