import Foundation

struct Target: Equatable {
    static let queryPlaceholder = "{query}"
    private static let queryValueAllowed = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: "&=+#?/"))

    let value: String

    var isFolder: Bool { value.hasPrefix("/") || value.hasPrefix("~") }

    var folderURL: URL {
        URL(fileURLWithPath: (value as NSString).expandingTildeInPath)
    }

    func resolvedURL(query: String) -> URL? {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: Target.queryValueAllowed) ?? query
        return URL(string: value.replacingOccurrences(of: Target.queryPlaceholder, with: encoded))
    }
}

struct Link: Identifiable, Equatable {
    let keyword: String
    let targets: [Target]

    var id: String { keyword }

    var isGroup: Bool { targets.count > 1 }

    var summary: String { targets.map(\.value).joined(separator: ", ") }

    func matches(_ needle: String) -> Bool {
        targets.contains { $0.value.lowercased().contains(needle) }
    }
}

struct AppEntry: Equatable {
    let name: String
    let url: URL
}

enum Entry: Identifiable, Equatable {
    case link(Link)
    case app(AppEntry)

    var id: String {
        switch self {
        case .link(let link): return "link:\(link.keyword)"
        case .app(let app): return "app:\(app.url.path)"
        }
    }
}

enum Search {
    private static let maxResults = 50

    static func results(for text: String, links: [Link], apps: [AppEntry]) -> [Entry] {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return links.map(Entry.link) }
        if let exact = exactKeywordMatch(for: trimmed, in: links) { return [.link(exact)] }
        let needle = trimmed.lowercased()
        let ranked = rankedLinks(links, needle: needle) + rankedApps(apps, needle: needle)
        return ranked
            .sorted { ($0.rank, $0.kind, $0.title) < ($1.rank, $1.kind, $1.title) }
            .prefix(maxResults)
            .map(\.entry)
    }

    static func query(for text: String, link: Link) -> String {
        guard let parts = keywordAndQuery(text), parts.keyword == link.keyword else { return "" }
        return parts.query
    }

    private struct Ranked {
        let entry: Entry
        let rank: Int
        let kind: Int
        let title: String
    }

    private static func rankedLinks(_ links: [Link], needle: String) -> [Ranked] {
        links.compactMap { link in
            let rank = rank(link.keyword, needle: needle)
                ?? (link.matches(needle) ? 3 : nil)
            return rank.map { Ranked(entry: .link(link), rank: $0, kind: 0, title: link.keyword.lowercased()) }
        }
    }

    private static func rankedApps(_ apps: [AppEntry], needle: String) -> [Ranked] {
        apps.compactMap { app in
            rank(app.name, needle: needle)
                .map { Ranked(entry: .app(app), rank: $0, kind: 1, title: app.name.lowercased()) }
        }
    }

    private static func rank(_ name: String, needle: String) -> Int? {
        let lowered = name.lowercased()
        if lowered.hasPrefix(needle) { return 0 }
        let words = lowered.split { !$0.isLetter && !$0.isNumber }
        if words.contains(where: { $0.hasPrefix(needle) }) { return 1 }
        if lowered.contains(needle) { return 2 }
        return nil
    }

    private static func exactKeywordMatch(for text: String, in links: [Link]) -> Link? {
        guard let parts = keywordAndQuery(text), !parts.query.isEmpty else { return nil }
        return links.first { $0.keyword == parts.keyword }
    }

    private static func keywordAndQuery(_ text: String) -> (keyword: String, query: String)? {
        let parts = text.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        guard let keyword = parts.first else { return nil }
        let query = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : ""
        return (String(keyword), query)
    }
}
