export function SiteFooter() {
  const year = new Date().getFullYear();
  return (
    <footer className="mt-auto border-t border-line">
      <div className="mx-auto flex max-w-6xl flex-col items-start justify-between gap-5 px-6 py-10 text-sm text-muted sm:flex-row sm:items-center sm:px-10">
        <div className="flex items-baseline gap-3">
          <span className="text-[12px] font-bold tracking-[0.18em] uppercase text-foreground">
            Made by Neurantra
          </span>
          <span>· {year}</span>
        </div>
        <nav className="flex flex-wrap gap-x-6 gap-y-2 text-sm">
          <a
            href="mailto:hello@neurantra.com"
            className="transition-colors hover:text-foreground"
          >
            Contact
          </a>
          <a
            href="mailto:hello@neurantra.com"
            className="transition-colors hover:text-foreground"
          >
            Support
          </a>
          <a
            href="https://neurantra.com/privacy"
            target="_blank"
            rel="noopener noreferrer"
            className="transition-colors hover:text-foreground"
          >
            Privacy
          </a>
          <a
            href="https://neurantra.com/terms"
            target="_blank"
            rel="noopener noreferrer"
            className="transition-colors hover:text-foreground"
          >
            Terms of use
          </a>
        </nav>
      </div>
    </footer>
  );
}
