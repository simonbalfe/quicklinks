# quicklinks

A tiny macOS launcher. Press a hotkey, type a short keyword, press Enter. Your website, folder or app opens.

```
⌥Space  →  type "gh"  →  Enter  →  github.com opens
```

No account, no cloud, no settings screen. One small native app and one JSON file.

## Key features

- **Global hotkey**: `⌥Space` opens the panel from anywhere. Type, press Enter, done.
- **Keyword links**: give any website a short keyword.
- **Search links**: put `{query}` in a URL and the text you type after the keyword is filled in (`g best pizza`).
- **Groups**: one keyword opens several links at once (`morning` opens mail, calendar and notes).
- **Folders**: a keyword can point at a folder; it opens in your terminal app.
- **Open with**: send any link or folder to a specific app instead of the default (`ws` opens in your editor).
- **App launcher**: installed apps show up as you type. Your links rank above apps.
- **Full command line**: everything the app can do is also available from `quicklinks` (add, append, remove, list, open, set hotkey and terminal), so it is easy to script.
- **Plain config**: one JSON file you can hand-edit. Link changes apply the next time the panel opens.
- **Fast and light**: native Swift, runs in the background with no Dock icon.

## What it does

| You type | What happens |
|---|---|
| `gh` | Opens https://github.com |
| `g best pizza` | Searches Google for "best pizza" |
| `morning` | Opens every link in the `morning` group |
| `ws` | Opens your workspace folder in the terminal |
| `safari` | Launches Safari (any installed app works) |

## Install

You need a Mac running macOS 14 or newer and the Swift toolchain (`xcode-select --install` provides it).

```sh
git clone <this repository>
cd quicklinks
./install.sh
```

This builds the app and copies it to `~/.local/bin/quicklinks`. Make sure that folder is on your `PATH`, then start it:

```sh
quicklinks start
```

To start it automatically, add `~/.local/bin/quicklinks` under System Settings → General → Login Items.

## Use it

1. Press `⌥Space` (Option + Space) to open the panel.
2. Type to filter. `↑` / `↓` pick a result.
3. Press `Enter` to open it. `Esc` or clicking away closes the panel.

Other shortcut: `⌘E` opens your config file.

## Add your own links

```sh
quicklinks add gh https://github.com
quicklinks add g "https://www.google.com/search?q={query}"
quicklinks add notes ~/Documents/notes
quicklinks remove gh
quicklinks list
```

A link target is either:

- a **URL** with a scheme, such as `https://...`, or
- a **folder** path starting with `/` or `~` (or `.` for the current folder).

Keywords cannot contain spaces. Adding a keyword that already exists replaces it.

## Groups

Give a keyword more than one target and they all open together.

```sh
quicklinks add morning https://mail.google.com https://calendar.google.com ~/Documents/notes
quicklinks append morning https://news.ycombinator.com
quicklinks remove morning https://news.ycombinator.com
```

Type `morning`, press Enter, and every target opens. A `{query}` target in a group is filled with the text you type after the keyword. If one target fails to open, the others still open and the error is shown.

## Open with a specific app

By default URLs open in your default browser and folders open in your terminal app. Add `--with <app>` to open the targets in another app.

```sh
quicklinks add ws ~/workspace --with Cursor
quicklinks add work https://github.com --with "Google Chrome"
quicklinks append morning ~/Documents/notes --with Obsidian
```

The app name is the name `quicklinks apps` lists. `--with` applies to the targets named in that command, so one group can send different targets to different apps. `quicklinks list` shows these targets as `target (App)`. If the app cannot be opened, the error names it.

## All commands

```sh
quicklinks list                      # show all links
quicklinks add <keyword> <target>... [--with <app>]  # add or replace a link; several targets make a group
quicklinks append <keyword> <target>... [--with <app>]  # add targets to a link (creates it if missing)
quicklinks remove <keyword> [target...]  # delete a link, or only the given targets
quicklinks open <keyword> [text]     # open a link from the terminal
quicklinks apps [query]              # list indexed apps
quicklinks set terminal Ghostty      # app used to open folders (default: iTerm)
quicklinks set hotkey cmd+shift+k    # change the hotkey (restart the app after)
quicklinks path                      # print the config file location
quicklinks edit                      # open the config file
quicklinks start                    # run the app in the background
quicklinks start --show             # run the app and show the panel
quicklinks --help                   # show help (also: quicklinks <command> --help)
```

Running `quicklinks` with no arguments in a terminal shows the help. Without a terminal, for example from Login Items, it starts the app.

## Config file

Located at `~/.config/quicklinks/config.json`. It is created on first run.

```json
{
  "hotkey": "option+space",
  "terminal": "iTerm",
  "links": {
    "gh": "https://github.com",
    "g": "https://www.google.com/search?q={query}",
    "ws": {"target": "~/workspace", "with": "Cursor"},
    "morning": ["https://mail.google.com", "https://calendar.google.com"]
  }
}
```

A target is either a string or an object with `target` and optional `with` (the app to open it with). Groups can mix both.

Links are re-read every time the panel opens. The hotkey is read only when the app starts.

**Hotkey format**: combine `cmd`, `option`, `control`, `shift` with a key (`a`-`z`, `0`-`9`, or `space`), for example `cmd+shift+k`. If another app already uses the hotkey, quicklinks exits with an error. Pick a different one and start it again.

## How apps are found

Each time the panel opens, quicklinks scans `/Applications`, `/System/Applications` (including `Utilities`), `~/Applications`, Finder and Safari. Your own links rank above apps when both match.
