import AppKit
import Observation

@MainActor
@Observable
final class LauncherModel {
    var text = ""
    var selection = 0
    private(set) var links: [Link] = []
    private(set) var apps: [AppEntry] = []
    private(set) var errorMessage: String?

    @ObservationIgnored var onDismiss: () -> Void = {}
    @ObservationIgnored private var terminalApp = Config.defaultTerminal

    var visibleEntries: [Entry] {
        Search.results(for: text, links: links, apps: apps)
    }

    func reset() {
        text = ""
        selection = 0
        apps = AppIndex.scan()
        reload()
    }

    func move(_ delta: Int) {
        let count = visibleEntries.count
        guard count > 0 else { return }
        selection = (selection + delta + count) % count
    }

    func openSelected() {
        let visible = visibleEntries
        guard visible.indices.contains(selection) else { return }
        open(visible[selection])
    }

    func open(_ entry: Entry) {
        do {
            switch entry {
            case .link(let link):
                try Opener.open(link, query: Search.query(for: text, link: link), terminalApp: terminalApp)
            case .app(let app):
                Opener.open(app)
            }
            onDismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func editConfig() {
        NSWorkspace.shared.open(ConfigStore.url)
        onDismiss()
    }

    func dismiss() {
        onDismiss()
    }

    private func reload() {
        do {
            let config = try ConfigStore.load()
            terminalApp = config.terminalApp
            links = config.links
                .map { Link(keyword: $0.key, targets: $0.value.values.map(Target.init(value:))) }
                .sorted { $0.keyword < $1.keyword }
            errorMessage = nil
        } catch {
            links = []
            errorMessage = "Cannot read \(ConfigStore.url.path): \(error.localizedDescription)"
        }
    }
}
