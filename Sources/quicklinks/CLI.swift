import Foundation

struct CLIError: Error {
    let message: String
}

enum CLI {
    static let helpFlags: Set<String> = ["-h", "--help"]

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
        guard let command = arguments.first else {
            print(Help.overview)
            return
        }
        let rest = Array(arguments.dropFirst())
        if helpFlags.contains(command) {
            print(Help.overview)
            return
        }
        if command == "help" {
            try help(rest)
            return
        }
        if let text = Help.text(for: command), rest.contains(where: helpFlags.contains) {
            print(text)
            return
        }
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
        case "start": throw CLIError(message: "usage: quicklinks start [--show]")
        default: throw CLIError(message: "unknown command \"\(command)\"\nRun `quicklinks --help` for the list of commands.")
        }
    }

    private static func help(_ arguments: [String]) throws {
        guard let command = arguments.first else {
            print(Help.overview)
            return
        }
        guard let text = Help.text(for: command) else {
            throw CLIError(message: "no help for \"\(command)\"\nRun `quicklinks --help` for the list of commands.")
        }
        print(text)
    }

    private static func list() throws {
        let config = try ConfigStore.load()
        for (keyword, targets) in config.links.sorted(by: { $0.key < $1.key }) {
            print(([keyword] + targets.targets.map(\.summary)).joined(separator: "\t"))
        }
    }

    private static func add(_ arguments: [String]) throws {
        let (keyword, targets) = try keywordAndTargets(arguments, usage: "quicklinks add <keyword> <target>... [--with <app>]")
        try ConfigStore.update { $0.links[keyword] = LinkTargets(targets) }
        print(([keyword] + targets.map(\.summary)).joined(separator: "\t"))
    }

    private static func append(_ arguments: [String]) throws {
        let (keyword, targets) = try keywordAndTargets(arguments, usage: "quicklinks append <keyword> <target>... [--with <app>]")
        var result: [Target] = []
        try ConfigStore.update { config in
            let existing = config.links[keyword]?.targets ?? []
            let known = Set(existing.map(\.value))
            result = existing + targets.filter { !known.contains($0.value) }
            config.links[keyword] = LinkTargets(result)
        }
        print(([keyword] + result.map(\.summary)).joined(separator: "\t"))
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
            let missing = targets.filter { target in !existing.targets.contains { $0.value == target } }
            guard missing.isEmpty else {
                throw CLIError(message: "\"\(keyword)\" has no target \(missing.joined(separator: ", "))")
            }
            let remaining = existing.targets.filter { !targets.contains($0.value) }
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
        let link = Link(keyword: keyword, targets: targets.targets)
        try Opener.open(link, query: query, terminalApp: config.terminalApp)
    }

    private static func keywordAndTargets(_ arguments: [String], usage: String) throws -> (String, [Target]) {
        let (positional, app) = try withApp(arguments)
        guard positional.count >= 2 else { throw CLIError(message: "usage: \(usage)") }
        let keyword = positional[0]
        guard !keyword.contains(where: \.isWhitespace) else {
            throw CLIError(message: "keyword must not contain whitespace")
        }
        let targets = try positional.dropFirst().map { Target(value: try normalizedTarget($0), app: app) }
        return (keyword, targets)
    }

    static func withApp(_ arguments: [String]) throws -> (positional: [String], app: String?) {
        var positional: [String] = []
        var app: String?
        var remaining = arguments[...]
        while let argument = remaining.popFirst() {
            if argument == "--with" {
                guard let name = remaining.popFirst(), !name.isEmpty else {
                    throw CLIError(message: "--with needs an app name")
                }
                app = name
            } else if argument.hasPrefix("--with=") {
                app = String(argument.dropFirst("--with=".count))
            } else {
                positional.append(argument)
            }
        }
        return (positional, app)
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
