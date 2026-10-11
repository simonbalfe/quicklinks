import AppKit
import SwiftUI

private final class LauncherPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

@MainActor
final class LauncherController: NSObject, NSWindowDelegate {
    private static let size = NSSize(width: 640, height: 420)

    private let model = LauncherModel()
    private let panel: NSPanel

    override init() {
        panel = LauncherPanel(
            contentRect: NSRect(origin: .zero, size: LauncherController.size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false)
        super.init()
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.delegate = self
        model.onDismiss = { [weak self] in self?.hide() }
    }

    func toggle() {
        panel.isVisible ? hide() : show()
    }

    func show() {
        model.reset()
        panel.contentView = NSHostingView(rootView: LauncherView(model: model))
        panel.setFrameOrigin(origin(on: activeScreen()))
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    func hide() {
        panel.orderOut(nil)
        NSApp.hide(nil)
    }

    func windowDidResignKey(_ notification: Notification) {
        if panel.isVisible { hide() }
    }

    private func activeScreen() -> NSScreen {
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main ?? NSScreen.screens[0]
    }

    private func origin(on screen: NSScreen) -> NSPoint {
        let frame = screen.visibleFrame
        return NSPoint(
            x: frame.midX - LauncherController.size.width / 2,
            y: frame.maxY - frame.height * 0.25 - LauncherController.size.height)
    }
}
