import Foundation

struct CLIError: Error {
    let message: String
}

enum CLI {
    static let usage = """
        usage: quicklinks [command]

          (no command)                 run the launcher app (--show opens the panel at launch)
          list                         print every keyword and target
          add <keyword> <target>       add or replace a link; target is a URL or a folder path
          remove <keyword>             delete a link
          open <keyword> [query...]    open a link now (folders open in the terminal app)
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
        case "remove", "rm": try remove(rest)
        case "open": try open(rest)
        case "set": try set(rest)
        case "path": print(ConfigStore.url.path)
        case "edit": try edit()
        case "help", "-h", "--help": print(usage)
        default: throw CLIError(message: "unknown command \"\(command)\"\n\n\(usage)")
        }
    }

    private static func list() throws {
        let config = try ConfigStore.load()
        for (keyword, target) in config.links.sorted(by: { $0.key < $1.key }) {
            print("\(keyword)\t\(target)")
        }
    }

    private static func add(_ arguments: [String]) throws {
        guard arguments.count == 2 else { throw CLIError(message: "usage: quicklinks add <keyword> <target>") }
        let keyword = arguments[0]
        guard !keyword.contains(where: \.isWhitespace) else {
            throw CLIError(message: "keyword must not contain whitespace")
        }
        let target = try normalizedTarget(arguments[1])
        try ConfigStore.update { $0.links[keyword] = target }
        print("\(keyword)\t\(target)")
    }

    private static func remove(_ arguments: [String]) throws {
        guard arguments.count == 1 else { throw CLIError(message: "usage: quicklinks remove <keyword>") }
        try ConfigStore.update { config in
            guard config.links.removeValue(forKey: arguments[0]) != nil else {
                throw CLIError(message: "no link named \"\(arguments[0])\"")
            }
        }
    }

    private static func open(_ arguments: [String]) throws {
        guard let keyword = arguments.first else {
            throw CLIError(message: "usage: quicklinks open <keyword> [query...]")
        }
        let config = try ConfigStore.load()
        guard let target = config.links[keyword] else {
            throw CLIError(message: "no link named \"\(keyword)\"")
        }
        let query = arguments.dropFirst().joined(separator: " ")
        try Opener.open(Link(keyword: keyword, template: target), query: query, terminalApp: config.terminalApp)
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
