import {
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
import { gameForPage, pageNames } from "../../_lib/analytics/types";

export async function POST(request: Request) {
  if (!sameOrigin(request))
    return new Response(null, { status: 403, headers: noStore });
  if (
    process.env.NEXT_PUBLIC_ANALYTICS_ENABLED !== "true" ||
    request.headers.get("sec-gpc") === "1" ||
    request.headers.get("dnt") === "1"
  )
    return new Response(null, { status: 204, headers: noStore });
  if (!configured() || !authConfigured())
    return new Response(null, { status: 503, headers: noStore });
  if (await isAdmin())
    return new Response(null, { status: 204, headers: noStore });
  try {
    const data = JSON.parse(await boundedBody(request, 1024));
    const fields = [
      "version",
      "eventId",
      "page",
      "views",
      "plays",
      "completions",
      "seconds",
      "playSeconds",
      "pulse",
    ];
    if (
      !data ||
      typeof data !== "object" ||
      Object.keys(data).length !== fields.length ||
      Object.keys(data).some((key) => !fields.includes(key)) ||
      data.version !== 2 ||
      typeof data.eventId !== "string" ||
      !/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(
        data.eventId,
      ) ||
      typeof data.page !== "string" ||
      !Object.hasOwn(pageNames, data.page) ||
      ![data.views, data.plays, data.completions].every(
        (n) => n === 0 || n === 1,
      ) ||
      !Number.isInteger(data.seconds) ||
      data.seconds < 0 ||
      data.seconds > 30 ||
      !Number.isInteger(data.playSeconds) ||
      data.playSeconds < 0 ||
      data.playSeconds > data.seconds ||
      typeof data.pulse !== "boolean" ||
      (!gameForPage(data.page) &&
        (data.plays || data.completions || data.playSeconds))
    )
      return new Response(null, { status: 400, headers: noStore });
    const ua = request.headers.get("user-agent") ?? "";
    if (/bot|crawler|spider|headless/i.test(ua))
      return new Response(null, { status: 204, headers: noStore });
    // A rotating security-only key is not attached to analytics records.
    if (
      !(await rateLimit(
        `usage:${networkKey(request, `minute:${Math.floor(Date.now() / 60000)}`)}`,
        240,
        60,
      ))
    )
      return new Response(null, { status: 429, headers: noStore });
    await rpc("aggregate_record", {
      p_event: data.eventId,
      p_page: data.page,
      p_views: data.views,
      p_plays: data.plays,
      p_completions: data.completions,
      p_seconds: data.seconds,
      p_play_seconds: data.playSeconds,
      p_pulse: data.pulse,
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
