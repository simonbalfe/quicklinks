import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let controller = LauncherController()
    private var hotKey: HotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let spec = (try? ConfigStore.load().hotkey) ?? Config.defaultHotkey
        do {
            hotKey = try HotKey(spec: spec) { [controller] in
                MainActor.assumeIsolated { controller.toggle() }
            }
        } catch {
            FileHandle.standardError.write(Data("quicklinks: \(error.localizedDescription)\n".utf8))
            exit(1)
        }
        if CommandLine.arguments.contains("--show") {
            controller.show()
        }
    }
}

let arguments = Array(CommandLine.arguments.dropFirst())

let startsApp: Bool = {
    switch arguments {
    case []: return isatty(STDOUT_FILENO) == 0
    case ["--show"], ["start"], ["start", "--show"]: return true
    default: return false
    }
}()

if startsApp {
    MainActor.assumeIsolated {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
} else {
    exit(CLI.run(arguments))
}
