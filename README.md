# quicklinks

Minimal macOS launcher: Raycast's Quicklinks plus an application launcher. A global hotkey opens a panel listing every `keyword → target` mapping. Targets are URLs or folders; folders open in your terminal app. Typing also searches installed applications.

## Install

```sh
./install.sh
```

Builds a release binary and installs it to `~/.local/bin/quicklinks`. Run `quicklinks` to start the background app (no Dock icon); add it to System Settings → General → Login Items to start at login.

## Use

- `⌥Space` toggles the panel (configurable).
- Type to filter by keyword or target. `↑`/`↓` select, `Enter` opens, `Esc` or clicking away closes.
- URLs containing `{query}` take the text after the keyword: `g hello world` opens the Google search for `hello world`.
- Targets starting with `/` or `~` are folders and open in the terminal app (default `iTerm`).
- Installed apps (from `/Applications`, `/System/Applications`, its `Utilities` and `CoreServices/Applications`, Finder, Safari and `~/Applications`) are indexed on every open and appear when you type; `Enter` launches. Quicklinks rank ahead of apps on equal matches.
- `⌘E` opens the config file.

## CLI

```sh
quicklinks list
quicklinks add gh https://github.com
quicklinks add ws ~/workspace
quicklinks add here .
quicklinks remove gh
quicklinks open ws
quicklinks apps [query]
quicklinks set terminal Ghostty
quicklinks set hotkey cmd+shift+k
quicklinks path
quicklinks edit
```

`quicklinks` with no arguments runs the app; `quicklinks --show` also opens the panel at launch.

## Config

`~/.config/quicklinks/config.json`, created on first run and re-read every time the panel opens. The hotkey is read at launch only.

```json
{
  "hotkey": "option+space",
  "terminal": "iTerm",
  "links": {
    "gh": "https://github.com",
    "g": "https://www.google.com/search?q={query}",
    "ws": "~/workspace"
  }
}
```

Hotkey modifiers: `cmd`, `option`, `control`, `shift`. Keys: `a`–`z`, `0`–`9`, `space`. If the hotkey is taken (for example by Raycast), the app exits with an error; change the hotkey and relaunch.
