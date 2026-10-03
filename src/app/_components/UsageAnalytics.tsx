"use client";

import { useEffect, useRef, useState } from "react";
import { usePathname } from "next/navigation";
import { gameForPage, pageCategory } from "../_lib/analytics/types";

const preferenceKey = "puzzlecub-analytics-choice";
function privacySignal() {
  return (
    navigator.doNotTrack === "1" ||
    (navigator as Navigator & { globalPrivacyControl?: boolean })
      .globalPrivacyControl === true
  );
}
function permitted() {
  if (privacySignal()) return false;
  try {
    return localStorage.getItem(preferenceKey) !== "deny";
  } catch {
    return true;
  }
}

export default function UsageAnalytics() {
  const pathname = usePathname();
  const [choice, setChoice] = useState("pending");
  const deniedInMemory = useRef(false);
  const enabled = process.env.NEXT_PUBLIC_ANALYTICS_ENABLED === "true";
  useEffect(() => {
    // Remove the previous tracker ID. Only an opt-out preference remains in storage.
    try {
      sessionStorage.removeItem("puzzlecub-usage-visit");
    } catch {}
    queueMicrotask(() => setChoice(permitted() ? "allow" : "deny"));
    const sync = (event: StorageEvent) => {
      if (event.key === preferenceKey || event.key === null)
        setChoice(permitted() ? "allow" : "deny");
    };
    window.addEventListener("storage", sync);
    return () => window.removeEventListener("storage", sync);
  }, []);

  useEffect(() => {
    const page = pageCategory(pathname);
    if (
      !enabled ||
      choice !== "allow" ||
      !page ||
      /(^|\.)puzzlecub\.app$/.test(location.hostname)
    )
      return;
    const game = gameForPage(page);
    function allowed() {
      return !deniedInMemory.current && permitted();
    }
    let started = false,
      stopped = false,
      played = false,
      completed = false,
      puzzleFinished = false;
    let active = 0,
      playing = 0,
      lastTick = performance.now(),
      interaction = performance.now();
    let adActive = false;
    let lastPulse = -Infinity;
    const retries = new Set<ReturnType<typeof setTimeout>>();
    function post(body: string, retry = true) {
      if (!allowed()) return;
      void fetch("/api/usage", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body,
        keepalive: true,
        referrerPolicy: "no-referrer",
      })
        .then((response) => {
          if (response.status >= 500) throw new Error("Unavailable");
        })
        .catch(() => {
          if (!retry || stopped || !allowed()) return;
          const timer = setTimeout(() => {
            retries.delete(timer);
            if (!stopped) post(body, false);
          }, 1500);
          retries.add(timer);
        });
    }
    function tick() {
      const now = performance.now();
      if (!adActive && !document.hidden && now - interaction < 60000) {
        const delta = Math.min(2, (now - lastTick) / 1000);
        active += delta;
        if (played && !puzzleFinished) playing += delta;
      }
      lastTick = now;
    }
    function send(views = 0, plays = 0, completions = 0, heartbeat = false) {
      if (!allowed()) return;
      tick();
      const seconds = Math.min(30, Math.floor(active));
      const playSeconds = Math.min(seconds, Math.floor(playing));
      active -= seconds;
      playing -= playSeconds;
      const now = performance.now();
      const pulse =
        heartbeat &&
        !document.hidden &&
        now - interaction < 60000 &&
        now - lastPulse >= 14000;
      if (pulse) lastPulse = now;
      if (!views && !plays && !completions && !seconds && !pulse) return;
      // A fresh ID identifies this delivery only, never a browser, visit, or person.
      post(
        JSON.stringify({
          version: 2,
          eventId: crypto.randomUUID(),
          page,
          views,
          plays,
          completions,
          seconds,
          playSeconds,
          pulse,
        }),
      );
    }
    function begin() {
      if (!started) {
        started = true;
        send(1, 0, 0, true);
      }
    }
    function interact() {
      tick();
      interaction = performance.now();
    }
    function gameEvent(event: Event) {
      const detail = (event as CustomEvent).detail;
      if (!detail || detail.game !== game || !game || document.hidden) return;
      begin();
      interact();
      const firstPlay = !played,
        firstCompletion = detail.completed === true && !completed;
      played = true;
      if (firstCompletion) completed = true;
      puzzleFinished = detail.completed === true;
      send(0, Number(firstPlay), Number(firstCompletion));
    }
    function adStart() {
      tick();
      adActive = true;
    }
    function adEnd() {
      lastTick = performance.now();
      adActive = false;
    }
    function frameEvent(event: MessageEvent) {
      const frame = document.querySelector<HTMLIFrameElement>(
        "iframe.classic-frame, iframe.chaturang-frame",
      );
      if (
        event.origin !== location.origin ||
        event.source !== frame?.contentWindow
      )
        return;
      if (event.data?.type === "puzzlecub:ad-state") {
        if (event.data.active === true) adStart();
        else adEnd();
        return;
      }
      if (
        event.data?.type !==
        (game === "alphadoku-classic"
          ? "puzzlecub:classic"
          : `puzzlecub:${game}`)
      )
        return;
      gameEvent(
        new CustomEvent("puzzlecub:game", {
          detail: {
            game,
            completed: event.data.completed === true,
          },
        }),
      );
    }
    function visibility() {
      if (started) send();
      lastTick = performance.now();
    }
    function leaving() {
      if (started) send();
    }
    // Defer the first count so React's development effect replay cannot count it twice.
    const initial = setTimeout(begin, 0);
    const tickTimer = setInterval(tick, 1000);
    const heartbeat = setInterval(() => {
      begin();
      send(0, 0, 0, true);
    }, 15000);
    window.addEventListener("pointerdown", interact, { passive: true });
    window.addEventListener("keydown", interact);
    window.addEventListener("scroll", interact, { passive: true });
    window.addEventListener("puzzlecub:game", gameEvent);
    window.addEventListener("message", frameEvent);
    window.addEventListener("puzzlecub:ad-start", adStart);
    window.addEventListener("puzzlecub:ad-end", adEnd);
    window.addEventListener("pagehide", leaving);
    document.addEventListener("visibilitychange", visibility);
    return () => {
      stopped = true;
      clearTimeout(initial);
      clearInterval(tickTimer);
      clearInterval(heartbeat);
      retries.forEach(clearTimeout);
      if (started) send();
      window.removeEventListener("pointerdown", interact);
      window.removeEventListener("keydown", interact);
      window.removeEventListener("scroll", interact);
      window.removeEventListener("puzzlecub:game", gameEvent);
      window.removeEventListener("message", frameEvent);
      window.removeEventListener("puzzlecub:ad-start", adStart);
      window.removeEventListener("puzzlecub:ad-end", adEnd);
      window.removeEventListener("pagehide", leaving);
      document.removeEventListener("visibilitychange", visibility);
    };
  }, [pathname, choice, enabled]);

  if (!enabled || pathname !== "/privacy" || choice === "pending") return null;
  function toggle() {
    const next = choice === "deny" ? "allow" : "deny";
    deniedInMemory.current = next === "deny";
    try {
      localStorage.setItem(preferenceKey, next);
    } catch {}
    setChoice(privacySignal() ? "deny" : next);
  }
  return (
    <section className="usage-choice" aria-label="Anonymous analytics settings">
      <span>
        Anonymous usage statistics: {choice === "deny" ? "off" : "on"}.
      </span>
      {privacySignal() ? (
        <span>Your browser’s privacy signal is respected.</span>
      ) : (
        <button onClick={toggle}>
          {choice === "deny"
            ? "Enable anonymous analytics"
            : "Stop anonymous analytics"}
        </button>
      )}
    </section>
  );
}
