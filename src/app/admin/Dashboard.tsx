"use client";

import { useCallback, useEffect, useState } from "react";
import {
  gameNames,
  pageNames,
  type UsageReport,
} from "../_lib/analytics/types";

function duration(seconds: number) {
  const rounded = Math.round(seconds);
  return `${Math.floor(rounded / 60)}m ${rounded % 60}s`;
}
function percent(part: number, total: number) {
  return total ? `${Math.round((part / total) * 100)}%` : "—";
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
            Anonymous totals, real game interactions, and time spent playing.
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
            <option value="1">Today (UTC)</option>
            <option value="7">7 days including today</option>
            <option value="30">30 days including today</option>
            <option value="90">90 days including today</option>
          </select>
        </label>
        <label>
          Game
          <select
            value={game}
            onChange={(e) => {
              setReport(null);
              setGame(e.target.value);
            }}
          >
            <option value="">All pages</option>
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
              ["Page views", report.views.toLocaleString()],
              ["Playing game views", report.plays.toLocaleString()],
              ["Game view → play", percent(report.plays, report.gameViews)],
              [
                "Active tabs · estimate",
                report.onlineEstimate.toLocaleString(),
              ],
              ["Active playing time", duration(report.playSeconds)],
              ["Views with a finish", report.completions.toLocaleString()],
            ].map(([label, value]) => (
              <div className="admin-stat" key={label}>
                <span className="admin-muted">{label}</span>
                <strong>{value}</strong>
              </div>
            ))}
          </div>
          <section className="admin-panel admin-games">
            <h2>Game engagement</h2>
            <div className="admin-table-wrap">
              <table>
                <thead>
                  <tr>
                    {[
                      "Game",
                      "Page views",
                      "Playing views",
                      "Play rate",
                      "Views with a finish",
                      "Active play time",
                    ].map((h) => (
                      <th key={h} scope="col">
                        {h}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {Object.entries(gameNames)
                    .filter(([id]) => !game || game === id)
                    .map(([id, name]) => {
                      const page = report.pages.find(
                        (p) =>
                          p.page ===
                          `/alphadoku/${id.replace("alphadoku-", "")}`,
                      );
                      return (
                        <tr key={id}>
                          <th scope="row">{name}</th>
                          <td>{page?.views ?? 0}</td>
                          <td>{page?.plays ?? 0}</td>
                          <td>{percent(page?.plays ?? 0, page?.views ?? 0)}</td>
                          <td>{page?.completions ?? 0}</td>
                          <td>{duration(page?.playSeconds ?? 0)}</td>
                        </tr>
                      );
                    })}
                </tbody>
              </table>
            </div>
          </section>
          <section className="admin-panel admin-games">
            <h2>Daily usage</h2>
            <p className="admin-muted">
              UTC calendar days · anonymous measurement began{" "}
              {new Date(report.since).toLocaleDateString()}.
            </p>
            <div
              className="admin-chart"
              role="img"
              aria-label="Daily page views; exact counts are in the table below"
            >
              {report.daily.map((d) => (
                <div
                  className="admin-chart-day"
                  key={d.day}
                  title={`${d.day}: ${d.views} views, ${d.plays} playing views`}
                >
                  <span>{d.views}</span>
                  <div
                    className="admin-chart-bar"
                    style={{
                      height: `${Math.max(2, (d.views / Math.max(1, ...report.daily.map((v) => v.views))) * 100)}px`,
                    }}
                  />
                  <small>{d.day.slice(5)}</small>
                </div>
              ))}
            </div>
            <div className="admin-table-wrap">
              <table>
                <thead>
                  <tr>
                    {[
                      "Day (UTC)",
                      "Page views",
                      "Playing views",
                      "Views with a finish",
                      "Active site time",
                      "Active play time",
                    ].map((h) => (
                      <th key={h} scope="col">
                        {h}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {[...report.daily].reverse().map((d) => (
                    <tr key={d.day}>
                      <th scope="row">{d.day}</th>
                      <td>{d.views}</td>
                      <td>{d.plays}</td>
                      <td>{d.completions}</td>
                      <td>{duration(d.activeSeconds)}</td>
                      <td>{duration(d.playSeconds)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>
          <section className="admin-panel">
            <h2>Popular pages</h2>
            {report.pages.length ? (
              <div className="admin-table-wrap">
                <table>
                  <thead>
                    <tr>
                      <th scope="col">Page</th>
                      <th scope="col">Views</th>
                      <th scope="col">Active time</th>
                    </tr>
                  </thead>
                  <tbody>
                    {report.pages.map((p) => (
                      <tr key={p.page}>
                        <th scope="row">{pageNames[p.page] ?? p.page}</th>
                        <td>{p.views}</td>
                        <td>{duration(p.activeSeconds)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ) : (
              <p className="admin-empty">
                No anonymous activity recorded in this period yet.
              </p>
            )}
          </section>
        </>
      )}
      <p className="admin-muted admin-note">
        These are page views, not unique people or visits. Reloading or opening
        another tab counts another view. A playing view has at least one real
        game action. A view with a finish solved a puzzle or ended a Chaturang
        match (including a forfeit) after a player move; additional finishes in
        that same view are not counted separately. Active time counts visible
        time with interaction in the last 60 seconds. Active play time follows
        game actions, pauses after a finish, and resumes on the next game
        action. Active tabs is estimated from anonymous heartbeats in the last
        three complete 15-second buckets; it can lag by about a minute and is
        not an exact headcount. Daily counters use event dates, so rates near
        date boundaries are approximate. Opt-outs, privacy signals, blockers,
        bots and network loss can affect totals. No visitor profiles, IP
        addresses or browsing histories are stored in analytics.
      </p>
    </>
  );
}
