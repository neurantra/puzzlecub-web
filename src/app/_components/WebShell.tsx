import Link from "next/link";
import ModeCarousel from "./ModeCarousel";
import Image from "next/image";
export function WebHeader() {
  return (
    <header className="web-header">
      <Link href="/" className="brand">
        <span className="brand-symbol">
          p<span>c</span>
        </span>
        puzzlecub<span className="brand-dot">.</span>
      </Link>
      <nav aria-label="Main navigation">
        <Link href="/alphadoku">Play</Link>
        <Link href="/challenges">Challenges</Link>
        <Link href="/learn">Learn</Link>
        <Link href="/mobile-apps" className="nav-apps">
          Our apps ↗
        </Link>
      </nav>
    </header>
  );
}
export function WebFooter() {
  return (
    <footer className="web-footer">
      <div>
        <Link className="brand" href="/">
          puzzlecub.
        </Link>
        <p>A little thought. A bright discovery.</p>
        <small>Made by Neurantra · Independent games for curious minds.</small>
      </div>
      <nav aria-label="Footer navigation">
        <Link href="/about">About & contact</Link>
        <Link href="/privacy">Privacy</Link>
        <Link href="/terms">Terms</Link>
        <Link href="/credits">Credits & licenses</Link>
        <Link href="/mobile-apps">Mobile apps</Link>
      </nav>
    </footer>
  );
}
export function ModeArt({ mega = false }: { mega?: boolean }) {
  const chars = mega ? "ABCDEFGHIJKLMNOPQRSTUVWXY" : "ALGORITHM";
  return (
    <div className={`mode-art ${mega ? "mega-art" : ""}`} aria-hidden="true">
      <div
        className="art-grid"
        style={{ gridTemplateColumns: `repeat(${mega ? 5 : 3},1fr)` }}
      >
        {Array.from(chars).map((c, i) => (
          <span key={i} className={i % (mega ? 6 : 4) === 0 ? "gold-cell" : ""}>
            {c}
          </span>
        ))}
      </div>
    </div>
  );
}
export function WebShell({ children }: { children: React.ReactNode }) {
  return (
    <>
      <a className="skip-link" href="#main">
        Skip to content
      </a>
      <WebHeader />
      {children}
      <WebFooter />
    </>
  );
}
export function ModeCards() {
  return (
    <ModeCarousel>
      <div className="mode-cards">
        <Link href="/alphadoku/classic" className="mode-card">
          <ModeArt />
          <div className="card-copy">
            <span className="tag">9 × 9 · THE ORIGINAL</span>
            <h3>
              One hidden line.
              <br />A whole new Sudoku.
            </h3>
            <p>
              Nine unique letters. A word hiding in plain sight. Four levels to
              find your rhythm.
            </p>
            <strong>
              Play Classic <span>↗</span>
            </strong>
          </div>
        </Link>
        <Link href="/alphadoku/mega" className="mode-card">
          <ModeArt mega />
          <div className="card-copy">
            <span className="tag">25 × 25 · THE BIG PICTURE</span>
            <h3>
              More letters.
              <br />A little more ambition.
            </h3>
            <p>
              A to Y, twenty-five boxes, and room to think. Pure alphabet
              Sudoku, without a hidden line.
            </p>
            <strong>
              Play Mega <span>↗</span>
            </strong>
          </div>
        </Link>
      </div>
    </ModeCarousel>
  );
}
export function AlphaIdentity() {
  return (
    <div className="alpha-identity">
      <Image src="/alphadoku/icon.png" width={44} height={44} alt="" />
      <span>
        ALPHADOKU <small>LETTER SUDOKU</small>
      </span>
    </div>
  );
}
