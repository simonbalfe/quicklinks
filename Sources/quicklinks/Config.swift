import Foundation

struct LinkTargets: Codable, Equatable, ExpressibleByStringLiteral {
    var values: [String]

    init(_ values: [String]) {
        self.values = values
    }

    init(stringLiteral value: String) {
        values = [value]
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let single = try? container.decode(String.self) {
            values = [single]
            return
        }
        values = try container.decode([String].self)
        guard !values.isEmpty else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "a link needs at least one target")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if values.count == 1 {
            try container.encode(values[0])
        } else {
            try container.encode(values)
        }
    }
}

struct Config: Codable {
    static let defaultHotkey = "option+space"
    static let defaultTerminal = "iTerm"

    var hotkey: String
    var terminal: String?
    var links: [String: LinkTargets]

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
