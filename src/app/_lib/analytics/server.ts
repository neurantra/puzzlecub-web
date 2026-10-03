import "server-only";
import { createHmac, timingSafeEqual, randomBytes } from "node:crypto";
import { isIP } from "node:net";
import { cookies } from "next/headers";
import { neon } from "@neondatabase/serverless";

export const adminCookie = "puzzlecub_admin";
export const noStore = {
  "Cache-Control": "private, no-store",
  "X-Robots-Tag": "noindex, nofollow",
};
export async function boundedBody(request: Request, limit: number) {
  const reader = request.body?.getReader();
  if (!reader) return "";
  const chunks: Uint8Array[] = [];
  let size = 0;
  while (true) {
    const { value, done } = await reader.read();
    if (done) break;
    size += value.length;
    if (size > limit) {
      await reader.cancel();
      throw new RangeError("Request too large");
    }
    chunks.push(value);
  }
  return Buffer.concat(chunks).toString("utf8");
}
export function configured() {
  return Boolean(process.env.DATABASE_URL);
}
export function authConfigured() {
  return (
    (process.env.ADMIN_PASSWORD?.length ?? 0) >= 16 &&
    (process.env.ADMIN_SESSION_SECRET?.length ?? 0) >= 32
  );
}
function mac(value: string) {
  if (!authConfigured())
    throw new Error("Admin authentication is not configured");
  return createHmac("sha256", process.env.ADMIN_SESSION_SECRET!)
    .update(value)
    .digest("hex");
}
function equal(a: string, b: string) {
  const left = Buffer.from(a),
    right = Buffer.from(b);
  return left.length === right.length && timingSafeEqual(left, right);
}
export function validPassword(value: string) {
  return (
    authConfigured() && equal(mac(value), mac(process.env.ADMIN_PASSWORD!))
  );
}
export function adminToken() {
  const payload = `${Date.now() + 8 * 60 * 60 * 1000}.${randomBytes(24).toString("hex")}`;
  return `${payload}.${mac(`${payload}.${process.env.ADMIN_PASSWORD}`)}`;
}
export async function isAdmin() {
  if (!authConfigured()) return false;
  const token = (await cookies()).get(adminCookie)?.value ?? "";
  const [expiry, nonce, signature, extra] = token.split(".");
  if (
    extra ||
    !/^\d{13}$/.test(expiry ?? "") ||
    !/^[a-f0-9]{48}$/.test(nonce ?? "") ||
    !signature
  )
    return false;
  return (
    Number(expiry) > Date.now() &&
    equal(signature, mac(`${expiry}.${nonce}.${process.env.ADMIN_PASSWORD}`))
  );
}
export function sameOrigin(request: Request) {
  const url = new URL(request.url);
  const host = request.headers.get("host") ?? url.host;
  const protocol = process.env.VERCEL === "1" ? "https:" : url.protocol;
  const expected = process.env.SITE_ORIGIN ?? `${protocol}//${host}`;
  return request.headers.get("origin") === expected;
}
export function clientIp(request: Request) {
  // Only configure a header your hosting proxy overwrites. Never blindly trust X-Forwarded-For.
  const header =
    process.env.ANALYTICS_TRUSTED_IP_HEADER ??
    (process.env.VERCEL === "1" ? "x-vercel-forwarded-for" : undefined);
  if (!header) return null;
  const candidate = request.headers.get(header)?.split(",")[0].trim() ?? "";
  return isIP(candidate) ? candidate : null;
}
export function networkKey(request: Request, scope = "login") {
  return mac(`${scope}:${clientIp(request) ?? "unknown-network"}`);
}
export async function rpc<T>(
  name: string,
  body: Record<string, unknown>,
): Promise<T> {
  if (!configured()) throw new Error("Analytics database is not configured");
  const parameters: Record<string, string[]> = {
    usage_rate_limit: ["p_key", "p_limit", "p_seconds"],
    aggregate_record: [
      "p_event",
      "p_page",
      "p_views",
      "p_plays",
      "p_completions",
      "p_seconds",
      "p_play_seconds",
      "p_pulse",
    ],
    aggregate_report: ["p_days", "p_game"],
    usage_cleanup: [],
  };
  if (!Object.hasOwn(parameters, name))
    throw new Error("Unknown analytics operation");
  const keys = parameters[name];
  const sql = neon(process.env.DATABASE_URL!, {
    fetchOptions: { cache: "no-store", signal: AbortSignal.timeout(8000) },
  });
  const rows = await sql.query(
    `select puzzlecub_usage.${name}(${keys.map((_, i) => `$${i + 1}`).join(",")}) as result`,
    keys.map((k) => body[k]),
  );
  return rows[0].result as T;
}
export async function rateLimit(key: string, limit: number, seconds: number) {
  return rpc<boolean>("usage_rate_limit", {
    p_key: key,
    p_limit: limit,
    p_seconds: seconds,
  });
}
