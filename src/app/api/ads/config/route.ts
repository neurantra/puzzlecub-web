import { adConfiguration } from "../../../_lib/ads";
export const dynamic = "force-dynamic";
export function GET() {
  return Response.json(adConfiguration(), {
    headers: { "Cache-Control": "no-store" },
  });
}
