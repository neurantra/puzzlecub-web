"use client";
import { useEffect, useState } from "react";
// These games preserve the mobile app's local age declaration. Unknown and
// protected players must not trigger display ads or load Google's SDK.
const familyGames = new Set(["/mazewords", "/slide-and-sort", "/fillthejar"]);
export function useGameAdsAllowed(path: string) {
  const [audience, setAudience] = useState<{
    path: string;
    allowed: boolean;
  } | null>(null);
  useEffect(() => {
    function receive(event: MessageEvent) {
      const frame = document.querySelector<HTMLIFrameElement>(
        "iframe.collection-frame",
      );
      if (
        event.origin !== location.origin ||
        event.source !== frame?.contentWindow ||
        event.data?.type !== "puzzlecub:audience"
      )
        return;
      setAudience({ path, allowed: event.data.allowed === true });
    }
    window.addEventListener("message", receive);
    return () => window.removeEventListener("message", receive);
  }, [path]);
  return (
    !familyGames.has(path) || (audience?.path === path && audience.allowed)
  );
}
