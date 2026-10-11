import Foundation

struct Config: Codable {
    static let defaultHotkey = "option+space"
    static let defaultTerminal = "iTerm"

    var hotkey: String
    var terminal: String?
    var links: [String: String]

    var terminalApp: String { terminal ?? Config.defaultTerminal }
}

enum ConfigStore {
    static let url = FileManager.default.homeDirectoryForCurrentUser
        .appending(path: ".config/quicklinks/config.json")

    static let starter = Config(
        hotkey: Config.defaultHotkey,
        terminal: Config.defaultTerminal,
        links: [
            "gh": "https://github.com",
            "mail": "https://mail.google.com",
            "cal": "https://calendar.google.com",
            "g": "https://www.google.com/search?q={query}",
            "yt": "https://www.youtube.com/results?search_query={query}",
            "ws": "~/workspace",
            "dl": "~/Downloads"
        ]
    )

    static func load() throws -> Config {
        if !FileManager.default.fileExists(atPath: url.path) {
            try save(starter)
        }
        return try JSONDecoder().decode(Config.self, from: Data(contentsOf: url))
    }

    static func update(_ change: (inout Config) throws -> Void) throws {
        var config = try load()
        try change(&config)
        try save(config)
    }

    private static func save(_ config: Config) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        try encoder.encode(config).write(to: url)
    }
}
