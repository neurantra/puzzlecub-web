import { timingSafeEqual } from "node:crypto";
import { noStore, rpc } from "../../../_lib/analytics/server";

export async function GET(request: Request) {
  const secret = process.env.CRON_SECRET;
  const received = Buffer.from(request.headers.get("authorization") ?? "");
  const expected = Buffer.from(`Bearer ${secret}`);
  if (
    !secret ||
    received.length !== expected.length ||
    !timingSafeEqual(received, expected)
  )
    return new Response(null, { status: 401, headers: noStore });
  try {
    await rpc("usage_cleanup", {});
    return Response.json({ ok: true }, { headers: noStore });
  } catch {
    return Response.json(
      { error: "Retention cleanup failed" },
      { status: 503, headers: noStore },
    );
  }
}
