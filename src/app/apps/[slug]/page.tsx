import type { Metadata } from "next";
import Image from "next/image";
import { notFound } from "next/navigation";
import { SiteHeader } from "../../_components/SiteHeader";
import { SiteFooter } from "../../_components/SiteFooter";
import { StoreLinks } from "../../_components/StoreLinks";
import { STANDALONE_APPS, getStandaloneApp } from "../../_lib/games";
export function generateStaticParams() {
  return STANDALONE_APPS.map((app) => ({ slug: app.slug }));
}
export async function generateMetadata({
  params,
}: PageProps<"/apps/[slug]">): Promise<Metadata> {
  const app = getStandaloneApp((await params).slug);
  return app
    ? {
        title: `${app.name} — Games from Neurantra`,
        description: app.description,
      }
    : {};
}
export default async function AppPage({ params }: PageProps<"/apps/[slug]">) {
  const app = getStandaloneApp((await params).slug);
  if (!app) notFound();
  return (
    <div className="flex flex-1 flex-col">
      <SiteHeader variant="subpage" />
      <main className="section-wrap grid w-full items-center gap-12 lg:grid-cols-[1.2fr_1fr]">
        <div>
          <Image
            src={app.icon}
            alt=""
            width={100}
            height={100}
            className="mb-8 rounded-3xl"
          />
          <p className="eyebrow">A standalone app from Neurantra</p>
          <h1 className="text-5xl font-extrabold tracking-tight sm:text-6xl">
            {app.name}
          </h1>
          <h2 className="mt-6 text-2xl font-bold text-accent">{app.tagline}</h2>
          <p className="mt-6 text-lg leading-relaxed text-muted">
            {app.description}
          </p>
          <p className="mt-4 leading-relaxed text-muted">{app.detail}</p>
          <div className="mt-8">
            <StoreLinks
              name={app.name}
              appStoreUrl={app.appStoreUrl}
              playStoreUrl={app.playStoreUrl}
              appStoreComingSoon={app.appStoreComingSoon}
              playStoreComingSoon={app.playStoreComingSoon}
            />
          </div>
          <p className="mt-4 text-sm text-muted">{app.note}</p>
          <p className="mt-6 text-sm text-muted">
            A separate download from Puzzlecub.
          </p>
        </div>
        <Image
          src={app.screenshot}
          alt={`${app.name} gameplay and features`}
          width={700}
          height={1517}
          priority
          sizes="(min-width: 1024px) 320px, 80vw"
          className="mx-auto h-auto w-full max-w-[320px] rounded-2xl border border-line"
        />
      </main>
      <SiteFooter />
    </div>
  );
}
