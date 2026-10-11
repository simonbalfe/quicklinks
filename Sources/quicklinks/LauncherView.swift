import SwiftUI

struct LauncherView: View {
    @Bindable var model: LauncherModel
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            searchField
            Divider()
            entryList
            Divider()
            footer
        }
        .frame(width: 640, height: 420)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .onAppear { searchFocused = true }
        .onChange(of: model.text) { model.selection = 0 }
    }

    private var searchField: some View {
        TextField("Search quicklinks and apps", text: $model.text)
            .textFieldStyle(.plain)
            .font(.system(size: 22))
            .padding(16)
            .focused($searchFocused)
            .onSubmit { model.openSelected() }
            .onKeyPress(.upArrow) { model.move(-1); return .handled }
            .onKeyPress(.downArrow) { model.move(1); return .handled }
            .onExitCommand { model.dismiss() }
    }

    private var entryList: some View {
        let visible = model.visibleEntries
        return ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(Array(visible.enumerated()), id: \.element.id) { index, entry in
                        EntryRow(entry: entry, isSelected: index == model.selection)
                            .id(entry.id)
                            .onTapGesture { model.open(entry) }
                    }
                }
                .padding(8)
            }
            .overlay {
                if visible.isEmpty { Text("No results").foregroundStyle(.secondary) }
            }
            .onChange(of: model.selection) {
                guard visible.indices.contains(model.selection) else { return }
                proxy.scrollTo(visible[model.selection].id)
            }
        }
    }

    private var footer: some View {
        HStack {
            if let errorMessage = model.errorMessage {
                Text(errorMessage).foregroundStyle(.red).lineLimit(1)
            } else {
                Text("\(model.links.count) quicklinks \u{00B7} \(model.apps.count) apps").foregroundStyle(.secondary)
            }
            Spacer()
            Button("Edit links  \u{2318}E") { model.editConfig() }
                .keyboardShortcut("e", modifiers: .command)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
        }
        .font(.caption)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

private struct EntryRow: View {
    let entry: Entry
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            switch entry {
            case .link(let link): LinkContent(link: link)
            case .app(let app): AppContent(app: app)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.25) : .clear, in: RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
    }
}

private struct LinkContent: View {
    let link: Link

    var body: some View {
        Text(link.keyword)
            .font(.system(.body, design: .monospaced).bold())
            .frame(width: 120, alignment: .leading)
        Image(systemName: link.isFolder ? "terminal" : "arrow.right").foregroundStyle(.secondary)
        Text(link.template)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.middle)
    }
}

private struct AppContent: View {
    let app: AppEntry

    var body: some View {
        Image(nsImage: NSWorkspace.shared.icon(forFile: app.url.path))
            .resizable()
            .frame(width: 22, height: 22)
        Text(app.name)
        Text("Application").foregroundStyle(.secondary)
    }
}
