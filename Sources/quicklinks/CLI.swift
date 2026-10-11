import Foundation

struct CLIError: Error {
    let message: String
}

enum CLI {
    static let usage = """
        usage: quicklinks [command]

          (no command)                 run the launcher app (--show opens the panel at launch)
          list                         print every keyword and its targets (tab separated)
          add <keyword> <target>...    add or replace a link; several targets make a group that opens together
          append <keyword> <target>... add targets to a link, creating it if missing
          remove <keyword> [target...] delete a link, or only the given targets from it
          open <keyword> [query...]    open a link now (folders open in the terminal app)
          apps [query]                 list the applications the launcher indexes
          set hotkey <spec>            e.g. option+space, cmd+shift+k (restart the app to apply)
          set terminal <app>           e.g. iTerm, Terminal, Ghostty
          path                         print the config file path
          edit                         open the config file in the default editor
        """

    static func run(_ arguments: [String]) -> Int32 {
        do {
            try dispatch(arguments)
            return 0
        } catch let error as CLIError {
            FileHandle.standardError.write(Data("quicklinks: \(error.message)\n".utf8))
            return 1
        } catch {
            FileHandle.standardError.write(Data("quicklinks: \(error.localizedDescription)\n".utf8))
            return 1
        }
    }

    private static func dispatch(_ arguments: [String]) throws {
        guard let command = arguments.first else { throw CLIError(message: usage) }
        let rest = Array(arguments.dropFirst())
        switch command {
        case "list", "ls": try list()
        case "add": try add(rest)
        case "append": try append(rest)
        case "remove", "rm": try remove(rest)
        case "open": try open(rest)
        case "apps": apps(rest)
        case "set": try set(rest)
        case "path": print(ConfigStore.url.path)
        case "edit": try edit()
        case "help", "-h", "--help": print(usage)
        default: throw CLIError(message: "unknown command \"\(command)\"\n\n\(usage)")
        }
    }

    private static func list() throws {
        let config = try ConfigStore.load()
        for (keyword, targets) in config.links.sorted(by: { $0.key < $1.key }) {
            print(([keyword] + targets.values).joined(separator: "\t"))
        }
    }

    private static func add(_ arguments: [String]) throws {
        let (keyword, targets) = try keywordAndTargets(arguments, usage: "quicklinks add <keyword> <target>...")
        try ConfigStore.update { $0.links[keyword] = LinkTargets(targets) }
        print(([keyword] + targets).joined(separator: "\t"))
    }

    private static func append(_ arguments: [String]) throws {
        let (keyword, targets) = try keywordAndTargets(arguments, usage: "quicklinks append <keyword> <target>...")
        var result: [String] = []
        try ConfigStore.update { config in
            let existing = config.links[keyword]?.values ?? []
            result = existing + targets.filter { !existing.contains($0) }
            config.links[keyword] = LinkTargets(result)
        }
        print(([keyword] + result).joined(separator: "\t"))
    }

    private static func remove(_ arguments: [String]) throws {
        guard let keyword = arguments.first else {
            throw CLIError(message: "usage: quicklinks remove <keyword> [target...]")
        }
        let targets = Array(arguments.dropFirst())
        try ConfigStore.update { config in
            guard let existing = config.links[keyword] else {
                throw CLIError(message: "no link named \"\(keyword)\"")
            }
            if targets.isEmpty {
                config.links.removeValue(forKey: keyword)
                return
            }
            let missing = targets.filter { !existing.values.contains($0) }
            guard missing.isEmpty else {
                throw CLIError(message: "\"\(keyword)\" has no target \(missing.joined(separator: ", "))")
            }
            let remaining = existing.values.filter { !targets.contains($0) }
            config.links[keyword] = remaining.isEmpty ? nil : LinkTargets(remaining)
        }
    }

    private static func apps(_ arguments: [String]) {
        let needle = arguments.joined(separator: " ").lowercased()
        for app in AppIndex.scan() where needle.isEmpty || app.name.lowercased().contains(needle) {
            print("\(app.name)\t\(app.url.path)")
        }
    }

    private static func open(_ arguments: [String]) throws {
        guard let keyword = arguments.first else {
            throw CLIError(message: "usage: quicklinks open <keyword> [query...]")
        }
        let config = try ConfigStore.load()
        guard let targets = config.links[keyword] else {
            throw CLIError(message: "no link named \"\(keyword)\"")
        }
        let query = arguments.dropFirst().joined(separator: " ")
        let link = Link(keyword: keyword, targets: targets.values.map(Target.init(value:)))
        try Opener.open(link, query: query, terminalApp: config.terminalApp)
    }

    private static func keywordAndTargets(_ arguments: [String], usage: String) throws -> (String, [String]) {
        guard arguments.count >= 2 else { throw CLIError(message: "usage: \(usage)") }
        let keyword = arguments[0]
        guard !keyword.contains(where: \.isWhitespace) else {
            throw CLIError(message: "keyword must not contain whitespace")
        }
        let targets = try arguments.dropFirst().map(normalizedTarget)
        return (keyword, targets)
    }

    private static func set(_ arguments: [String]) throws {
        guard arguments.count == 2 else {
            throw CLIError(message: "usage: quicklinks set hotkey|terminal <value>")
        }
        let value = arguments[1]
        switch arguments[0] {
        case "hotkey":
            _ = try HotKey.parse(value)
            try ConfigStore.update { $0.hotkey = value }
        case "terminal":
            try ConfigStore.update { $0.terminal = value }
        default:
            throw CLIError(message: "unknown setting \"\(arguments[0])\"")
        }
    }

    private static func edit() throws {
        _ = try ConfigStore.load()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = [ConfigStore.url.path]
        try process.run()
        process.waitUntilExit()
    }

    private static func normalizedTarget(_ target: String) throws -> String {
        if target.contains("://") || target.hasPrefix("/") || target.hasPrefix("~") { return target }
        let relative = URL(fileURLWithPath: target, relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath))
            .standardizedFileURL
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: relative.path, isDirectory: &isDirectory), isDirectory.boolValue {
            return relative.path
        }
        throw CLIError(message: "target must be a URL with a scheme (https://...) or an existing folder path")
    }
}
