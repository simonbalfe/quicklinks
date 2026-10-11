import AppKit

struct OpenError: LocalizedError {
    let errorDescription: String?
}

enum Opener {
    static func open(_ link: Link, query: String) throws {
        var failures: [String] = []
        for target in link.targets {
            do {
                try open(target, keyword: link.keyword, query: query)
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

    private static func open(_ target: Target, keyword: String, query: String) throws {
        if target.isFolder {
            try openFolder(target)
        } else {
            try openURL(target, keyword: keyword, query: query)
        }
    }

    private static func openURL(_ target: Target, keyword: String, query: String) throws {
        guard let url = target.resolvedURL(query: query) else {
            throw OpenError(errorDescription: "Invalid URL for \"\(keyword)\": \(target.value)")
        }
        guard let app = target.app else {
            NSWorkspace.shared.open(url)
            return
        }
        try run(app: app, opening: url.absoluteString, failure: "Cannot open \"\(app)\" (check the app name with `quicklinks apps`)")
    }

    private static func openFolder(_ target: Target) throws {
        let folder = target.folderURL
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: folder.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw OpenError(errorDescription: "Not a folder: \(folder.path)")
        }
        guard let app = target.app else {
            NSWorkspace.shared.open(folder)
            return
        }
        try run(app: app, opening: folder.path, failure: "Cannot open \"\(app)\" (check the app name with `quicklinks apps`)")
    }

    private static func run(app: String, opening path: String, failure: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", app, path]
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw OpenError(errorDescription: failure)
        }
    }
}
