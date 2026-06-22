# alfred-github-workflow

An [Alfred](https://www.alfredapp.com/) workflow that lists every GitHub repo your active `gh` account can see and opens them in your default browser — focusing an existing tab if one is already open in Chrome or Safari.

## Features

- 🔍 Fuzzy substring search across `org/repo` and descriptions — every repo you can access (personal, collaborator, org membership), no hardcoded org
- ⚡ Local disk cache with background refresh, keyed per `gh` account
- 🪟 Focuses an existing Chrome or Safari tab instead of opening duplicates
- 🔁 `gh-switch` keyword to flip the active `gh` account from inside Alfred
- 📑 Full pagination — works with accounts that span thousands of repos

## Install

1. Download the latest `github-alfred.alfredworkflow` from [Releases](../../releases/latest).
2. Double-click to import it into Alfred.

## Requirements

- macOS with [Alfred 5](https://www.alfredapp.com/) and the Powerpack
- [`gh` CLI](https://cli.github.com/) — `brew install gh`
- Authenticated: `gh auth login --hostname github.com`

## Usage

In Alfred, type:

```
gh                  → list every repo the active gh account can see
gh device           → filter by substring
gh foo bar          → match multiple terms (any order)
gh-switch           → list gh accounts; ↵ to switch the active one
gh-switch basetta   → filter the account list
```

Press <kbd>↵</kbd> on a result to open it in your default browser.

## Browser tab focusing

When a result is selected, the workflow checks Chrome and Safari for an existing tab with the same URL. If found, that tab is focused instead of opening a new one.

For **Firefox, Zen, and other Firefox-family browsers**, the workflow just opens the URL through the system default — meaning a new tab is opened even if the URL is already in another tab. This is a Firefox limitation (Firefox does not expose its tabs via AppleScript and has no preference for "switch to existing tab"), not something this workflow can work around without fragile UI scripting.

If you need deduplication for Firefox/Zen, configure a browser-picker like [Choosy](https://www.choosyosx.com/) as your default browser — it can route URLs to the browser that already has them open.

## Cache

Each `gh` account has its own cache file:

```
~/Library/Caches/org.pupazzo.github-alfred/repos-<gh-user>.json
```

- Background-refreshed when older than 60s
- Force-refetched if older than 24h, or if the cache file does not exist
- Switching accounts via `gh-switch` (or `gh auth switch` in a terminal) picks up the corresponding cache automatically; if there is no cache yet for the new account, the first query is a cold fetch
- Delete a file to force a refresh: `rm ~/Library/Caches/org.pupazzo.github-alfred/repos-*.json`

## Development

```
make build      # produces github-alfred.alfredworkflow
make install    # build and open in Alfred
make clean      # remove the built bundle
```

## Releasing

Push a `v*` tag and a GitHub Action builds the workflow and attaches it to a Release:

```bash
git tag v1.2.0
git push origin v1.2.0
```

## License

MIT
