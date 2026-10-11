import SwiftUI

struct LauncherView: View {
    @Bindable var model: LauncherModel
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            searchField
            Divider()
            linkList
            Divider()
            footer
        }
        .frame(width: 640, height: 420)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .onAppear { searchFocused = true }
        .onChange(of: model.text) { model.selection = 0 }
    }

    private var searchField: some View {
        TextField("Search quicklinks", text: $model.text)
            .textFieldStyle(.plain)
            .font(.system(size: 22))
            .padding(16)
            .focused($searchFocused)
            .onSubmit { model.openSelected() }
            .onKeyPress(.upArrow) { model.move(-1); return .handled }
            .onKeyPress(.downArrow) { model.move(1); return .handled }
            .onExitCommand { model.dismiss() }
    }

    private var linkList: some View {
        let visible = model.visibleLinks
        return ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(Array(visible.enumerated()), id: \.element.id) { index, link in
                        LinkRow(link: link, isSelected: index == model.selection)
                            .id(link.id)
                            .onTapGesture { model.open(link) }
                    }
                }
                .padding(8)
            }
            .overlay {
                if visible.isEmpty { Text("No quicklinks").foregroundStyle(.secondary) }
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
                Text("\(model.links.count) quicklinks").foregroundStyle(.secondary)
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

private struct LinkRow: View {
    let link: Link
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(link.keyword)
                .font(.system(.body, design: .monospaced).bold())
                .frame(width: 120, alignment: .leading)
            Image(systemName: link.isFolder ? "terminal" : "arrow.right").foregroundStyle(.secondary)
            Text(link.template)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.25) : .clear, in: RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
    }
}
