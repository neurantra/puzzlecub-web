"use client";

import Image from "next/image";
import Link from "next/link";
import { useEffect, useState } from "react";

const HOME_LINKS = [
  { href: "#games", label: "Puzzlecub", section: "games" },
  { href: "#apps", label: "More apps", section: "apps" },
] as const;

export type SiteHeaderVariant = "home" | "subpage";

export function SiteHeader({ variant = "home" }: { variant?: SiteHeaderVariant }) {
  const [active, setActive] = useState<string | null>(null);

  useEffect(() => {
    if (variant !== "home") return;
    const observer = new IntersectionObserver(
      (entries) => {
        const visible = entries
          .filter(e => e.isIntersecting)
          .sort((a, b) => b.intersectionRatio - a.intersectionRatio)[0];
        if (visible) setActive(visible.target.id);
      },
      { rootMargin: "-40% 0px -50% 0px", threshold: [0, 0.25, 0.5, 0.75, 1] },
    );
    HOME_LINKS.forEach(({ section }) => {
      const el = document.getElementById(section);
      if (el) observer.observe(el);
    });
    return () => observer.disconnect();
  }, [variant]);

  return (
    <header className="sticky top-0 z-40 border-b border-line bg-background/85 backdrop-blur-md">
      <div className="mx-auto max-w-6xl px-6 sm:px-10">
        <div className="flex items-center justify-between py-5">
          <Link
            href="/"
            className="flex items-center gap-3 transition-opacity hover:opacity-80"
          >
            <Image
              src="/puzzlecub/icon.webp"
              alt=""
              width={36}
              height={36}
              priority
              className="h-9 w-9"
            />
            <span className="text-[17px] font-bold tracking-tight text-foreground">
              Puzzlecub
            </span>
          </Link>

          {variant === "subpage" ? (
            <Link
              href="/"
              className="text-sm text-muted transition-colors hover:text-foreground"
            >
              ← Back to home
            </Link>
          ) : (
            <nav className="flex gap-4 text-xs sm:gap-7 sm:text-sm text-muted">
              {HOME_LINKS.map(({ href, label, section }) => (
                <NavLink key={href} href={href} active={active === section}>
                  {label}
                </NavLink>
              ))}
            </nav>
          )}
        </div>
      </div>
    </header>
  );
}

function NavLink({
  href,
  active,
  children,
}: {
  href: string;
  active: boolean;
  children: React.ReactNode;
}) {
  return (
    <a
      href={href}
      data-active={active}
      className="relative transition-colors hover:text-foreground data-[active=true]:text-foreground after:absolute after:-bottom-1 after:left-0 after:h-[1.5px] after:w-full after:origin-left after:scale-x-0 after:bg-accent after:transition-transform after:duration-300 hover:after:scale-x-100 data-[active=true]:after:scale-x-100"
    >
      {children}
    </a>
  );
}
