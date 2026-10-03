import { authConfigured, isAdmin } from "../_lib/analytics/server";
import Dashboard from "./Dashboard";
import "./admin.css";

export const metadata = {
  title: "PuzzleCub · Admin",
  robots: { index: false, follow: false },
};
export const dynamic = "force-dynamic";

export default async function Admin({
  searchParams,
}: {
  searchParams: Promise<{ error?: string }>;
}) {
  const { error } = await searchParams;
  const authenticated = await isAdmin();
  return (
    <main className="admin-shell">
      {authenticated ? (
        <Dashboard />
      ) : (
        <section className="admin-panel admin-login">
          <span className="admin-kicker">PuzzleCub · Owner access</span>
          <h1>Site activity</h1>
          <p className="admin-muted">
            Sign in to view anonymous site and game statistics.
          </p>
          {!authConfigured() ? (
            <p className="admin-error">
              Admin access is not configured. Set the server-side admin password
              and session secret using the setup guide.
            </p>
          ) : (
            <form action="/api/admin/login" method="post">
              <label htmlFor="admin-password">
                Admin password
                <input
                  id="admin-password"
                  type="password"
                  name="password"
                  required
                  autoComplete="current-password"
                  maxLength={256}
                />
              </label>
              {error && (
                <p className="admin-error" role="alert">
                  {error === "limit"
                    ? "Too many attempts. Try again in 15 minutes."
                    : error === "setup"
                      ? "The authentication service is unavailable. Check the database configuration."
                      : "Incorrect password. Please try again."}
                </p>
              )}
              <button type="submit">Sign in securely</button>
            </form>
          )}
          <p className="admin-muted admin-note">
            This login is for the site owner. Players can continue to play
            without an account.
          </p>
        </section>
      )}
    </main>
  );
}
