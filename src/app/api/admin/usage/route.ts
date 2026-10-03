import { isAdmin, noStore, rpc } from "../../../_lib/analytics/server";
import { gameNames, type UsageReport } from "../../../_lib/analytics/types";

export async function GET(request: Request) {
  if (!(await isAdmin()))
    return Response.json(
      { error: "Unauthorized" },
      { status: 401, headers: noStore },
    );
  const params = new URL(request.url).searchParams;
  const days = Number(params.get("days") ?? "7"),
    game = params.get("game") || null;
  if (
    ![1, 7, 30, 90].includes(days) ||
    (game && !Object.hasOwn(gameNames, game))
  )
    return new Response(null, { status: 400, headers: noStore });
  try {
    return Response.json(
      await rpc<UsageReport>("aggregate_report", {
        p_days: days,
        p_game: game,
      }),
      { headers: noStore },
    );
  } catch {
    return Response.json(
      { error: "Analytics unavailable" },
      { status: 503, headers: noStore },
    );
  }
}
