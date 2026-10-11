import Foundation

enum AppIndex {
    private static let maxDepth = 3

    private static let roots: [URL] = [
        "/Applications",
        "/System/Applications",
        "/System/Cryptexes/App/System/Applications",
        "/System/Library/CoreServices/Finder.app",
        "/System/Library/CoreServices/Applications",
        NSHomeDirectory() + "/Applications"
    ].map { URL(fileURLWithPath: $0) }

    static func scan() -> [AppEntry] {
        var byName: [String: AppEntry] = [:]
        for root in roots {
            for url in applications(under: root) {
                let name = FileManager.default.displayName(atPath: url.path)
                if byName[name] == nil { byName[name] = AppEntry(name: name, url: url) }
            }
        }
        return byName.values.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }

    private static func applications(under root: URL) -> [URL] {
        guard FileManager.default.fileExists(atPath: root.path) else { return [] }
        if root.pathExtension == "app" { return [root] }
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return [] }
        var found: [URL] = []
        for case let url as URL in enumerator {
            if url.pathExtension == "app" {
                found.append(url)
            } else if enumerator.level >= maxDepth {
                enumerator.skipDescendants()
            }
        }
        return found
    }
}
