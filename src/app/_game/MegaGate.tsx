"use client";
import { useSyncExternalStore } from "react";
import Link from "next/link";
import Mega from "./Mega";

const desktopPointer = "(hover: hover) and (pointer: fine)";
const minimumWidth = 1200;
const minimumHeight = 700;

function isMobileDevice() {
  return (
    /Android|iPhone|iPad|iPod|Mobile/i.test(navigator.userAgent) ||
    (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1)
  );
}
function canPlayMega() {
  return (
    !isMobileDevice() &&
    window.innerWidth >= minimumWidth &&
    window.innerHeight >= minimumHeight &&
    window.matchMedia(desktopPointer).matches
  );
}
function subscribe(onChange: () => void) {
  const pointer = window.matchMedia(desktopPointer);
  window.addEventListener("resize", onChange);
  pointer.addEventListener("change", onChange);
  return () => {
    window.removeEventListener("resize", onChange);
    pointer.removeEventListener("change", onChange);
  };
}
export default function MegaGate({ week }: { week?: string }) {
  const available = useSyncExternalStore(subscribe, canPlayMega, () => null);
  if (available === null)
    return (
      <p className="mega-check" role="status">
        Checking your display…
      </p>
    );
  if (!available)
    return (
      <section
        className="mega-unavailable"
        aria-labelledby="mega-unavailable-title"
      >
        <span className="tag">A BIGGER CANVAS FOR THE BIG PICTURE</span>
        <h2 id="mega-unavailable-title">Mega needs a desktop or laptop.</h2>
        <p>
          To keep all 625 cells readable at once, open Mega on a computer with a
          mouse or trackpad and a browser window at least 1,200 pixels wide and
          700 pixels tall. Maximize your window if you are already on a
          computer.
        </p>
        <Link className="button primary" href="/alphadoku/classic">
          Play Classic on this device →
        </Link>
      </section>
    );
  return <Mega week={week} />;
}
