import Foundation

struct Link: Identifiable, Equatable {
    static let queryPlaceholder = "{query}"
    private static let queryValueAllowed = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: "&=+#?/"))

    let keyword: String
    let template: String

    var id: String { keyword }

    var isFolder: Bool { template.hasPrefix("/") || template.hasPrefix("~") }

    var folderURL: URL {
        URL(fileURLWithPath: (template as NSString).expandingTildeInPath)
    }

    func resolvedURL(query: String) -> URL? {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: Link.queryValueAllowed) ?? query
        return URL(string: template.replacingOccurrences(of: Link.queryPlaceholder, with: encoded))
    }
}

enum LinkSearch {
    static func results(for text: String, in links: [Link]) -> [Link] {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return links }
        if let exact = exactKeywordMatch(for: trimmed, in: links) { return [exact] }
        let needle = trimmed.lowercased()
        let matches = links.filter {
            $0.keyword.lowercased().contains(needle) || $0.template.lowercased().contains(needle)
        }
        return matches.sorted { lhs, rhs in
            lhs.keyword.lowercased().hasPrefix(needle) && !rhs.keyword.lowercased().hasPrefix(needle)
        }
    }

    static func query(for text: String, link: Link) -> String {
        guard let parts = keywordAndQuery(text), parts.keyword == link.keyword else { return "" }
        return parts.query
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
