# Corpus sources and review record

The shipping library contains 2,671 approved targets: 533 single words and 2,138
two-word phrases. Every target has nine distinct A–Z letters across the whole
entry and uses one of the seven allowed length patterns. All four difficulty
levels share this library. Five thousand remains a stretch goal.

`review.json` records individual decisions, sources and reasons; `report.json`
contains exact counts and a hash of that ledger. Review was performed by Codex
in two editorial passes on October 2, 2026. This is AI editorial review, not an
independent human review. A human spot-check is recommended before release,
particularly for regional vocabulary and repetitive descriptive phrases.

Source composition after review: 588 WordNet entries, 177 ESDB entries, 39
retained starter entries, and 1,867 original editorial two-word descriptions.
The original descriptions are reviewed phrases, not claims of dictionary
attestation. No arbitrary word pair is admitted just because it is an isogram.
Rejected candidates remain in the ledger and are not compiled into the app.
Duplicate compact keys are rejected, including alternate space placement.

## Reproduce the bundled corpus

Run `python3 tool/review_corpus.py` to apply the recorded editorial selections
to the candidate snapshots. Then run `python3 tool/build_corpus.py --release`.
Verify without changing files with
`python3 tool/build_corpus.py --check --release`.

The final command checks the allowed patterns, spelling characters, unique
letters, unique compact keys, review metadata, notices, generated-source parity,
and a minimum of 2,000 approved entries. Native iOS non-Debug builds and Android
release builds run that check. Python 3 must be available on the build machine.
It verifies recorded decisions; it cannot prove language quality by itself.

Dictionary import can be repeated with an isolated Python environment containing
`nltk==3.10.3` and `wordfreq==3.1.1`, then:
`python tool/import_corpus.py --esdb PATH_TO_SCOWL_PRE --nltk-data PATH_TO_NLTK_DATA`.
The source URLs and content hashes are in `../corpus_sources/manifest.json`.
The original phrase groups are in `tool/corpus_phrase_groups.py`; generated
candidate snapshots are retained so reproducing the app requires no network or
Python NLP packages. Acquisition produces candidates, never automatic approval.

ESDB and WordNet notices are bundled under `assets/licenses/` and visible through
Open-source licenses on Home. Wordfreq 3.1.1 was used only as a build-time ranking
signal for dictionary review. Its package/data attribution is retained in
`data/corpus_sources/wordfreq-NOTICE.txt`; frequency-score metadata in this review
dataset follows its CC BY-SA 4.0 data terms. The frequency model and raw scores
are not included in the app.
