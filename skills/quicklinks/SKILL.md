---
name: quicklinks
description: >-
  Simon's minimal macOS quicklinks launcher. Use to add, remove, list, or open
  keyword shortcuts for URLs, URIs and folders (folders open in Finder, or any
  app with --with), or change its hotkey.
targets:
  - '*'
agentsskills:
  metadata:
    short-description: Manage Simon's hotkey quicklinks launcher via CLI
    category: infrastructure-and-tooling
---
# Quicklinks

Native Swift launcher. `⌥Space` shows every `keyword → target` mapping. The installed `quicklinks` CLI edits the same config the app reads. Config: `~/.config/quicklinks/config.json`. The app re-reads it each time the panel opens, so link changes apply immediately.

## Source

- Code: `~/workspace/dev/playground/quicklinks` (SwiftPM, `Sources/quicklinks/*.swift`, `README.md`). Read and edit it there when asked to change behavior.
- Public repo: `git@github.com:simonbalfe/quicklinks.git`, branch `main`. The folder is its own Git repo: commit and push changes there. Releases are tags (`vX.Y.Z`); after tagging, bump `url` and `sha256` in the Homebrew tap `~/workspace/dev/playground/homebrew-quicklinks/Formula/quicklinks.rb` and push it. Tests: `./test.sh`.
- After editing code, run `~/workspace/dev/playground/quicklinks/install.sh` to rebuild and reinstall the CLI and app binary, then restart the app.

## Commands

```bash
quicklinks list
quicklinks add gh https://github.com
quicklinks add g "https://www.google.com/search?q={query}"
quicklinks add ws ~/workspace
quicklinks add proj ~/projects/app --with Terminal
quicklinks add tunes spotify:playlist:123
quicklinks add here .
quicklinks remove gh
quicklinks open ws
quicklinks apps safari
quicklinks open g hello world
quicklinks set hotkey cmd+shift+k
quicklinks path
quicklinks edit
```

## Rules

- Typing in the panel also searches installed applications (indexed on every open); `quicklinks apps [query]` lists what is indexed.
- A target starting with `/` or `~`, or an existing relative folder (stored as an absolute path), is a folder: Enter opens it in Finder. Add `--with <app>` (for example `Terminal`, `iTerm`, `Cursor`) to open that target in another app; `--with` applies to every target in that command, so for mixed groups use `add` then `append --with`.
- Any other target must be a URL with a scheme (`https://...`) or a URI like `spotify:playlist:<id>`. `{query}` is replaced by the text typed after the keyword (`g hello world`).
- Keywords cannot contain whitespace. `add` overwrites an existing keyword.
- Hotkey changes need an app restart. Modifiers: `cmd`, `option`, `control`, `shift`. Keys: `a`-`z`, `0`-`9`, `space`.
- `quicklinks start` starts the app (`--show` also opens the panel). `quicklinks` with no arguments prints help in a terminal and starts the app when run without one (Login Items). `quicklinks --help` and `quicklinks <command> --help` show help.

## Install or update

```bash
~/workspace/dev/playground/quicklinks/install.sh
```

Builds a release binary and installs it to `~/.local/bin/quicklinks`. To start at login, add `~/.local/bin/quicklinks` to System Settings → General → Login Items.
