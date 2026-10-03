"use client";

import { useCallback, useEffect, useState } from "react";
import { gameNames, type UsageReport } from "../_lib/analytics/types";

function duration(seconds: number) {
  const rounded = Math.round(seconds);
  return `${Math.floor(rounded / 60)}m ${rounded % 60}s`;
}
function date(value: string) {
  return new Date(value).toLocaleString();
}

export default function Dashboard() {
  const [days, setDays] = useState("7");
  const [game, setGame] = useState("");
  const [report, setReport] = useState<UsageReport | null>(null);
  const [error, setError] = useState("");
  const [updated, setUpdated] = useState("");
  const [loading, setLoading] = useState(false);
  const refresh = useCallback(
    async (signal?: AbortSignal) => {
      setLoading(true);
      try {
        const response = await fetch(
          `/api/admin/usage?days=${days}&game=${game}`,
          { cache: "no-store", signal },
        );
        if (response.status === 401) {
          window.location.assign("/admin");
          return;
        }
        if (!response.ok)
          throw new Error(
            "Usage data is unavailable. Check the analytics database configuration and try again.",
          );
        setReport(await response.json());
        setUpdated(new Date().toLocaleTimeString());
        setError("");
      } catch (e) {
        if (!signal?.aborted)
          setError(e instanceof Error ? e.message : "Unable to load usage.");
      } finally {
        if (!signal?.aborted) setLoading(false);
      }
    },
    [days, game],
  );
  useEffect(() => {
    const controller = new AbortController();
    queueMicrotask(() => {
      if (!controller.signal.aborted) void refresh(controller.signal);
    });
    const timer = setInterval(() => {
      if (!document.hidden) void refresh(controller.signal);
    }, 30000);
    return () => {
      controller.abort();
      clearInterval(timer);
    };
  }, [refresh]);

  return (
    <>
      <header className="admin-header">
        <div>
          <span className="admin-kicker">PuzzleCub · Private analytics</span>
          <h1>How are people playing?</h1>
          <p className="admin-muted">
            Visits, real game interactions, and time spent on your site.
          </p>
        </div>
        <form action="/api/admin/logout" method="post">
          <button>Sign out</button>
        </form>
      </header>
      <div className="admin-filters">
        <label>
          Period
          <select
            value={days}
            onChange={(e) => {
              setReport(null);
              setDays(e.target.value);
            }}
          >
            <option value="1">Last 24 hours</option>
            <option value="7">Last 7 days</option>
            <option value="30">Last 30 days</option>
            <option value="90">Last 90 days</option>
          </select>
        </label>
        <label>
          Played game
          <select
            value={game}
            onChange={(e) => {
              setReport(null);
              setGame(e.target.value);
            }}
          >
            <option value="">All visits</option>
            {Object.entries(gameNames).map(([id, name]) => (
              <option key={id} value={id}>
                {name}
              </option>
            ))}
          </select>
        </label>
        <button disabled={loading} onClick={() => void refresh()}>
          {loading ? "Refreshing…" : "Refresh"}
        </button>
        <span className="admin-muted" role="status">
          {updated && `Updated ${updated} · refreshes every 30s`}
        </span>
      </div>
      {error && (
        <p className="admin-error" role="alert">
          {error} {report && "Showing the last successful report."}
        </p>
      )}
      {report && (
        <>
          <div className="admin-stats">
            {[
              ["Visits", report.total.toLocaleString()],
              [
                "Visits with play",
                `${report.players.toLocaleString()} (${report.total ? Math.round((report.players / report.total) * 100) : 0}%)`,
              ],
              ["Online now · estimated", report.online.toLocaleString()],
              ["Average active time", duration(report.averageActiveSeconds)],
              ["Visit/game completions", report.completions.toLocaleString()],
            ].map(([label, value]) => (
              <div className="admin-stat" key={label}>
                <span className="admin-muted">{label}</span>
                <strong>{value}</strong>
              </div>
            ))}
          </div>
          <section className="admin-panel admin-games">
            <h2>Game engagement</h2>
            {report.games.length ? (
              report.games.map((g) => (
                <div key={g.id} className="admin-game-row">
                  <strong>{gameNames[g.id] ?? g.id}</strong>
                  <span>
                    {g.players} playing visits · {g.completions} completed
                  </span>
                </div>
              ))
            ) : (
              <p className="admin-muted">
                No game interactions recorded in this period.
              </p>
            )}
          </section>
          <section className="admin-panel">
            <h2>Visit activity</h2>
            <p className="admin-muted">
              Latest {report.visits.length} of {report.total} visits. Dates are
              shown in your browser’s time zone.
            </p>
            {report.visits.length ? (
              <div className="admin-table-wrap">
                <table>
                  <thead>
                    <tr>
                      {[
                        "Visitor / IP",
                        "Visit started",
                        "Did they play?",
                        "Games played",
                        "Active time",
                        "Visit span",
                        "Last seen",
                        "Status",
                        "Pages / source",
                      ].map((h) => (
                        <th key={h} scope="col">
                          {h}
                        </th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {report.visits.map((v) => (
                      <tr key={v.id}>
                        <td>
                          <code>{v.id.slice(0, 8)}</code>
                          <small>{v.ip ?? "IP not collected"}</small>
                          <small>{v.device}</small>
                        </td>
                        <td>{date(v.startedAt)}</td>
                        <td>{v.games.length ? "Yes" : "No"}</td>
                        <td>
                          {v.games.map((g) => gameNames[g] ?? g).join(", ") ||
                            "—"}
                          {v.completedGames.length > 0 && (
                            <small>
                              Completed:{" "}
                              {v.completedGames
                                .map((g) => gameNames[g] ?? g)
                                .join(", ")}
                            </small>
                          )}
                        </td>
                        <td>{duration(v.activeSeconds)}</td>
                        <td>
                          {duration(
                            Math.max(
                              0,
                              (Date.parse(v.lastSeen) -
                                Date.parse(v.startedAt)) /
                                1000,
                            ),
                          )}
                        </td>
                        <td>{date(v.lastSeen)}</td>
                        <td
                          className={v.online ? "admin-online" : "admin-muted"}
                        >
                          {v.online ? "● Online" : "Offline"}
                        </td>
                        <td>
                          {v.entryPath}
                          <small>Last: {v.lastPath}</small>
                          <small>{v.referrer || "Direct / unknown"}</small>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ) : (
              <div className="admin-empty">
                <h2>No visits yet</h2>
                <p>
                  Records appear after tracking is configured and visitors allow
                  usage analytics. Past activity cannot be reconstructed.
                </p>
              </div>
            )}
          </section>
        </>
      )}
      <p className="admin-muted admin-note">
        A visit is a browser-tab session, renewed after 30 minutes without
        activity. Players do not sign in. “Played” means a game action, such as
        entering a letter or using a hint. Active time counts visible time with
        interaction in the last 60 seconds; visit span includes breaks. Online
        means a visible heartbeat within 45 seconds. Completion counts are
        distinct visit/game pairs, not total puzzles solved. These are
        estimates; blocked analytics, declined consent, connection loss, and
        bots can affect totals. IP addresses are network addresses, not reliable
        identities.
      </p>
    </>
  );
}
