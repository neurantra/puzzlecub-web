// Publisher and slot IDs are public. These switches default to no ad requests.
export function adConfiguration() {
  const candidate = process.env.ADSENSE_CLIENT ?? "";
  const client = /^ca-pub-\d{16}$/.test(candidate) ? candidate : "";
  const test = process.env.ADS_TEST_MODE === "true";
  const enabled =
    !!client &&
    process.env.ADS_ENABLED === "true" &&
    (test || process.env.ADS_CONSENT_READY === "true");
  const slot = (value: string | undefined) =>
    /^\d{10}$/.test(value ?? "") ? value! : "";
  return {
    client,
    enabled,
    test,
    h5: enabled && process.env.H5_ADS_ENABLED === "true",
    slots: {
      content: slot(process.env.ADSENSE_CONTENT_SLOT),
      gameplay: slot(process.env.ADSENSE_GAMEPLAY_SLOT),
    },
  };
}
