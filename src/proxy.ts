import { NextRequest, NextResponse } from "next/server";
// Both domains can point to the same deployment. DNS is configured separately.
export function proxy(request: NextRequest) {
  const host = request.headers.get("host")?.split(":")[0];
  if (
    (host === "puzzlecub.app" || host === "www.puzzlecub.app") &&
    request.nextUrl.pathname === "/"
  ) {
    const url = request.nextUrl.clone();
    url.pathname = "/mobile-apps";
    return NextResponse.rewrite(url);
  }
  return NextResponse.next();
}
export const config = { matcher: "/" };
