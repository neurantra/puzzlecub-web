import { APP_STORE_URL, PLAY_STORE_URL } from "../_lib/games";
type Props = {
  appStoreUrl?: string;
  playStoreUrl?: string;
  name?: string;
  appStoreComingSoon?: boolean;
  playStoreComingSoon?: boolean;
};
export function StoreLinks({
  appStoreUrl = APP_STORE_URL,
  playStoreUrl = PLAY_STORE_URL,
  name = "Puzzlecub",
  appStoreComingSoon = false,
  playStoreComingSoon = false,
}: Props) {
  return (
    <div className="flex flex-wrap gap-3">
      {appStoreComingSoon ? (
        <span
          className="store-link border-line text-muted"
          aria-label={`${name} for iOS is coming soon`}
        >
          iOS · Coming soon
        </span>
      ) : (
        <a
          className="store-link store-link-primary"
          href={appStoreUrl}
          target="_blank"
          rel="noopener noreferrer"
          aria-label={`${name} on the App Store`}
        >
          App Store ↗
        </a>
      )}
      {playStoreComingSoon ? (
        <span
          className="store-link border-line text-muted"
          aria-label={`${name} for Android is coming soon`}
        >
          Android · Coming soon
        </span>
      ) : (
        <a
          className="store-link"
          href={playStoreUrl}
          target="_blank"
          rel="noopener noreferrer"
          aria-label={`${name} on Google Play`}
        >
          Google Play ↗
        </a>
      )}
    </div>
  );
}
