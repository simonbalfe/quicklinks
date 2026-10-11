# quicklinks

A tiny Mac launcher. Press a hotkey, type a short word, press Enter. A website, folder or app opens.

```
⌥Space  →  type "gh"  →  Enter  →  github.com opens
```

No account, no cloud, no settings screen. One small app and one JSON file. It also has a command line, so you (or an AI agent) can add a lot of links fast.

## Install

You need a Mac on macOS 14 or newer and Homebrew.

```sh
brew install simonbalfe/quicklinks/quicklinks
quicklinks start
```

The first install builds the app on your Mac, which needs Swift. If it asks, run `xcode-select --install` and try again.

To start it every time you log in:

```sh
brew services start quicklinks
```

## Use it

1. Press `⌥Space` to open the panel.
2. Type a keyword. `↑` and `↓` pick a result.
3. Press `Enter` to open it. `Esc` closes the panel.

It starts with a few links already set up: `gh`, `mail`, `cal`, `g`, `yt`, `ws`, `dl`.

Installed apps show up as you type too, so `safari` launches Safari. Your links rank above apps.

## Add your own links

```sh
quicklinks add gh https://github.com
quicklinks add notes ~/Documents/notes
quicklinks add g "https://www.google.com/search?q={query}"
```

- A link opens a **URL** (like `https://...` or `vscode://...`), a **URI** (like `spotify:playlist:<id>`) or a **folder**.
- URLs and URIs open in the app macOS picks for them (your default browser, Spotify, and so on).
- Folders open in your terminal app by default (iTerm; change it with `quicklinks set terminal Terminal`).
- Any single target can use a different app with `--with` (see below), which overrides those defaults.
- `{query}` is replaced by what you type after the keyword. `g best pizza` searches Google for "best pizza".
- Adding a keyword that already exists replaces it.

## Open several things at once

Give one keyword more than one target and they all open together.

```sh
quicklinks add morning https://mail.google.com https://calendar.google.com ~/Documents/notes
quicklinks append morning https://news.ycombinator.com
```

## Open with a specific app

Add `--with <app>` to send a link or folder to an app instead of the default. This applies to that link only and overrides the browser, the app macOS picks, or the terminal.

```sh
quicklinks add ws ~/workspace --with Cursor
quicklinks add work https://github.com --with "Google Chrome"
```

`quicklinks apps` lists the app names you can use.

## Let an agent add your links

The command line is plain and predictable, so a coding agent can set up a whole set of links from one sentence.

You say:

> add quicklinks for my supabase dashboard, my slop project folder and my spotify playlist, plus one called all that opens all three

The agent runs:

```sh
quicklinks add db https://abcdefghijklmnopqrst.supabase.co
quicklinks add slop ~/dev/slop
quicklinks add tunes spotify:playlist:123
quicklinks add all https://abcdefghijklmnopqrst.supabase.co ~/dev/slop spotify:playlist:123
```

Now `⌥Space`, then:

- `db` opens the dashboard in your browser
- `slop` opens the folder in your terminal
- `tunes` opens the playlist in Spotify
- `all` opens all three at once

Changes apply the next time the panel opens. There is nothing to restart.

## Commands

```sh
quicklinks list                           # show all links
quicklinks add <keyword> <target>...      # add or replace a link (add --with <app> to pick an app)
quicklinks append <keyword> <target>...   # add targets to a link
quicklinks remove <keyword> [target...]   # delete a link, or only some targets
quicklinks open <keyword> [text]          # open a link from the terminal
quicklinks apps [query]                   # list apps
quicklinks set terminal Ghostty           # default app for folders (a link's --with overrides it)
quicklinks set hotkey cmd+shift+k         # change the hotkey, then restart the app
quicklinks edit                           # open the config file
quicklinks start                          # run the app in the background
quicklinks --help                         # help (also: quicklinks <command> --help)
```

## Config file

Everything is stored in `~/.config/quicklinks/config.json`. You can edit it by hand.

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

A target is either a string or `{"target": "...", "with": "App"}`. `with` is the app that opens that one target. `terminal` is only the default app for folders that have no `with`.

Links are re-read every time the panel opens. The hotkey is only read when the app starts.

Hotkeys combine `cmd`, `option`, `control` or `shift` with a key (`a`-`z`, `0`-`9`, or `space`), for example `cmd+shift+k`.

## Build from source

```sh
git clone https://github.com/simonbalfe/quicklinks
cd quicklinks
./install.sh
```

This installs to `~/.local/bin/quicklinks`. Make sure that folder is on your `PATH`.

Run the tests with `./test.sh`.

## License

MIT
