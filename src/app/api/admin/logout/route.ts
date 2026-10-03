import { NextResponse } from "next/server";
import {
  adminCookie,
  noStore,
  sameOrigin,
} from "../../../_lib/analytics/server";

export async function POST(request: Request) {
  if (!sameOrigin(request))
    return new Response(null, { status: 403, headers: noStore });
  const response = NextResponse.redirect(
    new URL("/admin", request.headers.get("origin")!),
    {
      status: 303,
      headers: noStore,
    },
  );
  response.cookies.set(adminCookie, "", {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "strict",
    path: "/",
    maxAge: 0,
  });
  return response;
}
