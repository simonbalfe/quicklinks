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
          add <keyword> <target>...        add or replace a link; several targets make a group
          append <keyword> <target>...     add targets to a link, creating it if missing
          remove <keyword> [target...]     delete a link, or only the given targets
          open <keyword> [query...]        open a link now

        SETTINGS
          set hotkey <spec>                change the global hotkey (restart the app to apply)
          set terminal <app>               change the app that opens folders
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
            the keyword followed by each of its targets.
            """,
        "add": """
            usage: quicklinks add <keyword> <target>...

            Add a link, or replace the link that already uses the keyword. A target is a URL
            with a scheme (https://...) or a folder path. Several targets make a group that
            opens together. Use {query} in a URL to insert text typed after the keyword.

            examples:
              quicklinks add gh https://github.com
              quicklinks add notes ~/Documents/notes
              quicklinks add morning https://mail.google.com https://calendar.google.com
            """,
        "append": """
            usage: quicklinks append <keyword> <target>...

            Add targets to an existing link, skipping ones it already has. Creates the link
            if the keyword is new.
            """,
        "remove": """
            usage: quicklinks remove <keyword> [target...]

            Delete the link. With targets, remove only those targets from the link; removing
            the last target deletes the link. Alias: rm.
            """,
        "open": """
            usage: quicklinks open <keyword> [query...]

            Open a link from the terminal. Folders open in the terminal app. The query text
            replaces {query} in the link's URLs.

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
                   quicklinks set terminal <app>

            hotkey    modifiers cmd, option, control, shift plus a key a-z, 0-9 or space,
                      for example option+space or cmd+shift+k. Restart the app to apply.
            terminal  the app that opens folder links, for example iTerm, Terminal or
                      Ghostty. Applies the next time the panel opens.
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
