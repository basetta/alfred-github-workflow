# alfred-github-workflow

An [Alfred](https://www.alfredapp.com/) workflow that lists repos in a GitHub organization and opens them in your default browser — focusing an existing tab if one is already open.

## Features

- 🔍 Fuzzy substring search across `org/repo` and descriptions
- ⚡ Local disk cache with background refresh (instant after first run)
- 🪟 Focuses an existing Chrome or Safari tab instead of opening duplicates
- 📑 Full pagination — works with orgs that have thousands of repos

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
ghr            → list all repos
ghr device     → filter by substring
ghr foo bar    → match multiple terms (any order)
```

Press <kbd>↵</kbd> on a result to open it in your default browser. If a tab with that URL is already open in Chrome or Safari, the existing tab is focused instead.

## Configuration

The org name is currently hardcoded in `workflow/repos.sh`:

```bash
ORG="emartech"
```

Edit the file and rebuild (`make build`) to target a different org.

## Development

```
make build      # produces github-alfred.alfredworkflow
make install    # build and open in Alfred
make clean      # remove the built bundle
```

## Releasing

Push a `v*` tag and a GitHub Action builds the workflow and attaches it to a Release:

```bash
git tag v1.0.0
git push origin v1.0.0
```

## Cache

The repo list is cached at:

```
~/Library/Caches/org.pupazzo.github-alfred/repos.json
```

- Background-refreshed when older than 60s
- Force-refetched if older than 24h
- Delete the file to force a refresh: `rm ~/Library/Caches/org.pupazzo.github-alfred/repos.json`

## License

MIT
