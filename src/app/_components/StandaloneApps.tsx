import Image from "next/image";
import Link from "next/link";
import { STANDALONE_APPS } from "../_lib/games";
import { StoreLinks } from "./StoreLinks";
export function StandaloneApps() {
  return (
    <section id="apps" className="scroll-mt-24 border-b border-line">
      <div className="section-wrap">
        <p className="eyebrow">More from Neurantra</p>
        <h2 className="section-title">Find your next favorite.</h2>
        <p className="mt-5 max-w-2xl text-lg leading-relaxed text-muted">
          Explore Alphadoku, Fill the Jar, Mapopia, Maze Words, and Slide
          &amp; Sort. Each is a separate app with its own puzzles and download.
        </p>
        <div className="mt-10 grid gap-6 lg:grid-cols-2">
          {STANDALONE_APPS.map((app) => (
            <article
              key={app.slug}
              className="overflow-hidden rounded-3xl border border-line bg-surface"
            >
              <div className="grid gap-6 p-6 sm:grid-cols-[1fr_150px] sm:p-8">
                <div>
                  <Image
                    src={app.icon}
                    alt=""
                    width={64}
                    height={64}
                    className="rounded-2xl"
                  />
                  <h3 className="mt-5 text-2xl font-bold">
                    <Link
                      href={`/apps/${app.slug}`}
                      className="hover:underline"
                    >
                      {app.name}
                    </Link>
                  </h3>
                  <p className="mt-2 font-semibold text-accent">
                    {app.tagline}
                  </p>
                  <p className="mt-4 text-sm leading-relaxed text-muted">
                    {app.description}
                  </p>
                </div>
                <Link
                  href={`/apps/${app.slug}`}
                  className="mx-auto self-center"
                  aria-label={`Explore ${app.name}`}
                >
                  <Image
                    src={app.screenshot}
                    alt={`${app.name} app screenshot`}
                    width={700}
                    height={1517}
                    sizes="180px"
                    className="h-auto w-[160px] rounded-xl"
                  />
                </Link>
              </div>
              <div className="border-t border-line p-6 sm:px-8">
                <StoreLinks
                  name={app.name}
                  appStoreUrl={app.appStoreUrl}
                  playStoreUrl={app.playStoreUrl}
                  appStoreComingSoon={app.appStoreComingSoon}
                  playStoreComingSoon={app.playStoreComingSoon}
                />
                <p className="mt-4 text-xs leading-relaxed text-muted">
                  {app.note}
                </p>
              </div>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
