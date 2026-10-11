# quicklinks

A tiny macOS launcher. Press a hotkey, type a short keyword, press Enter. Your website, folder or app opens.

```
⌥Space  →  type "gh"  →  Enter  →  github.com opens
```

No account, no cloud, no settings screen. One small native app and one JSON file.

## What it does

| You type | What happens |
|---|---|
| `gh` | Opens https://github.com |
| `g best pizza` | Searches Google for "best pizza" |
| `ws` | Opens your workspace folder in the terminal |
| `safari` | Launches Safari (any installed app works) |

- **Links**: give any website a short keyword.
- **Search links**: put `{query}` in a URL and whatever you type after the keyword is filled in.
- **Folders**: a keyword can point at a folder; it opens in your terminal app.
- **Apps**: it also finds and launches the apps you have installed.
- **Fast and light**: runs in the background with no Dock icon.
- **Plain config**: edit one JSON file, or use the command line. Changes apply the next time the panel opens.

## Install

You need a Mac running macOS 14 or newer and the Swift toolchain (`xcode-select --install` provides it).

```sh
git clone <this repository>
cd quicklinks
./install.sh
```

This builds the app and copies it to `~/.local/bin/quicklinks`. Make sure that folder is on your `PATH`, then start it:

```sh
quicklinks
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

## All commands

```sh
quicklinks list                      # show all links
quicklinks add <keyword> <target>    # add or replace a link
quicklinks remove <keyword>          # delete a link
quicklinks open <keyword> [text]     # open a link from the terminal
quicklinks apps [query]              # list indexed apps
quicklinks set terminal Ghostty      # app used to open folders (default: iTerm)
quicklinks set hotkey cmd+shift+k    # change the hotkey (restart the app after)
quicklinks path                      # print the config file location
quicklinks edit                      # open the config file
quicklinks --show                    # start the app and show the panel
```

Running `quicklinks` with no arguments starts the app.

## Config file

Located at `~/.config/quicklinks/config.json`. It is created on first run.

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

Links are re-read every time the panel opens. The hotkey is read only when the app starts.

**Hotkey format**: combine `cmd`, `option`, `control`, `shift` with a key (`a`-`z`, `0`-`9`, or `space`), for example `cmd+shift+k`. If another app already uses the hotkey, quicklinks exits with an error. Pick a different one and start it again.

## How apps are found

Each time the panel opens, quicklinks scans `/Applications`, `/System/Applications` (including `Utilities`), `~/Applications`, Finder and Safari. Your own links rank above apps when both match.
