import AppKit

struct OpenError: LocalizedError {
    let errorDescription: String?
}

enum Opener {
    static func open(_ link: Link, query: String, terminalApp: String) throws {
        if link.isFolder {
            try openFolder(link.folderURL, in: terminalApp)
        } else {
            try openURL(link, query: query)
        }
    }

    static func open(_ app: AppEntry) {
        NSWorkspace.shared.open(app.url)
    }

    private static func openURL(_ link: Link, query: String) throws {
        guard let url = link.resolvedURL(query: query) else {
            throw OpenError(errorDescription: "Invalid URL for \"\(link.keyword)\": \(link.template)")
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
