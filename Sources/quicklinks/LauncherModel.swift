import AppKit
import Observation

@MainActor
@Observable
final class LauncherModel {
    var text = ""
    var selection = 0
    private(set) var links: [Link] = []
    private(set) var errorMessage: String?

    @ObservationIgnored var onDismiss: () -> Void = {}
    @ObservationIgnored private var terminalApp = Config.defaultTerminal

    var visibleLinks: [Link] {
        LinkSearch.results(for: text, in: links)
    }

    func reset() {
        text = ""
        selection = 0
        reload()
    }

    func move(_ delta: Int) {
        let count = visibleLinks.count
        guard count > 0 else { return }
        selection = (selection + delta + count) % count
    }

    func openSelected() {
        let visible = visibleLinks
        guard visible.indices.contains(selection) else { return }
        open(visible[selection])
    }

    func open(_ link: Link) {
        do {
            try Opener.open(link, query: LinkSearch.query(for: text, link: link), terminalApp: terminalApp)
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
                .map { Link(keyword: $0.key, template: $0.value) }
                .sorted { $0.keyword < $1.keyword }
            errorMessage = nil
        } catch {
            links = []
            errorMessage = "Cannot read \(ConfigStore.url.path): \(error.localizedDescription)"
        }
    }
}
