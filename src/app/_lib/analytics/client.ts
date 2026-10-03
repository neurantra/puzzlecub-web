export function trackGame(game: string, completed = false) {
  window.dispatchEvent(
    new CustomEvent("puzzlecub:game", { detail: { game, completed } }),
  );
}
