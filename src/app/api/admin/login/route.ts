import { NextResponse } from "next/server";
import {
  adminCookie,
  adminToken,
  authConfigured,
  boundedBody,
  networkKey,
  noStore,
  rateLimit,
  sameOrigin,
  validPassword,
} from "../../../_lib/analytics/server";

export async function POST(request: Request) {
  if (!sameOrigin(request))
    return new Response(null, { status: 403, headers: noStore });
  if (!authConfigured())
    return new Response(null, { status: 503, headers: noStore });
  const redirect = (error?: string) =>
    NextResponse.redirect(
      new URL(
        `/admin${error ? `?error=${error}` : ""}`,
        request.headers.get("origin")!,
      ),
      { status: 303, headers: noStore },
    );
  try {
    if (!(await rateLimit(`login:${networkKey(request)}`, 10, 900)))
      return redirect("limit");
    const body = await boundedBody(request, 1024);
    const password = new URLSearchParams(body).get("password") ?? "";
    if (password.length > 256 || !validPassword(password))
      return redirect("password");
    const response = redirect();
    response.cookies.set(adminCookie, adminToken(), {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "strict",
      path: "/",
      maxAge: 8 * 3600,
    });
    return response;
  } catch {
    return redirect("setup");
  }
}
