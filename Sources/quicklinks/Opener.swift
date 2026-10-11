import AppKit

struct OpenError: LocalizedError {
    let errorDescription: String?
}

enum Opener {
    static func open(_ link: Link, query: String, terminalApp: String) throws {
        var failures: [String] = []
        for target in link.targets {
            do {
                try open(target, keyword: link.keyword, query: query, terminalApp: terminalApp)
            } catch {
                failures.append(error.localizedDescription)
            }
        }
        if !failures.isEmpty {
            throw OpenError(errorDescription: failures.joined(separator: "; "))
        }
    }

    static func open(_ app: AppEntry) {
        NSWorkspace.shared.open(app.url)
    }

    private static func open(_ target: Target, keyword: String, query: String, terminalApp: String) throws {
        if target.isFolder {
            try openFolder(target.folderURL, in: terminalApp)
        } else {
            try openURL(target, keyword: keyword, query: query)
        }
    }

    private static func openURL(_ target: Target, keyword: String, query: String) throws {
        guard let url = target.resolvedURL(query: query) else {
            throw OpenError(errorDescription: "Invalid URL for \"\(keyword)\": \(target.value)")
        }
        NSWorkspace.shared.open(url)
    }

    private static func openFolder(_ folder: URL, in terminalApp: String) throws {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: folder.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw OpenError(errorDescription: "Not a folder: \(folder.path)")
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", terminalApp, folder.path]
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw OpenError(errorDescription: "Cannot open \"\(terminalApp)\" (set \"terminal\" in the config)")
        }
    }
}
