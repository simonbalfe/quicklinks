enum Help {
    static let overview = """
        quicklinks: keyword launcher for links, folders and apps

        USAGE
          quicklinks <command> [arguments]
          quicklinks <command> --help      show help for one command

        APP
          start [--show]                   run the launcher in the background (--show also opens the panel)

        LINKS
          list                             print every keyword and its targets
          add <keyword> <target>... [--with <app>]
                                           add or replace a link; several targets make a group;
                                           --with opens the targets in that app
          append <keyword> <target>... [--with <app>]
                                           add targets to a link, creating it if missing
          remove <keyword> [target...]     delete a link, or only the given targets
          open <keyword> [query...]        open a link now

        SETTINGS
          set hotkey <spec>                change the global hotkey (restart the app to apply)
          apps [query]                     list the applications the launcher indexes

        CONFIG FILE
          path                             print the config file path
          edit                             open the config file in the default editor

        OPTIONS
          -h, --help                       show this help
          --show                           start the app and open the panel immediately

        EXAMPLES
          quicklinks add gh https://github.com
          quicklinks add g "https://www.google.com/search?q={query}"
          quicklinks add morning https://mail.google.com https://calendar.google.com
          quicklinks add ws ~/workspace --with Cursor
          quicklinks add proj ~/projects/app --with Terminal
          quicklinks open g best pizza
          quicklinks set hotkey cmd+shift+k

        Config: ~/.config/quicklinks/config.json
        """

    private static let aliases = ["ls": "list", "rm": "remove"]

    private static let commands: [String: String] = [
        "start": """
            usage: quicklinks start [--show]

            Run the launcher app in the background. It has no Dock icon and listens for the
            global hotkey. With --show the panel opens immediately.

            Running `quicklinks` with no arguments in a terminal shows this help. Without a
            terminal (for example from Login Items) it starts the app.
            """,
        "list": """
            usage: quicklinks list

            Print every link, one per line, sorted by keyword. Columns are tab separated:
            the keyword followed by each of its targets. A target opened with a specific app
            is shown as "target (App)".
            """,
        "add": """
            usage: quicklinks add <keyword> <target>... [--with <app>]

            Add a link, or replace the link that already uses the keyword. A target is a URL
            with a scheme (https://...), a URI such as spotify:playlist:<id>, or a folder path.
            Several targets make a group that opens together. Use {query} in a URL to insert
            text typed after the keyword.

            --with <app> opens the targets in that app instead of the default. By default URLs
            open in the app macOS picks (your browser, Spotify, ...) and folders open in
            Finder. Run `quicklinks apps` to see app names.

            examples:
              quicklinks add gh https://github.com
              quicklinks add notes ~/Documents/notes
              quicklinks add morning https://mail.google.com https://calendar.google.com
              quicklinks add ws ~/workspace --with Cursor
              quicklinks add proj ~/projects/app --with Terminal
              quicklinks add work https://github.com --with "Google Chrome"
            """,
        "append": """
            usage: quicklinks append <keyword> <target>... [--with <app>]

            Add targets to an existing link, skipping ones it already has. Creates the link
            if the keyword is new. --with opens the added targets in that app.
            """,
        "remove": """
            usage: quicklinks remove <keyword> [target...]

            Delete the link. With targets, remove only those targets from the link; removing
            the last target deletes the link. Alias: rm.
            """,
        "open": """
            usage: quicklinks open <keyword> [query...]

            Open a link from the terminal. Folders open in Finder unless the target has an app
            set with --with. The query text replaces {query} in the link's URLs.

            example:
              quicklinks open g best pizza
            """,
        "apps": """
            usage: quicklinks apps [query]

            List the installed applications the launcher indexes, optionally filtered by
            name.
            """,
        "set": """
            usage: quicklinks set hotkey <spec>

            hotkey    modifiers cmd, option, control, shift plus a key a-z, 0-9 or space,
                      for example option+space or cmd+shift+k. Restart the app to apply.
            """,
        "path": """
            usage: quicklinks path

            Print the config file path.
            """,
        "edit": """
            usage: quicklinks edit

            Open the config file in the default editor.
            """
    ]

    static func text(for command: String) -> String? {
        commands[aliases[command] ?? command]
    }
}
