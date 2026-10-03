"use client";

import { useEffect, useState } from "react";
import { usePathname } from "next/navigation";
import { gameNames } from "../_lib/analytics/types";

const consentKey = "puzzlecub-analytics-choice";
const visitKey = "puzzlecub-usage-visit";
type Session = {
  id: string;
  seconds: number;
  sequence: number;
  games: string[];
  completed: string[];
  touched: number;
  referrer: string;
};
function newSession(): Session {
  let referrer = "";
  try {
    referrer = document.referrer ? new URL(document.referrer).hostname : "";
  } catch {}
  return {
    id: crypto.randomUUID(),
    seconds: 0,
    sequence: 0,
    games: [],
    completed: [],
    touched: Date.now(),
    referrer,
  };
}

export default function UsageAnalytics() {
  const pathname = usePathname();
  const [choice, setChoice] = useState<string | null>(null);
  const [ready, setReady] = useState(false);
  const enabled = process.env.NEXT_PUBLIC_ANALYTICS_ENABLED === "true";
  const excluded = pathname.startsWith("/admin");
  useEffect(() => {
    queueMicrotask(() => {
      try {
        setChoice(localStorage.getItem(consentKey));
      } catch {}
      setReady(true);
    });
    const sync = (event: StorageEvent) => {
      if (event.key === consentKey) setChoice(event.newValue);
    };
    window.addEventListener("storage", sync);
    return () => window.removeEventListener("storage", sync);
  }, []);
  function choose(value: string) {
    try {
      localStorage.setItem(consentKey, value);
    } catch {}
    setChoice(value);
  }
  useEffect(() => {
    if (!enabled || excluded || choice !== "allow") {
      if (choice === "deny") {
        try {
          sessionStorage.removeItem(visitKey);
        } catch {}
      }
      return;
    }
    let session = newSession();
    try {
      const saved = JSON.parse(sessionStorage.getItem(visitKey) ?? "null");
      if (
        saved &&
        Date.now() - saved.touched < 30 * 60 * 1000 &&
        saved.seconds < 86400 &&
        Array.isArray(saved.games) &&
        Array.isArray(saved.completed)
      )
        session = saved;
    } catch {}
    let lastInteraction = session.touched;
    let lastTick = Date.now();
    let lastSend = 0;
    function persist() {
      try {
        sessionStorage.setItem(visitKey, JSON.stringify(session));
      } catch {}
    }
    function allowed() {
      try {
        return localStorage.getItem(consentKey) !== "deny";
      } catch {
        return true;
      }
    }
    function send(visible = !document.hidden) {
      if (!allowed()) return;
      session.sequence++;
      persist();
      lastSend = Date.now();
      const payload = JSON.stringify({
        ...session,
        seconds: Math.floor(session.seconds),
        path: pathname,
        visible,
        consent: true,
      });
      void fetch("/api/usage", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: payload,
        keepalive: true,
      }).catch(() => {});
    }
    function interact() {
      const now = Date.now();
      if (now - session.touched > 30 * 60 * 1000 || session.seconds >= 86400)
        session = newSession();
      session.touched = now;
      lastInteraction = now;
    }
    function gameEvent(event: Event) {
      const detail = (event as CustomEvent).detail;
      if (
        !detail ||
        typeof detail.game !== "string" ||
        !Object.hasOwn(gameNames, detail.game)
      )
        return;
      interact();
      const changed =
        !session.games.includes(detail.game) ||
        (detail.completed && !session.completed.includes(detail.game));
      if (!session.games.includes(detail.game)) session.games.push(detail.game);
      if (detail.completed && !session.completed.includes(detail.game))
        session.completed.push(detail.game);
      if (changed) send();
    }
    function frameEvent(event: MessageEvent) {
      const frame = document.querySelector<HTMLIFrameElement>(
        "iframe.classic-frame",
      );
      if (
        event.origin !== window.location.origin ||
        event.source !== frame?.contentWindow ||
        event.data?.type !== "puzzlecub:classic"
      )
        return;
      gameEvent(
        new CustomEvent("puzzlecub:game", {
          detail: {
            game: "alphadoku-classic",
            completed: event.data.completed === true,
          },
        }),
      );
    }
    function visibility() {
      lastTick = Date.now();
      send();
    }
    function leaving() {
      send(false);
    }
    window.addEventListener("pointerdown", interact, { passive: true });
    window.addEventListener("keydown", interact);
    window.addEventListener("scroll", interact, { passive: true });
    window.addEventListener("puzzlecub:game", gameEvent);
    window.addEventListener("message", frameEvent);
    document.addEventListener("visibilitychange", visibility);
    window.addEventListener("pagehide", leaving);
    const timer = setInterval(() => {
      const now = Date.now();
      if (!document.hidden && now - lastInteraction < 60000)
        session.seconds += Math.min(2, (now - lastTick) / 1000);
      lastTick = now;
      if (
        !document.hidden &&
        now - lastSend >= 15000 &&
        now - session.touched < 30 * 60 * 1000
      )
        send();
    }, 1000);
    send();
    return () => {
      clearInterval(timer);
      send(false);
      window.removeEventListener("pointerdown", interact);
      window.removeEventListener("keydown", interact);
      window.removeEventListener("scroll", interact);
      window.removeEventListener("puzzlecub:game", gameEvent);
      window.removeEventListener("message", frameEvent);
      document.removeEventListener("visibilitychange", visibility);
      window.removeEventListener("pagehide", leaving);
    };
  }, [pathname, choice, enabled, excluded]);

  if (!enabled || excluded || !ready) return null;
  if (choice)
    return pathname === "/privacy" ? (
      <div className="usage-choice">
        <span>
          Usage analytics: {choice === "allow" ? "allowed" : "declined"}.
        </span>
        <button onClick={() => choose(choice === "allow" ? "deny" : "allow")}>
          {choice === "allow" ? "Stop analytics" : "Allow analytics"}
        </button>
      </div>
    ) : null;
  return (
    <aside className="usage-choice" aria-label="Optional usage analytics">
      <p>
        Help improve PuzzleCub? Allow visit and game-activity analytics,
        including active time and a network address when enabled. Games work
        either way. <a href="/privacy">Privacy details</a>
      </p>
      <button onClick={() => choose("allow")}>Allow analytics</button>
      <button onClick={() => choose("deny")}>No thanks</button>
    </aside>
  );
}
