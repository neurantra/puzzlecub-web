"use client";
import Script from "next/script";
import { useGameAdsAllowed } from "./useGameAdsAllowed";
import { useEffect, useRef, useState } from "react";
import { usePathname } from "next/navigation";

type AdConfig = {
  enabled: boolean;
  client: string;
  test: boolean;
  slots: { content: string; gameplay: string };
};
declare global {
  interface Window {
    puzzlecubAds?: {
      settings: Promise<AdConfig>;
      display: (element: HTMLElement, slot: string) => void;
      markPlayed: () => void;
      between: () => Promise<void>;
    };
    puzzlecubBetweenGames?: () => Promise<void>;
  }
}
export async function betweenGames() {
  await window.puzzlecubAds?.between();
}
export function AdvertisingScript() {
  const path = usePathname();
  const allowed = useGameAdsAllowed(path);
  if (path.startsWith("/admin") || !allowed) return null;
  return (
    <Script
      src="/game-ads.js"
      strategy="afterInteractive"
      onReady={() => {
        window.dispatchEvent(new Event("puzzlecub:ads-configured"));
      }}
    />
  );
}
export function AdPlacement({ gameplay = false }: { gameplay?: boolean }) {
  const path = usePathname();
  const allowed = useGameAdsAllowed(path);
  const [config, setConfig] = useState<AdConfig | null>(null);
  const ref = useRef<HTMLModElement>(null);
  const kind = gameplay ? "gameplay" : "content";
  useEffect(() => {
    let live = true;
    function configure() {
      window.puzzlecubAds?.settings.then((value) => {
        if (live) setConfig(value);
      });
    }
    configure();
    window.addEventListener("puzzlecub:ads-configured", configure);
    return () => {
      live = false;
      window.removeEventListener("puzzlecub:ads-configured", configure);
    };
  }, []);
  useEffect(() => {
    function request() {
      if (allowed && ref.current && config?.slots[kind])
        window.puzzlecubAds?.display(ref.current, config.slots[kind]);
    }
    request();
    window.addEventListener("puzzlecub:ads-ready", request);
    return () => window.removeEventListener("puzzlecub:ads-ready", request);
  }, [config, kind, path, allowed]);
  if (
    !allowed ||
    !config?.enabled ||
    !config.slots[kind] ||
    (typeof navigator !== "undefined" &&
      (navigator.doNotTrack === "1" ||
        (navigator as Navigator & { globalPrivacyControl?: boolean })
          .globalPrivacyControl))
  )
    return null;
  return (
    <aside
      className={`ad-placement ${gameplay ? "gameplay-ad" : "content-ad"}`}
      aria-label="Advertisement"
    >
      <small>Advertisement</small>
      <ins
        key={`${path}-${kind}`}
        ref={ref}
        className="adsbygoogle"
        style={{ display: "block" }}
        data-ad-client={config.client}
        data-ad-slot={config.slots[kind]}
        data-ad-format="horizontal"
        data-full-width-responsive="true"
        {...(config.test ? { "data-adtest": "on" } : {})}
      />
    </aside>
  );
}
export function ContentAdvertisement() {
  const path = usePathname();
  // Rich editorial pages; never the admin, legal pages, or duplicate game units.
  return path === "/" ||
    path === "/alphadoku" ||
    path === "/challenges" ||
    path === "/about" ||
    path.startsWith("/learn") ? (
    <AdPlacement />
  ) : null;
}

export function AdvertisingPrivacy() {
  const [ready, setReady] = useState(false);
  useEffect(() => {
    let live = true;
    const target = window as Window & {
      googlefc?: {
        callbackQueue: object[];
        showRevocationMessage?: () => void;
      };
    };
    target.googlefc ??= { callbackQueue: [] };
    target.googlefc.callbackQueue ??= [];
    target.googlefc.callbackQueue.push({
      CONSENT_API_READY: () => {
        if (live) setReady(true);
      },
    });
    return () => {
      live = false;
    };
  }, []);
  if (!ready) return null;
  return (
    <button
      className="text-link"
      onClick={() => {
        const target = window as Window & {
          googlefc?: { showRevocationMessage?: () => void };
        };
        target.googlefc?.showRevocationMessage?.();
      }}
    >
      Privacy & cookie settings
    </button>
  );
}
