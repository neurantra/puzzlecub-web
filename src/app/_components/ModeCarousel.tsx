"use client";
import { useRef } from "react";
export default function ModeCarousel({
  children,
}: {
  children: React.ReactNode;
}) {
  const ref = useRef<HTMLDivElement>(null);
  function move(last: boolean) {
    const el = ref.current?.querySelector(".mode-cards");
    if (el)
      el.scrollTo({
        left: last ? el.scrollWidth : 0,
        behavior: window.matchMedia("(prefers-reduced-motion: reduce)").matches
          ? "instant"
          : "smooth",
      });
  }
  return (
    <div ref={ref}>
      <div className="carousel-controls" aria-label="Puzzle carousel controls">
        <span>Swipe to explore both modes</span>
        <button onClick={() => move(false)} aria-label="Show Classic">
          ←
        </button>
        <button onClick={() => move(true)} aria-label="Show Mega">
          →
        </button>
      </div>
      {children}
    </div>
  );
}
