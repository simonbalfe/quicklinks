import Carbon.HIToolbox

struct HotKeyError: LocalizedError {
    let description: String
    var errorDescription: String? { description }
}

final class HotKey {
    private static let signature: OSType = 0x514C4B31

    private static let modifiers: [String: Int] = [
        "cmd": cmdKey, "command": cmdKey,
        "option": optionKey, "opt": optionKey, "alt": optionKey,
        "control": controlKey, "ctrl": controlKey,
        "shift": shiftKey
    ]

    private static let keyCodes: [String: Int] = [
        "space": kVK_Space,
        "a": kVK_ANSI_A, "b": kVK_ANSI_B, "c": kVK_ANSI_C, "d": kVK_ANSI_D,
        "e": kVK_ANSI_E, "f": kVK_ANSI_F, "g": kVK_ANSI_G, "h": kVK_ANSI_H,
        "i": kVK_ANSI_I, "j": kVK_ANSI_J, "k": kVK_ANSI_K, "l": kVK_ANSI_L,
        "m": kVK_ANSI_M, "n": kVK_ANSI_N, "o": kVK_ANSI_O, "p": kVK_ANSI_P,
        "q": kVK_ANSI_Q, "r": kVK_ANSI_R, "s": kVK_ANSI_S, "t": kVK_ANSI_T,
        "u": kVK_ANSI_U, "v": kVK_ANSI_V, "w": kVK_ANSI_W, "x": kVK_ANSI_X,
        "y": kVK_ANSI_Y, "z": kVK_ANSI_Z,
        "0": kVK_ANSI_0, "1": kVK_ANSI_1, "2": kVK_ANSI_2, "3": kVK_ANSI_3,
        "4": kVK_ANSI_4, "5": kVK_ANSI_5, "6": kVK_ANSI_6, "7": kVK_ANSI_7,
        "8": kVK_ANSI_8, "9": kVK_ANSI_9
    ]

    private let action: () -> Void
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    init(spec: String, action: @escaping () -> Void) throws {
        self.action = action
        let (keyCode, modifierMask) = try HotKey.parse(spec)
        try installHandler()
        try register(keyCode: keyCode, modifierMask: modifierMask)
    }

    deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let handlerRef { RemoveEventHandler(handlerRef) }
    }

    static func parse(_ spec: String) throws -> (keyCode: Int, modifierMask: Int) {
        let tokens = spec.lowercased().split(separator: "+").map { $0.trimmingCharacters(in: .whitespaces) }
        guard let keyToken = tokens.last, let keyCode = keyCodes[keyToken] else {
            throw HotKeyError(description: "Unknown key in hotkey \"\(spec)\"")
        }
        var mask = 0
        for token in tokens.dropLast() {
            guard let modifier = modifiers[token] else {
                throw HotKeyError(description: "Unknown modifier \"\(token)\" in hotkey \"\(spec)\"")
            }
            mask |= modifier
        }
        guard mask != 0 else {
            throw HotKeyError(description: "Hotkey \"\(spec)\" needs at least one modifier")
        }
        return (keyCode, mask)
    }

    private func installHandler() throws {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                guard let userData else { return OSStatus(eventNotHandledErr) }
                Unmanaged<HotKey>.fromOpaque(userData).takeUnretainedValue().action()
                return noErr
            },
            1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &handlerRef)
        guard status == noErr else {
            throw HotKeyError(description: "InstallEventHandler failed (\(status))")
        }
    }

    private func register(keyCode: Int, modifierMask: Int) throws {
        let id = EventHotKeyID(signature: HotKey.signature, id: 1)
        let status = RegisterEventHotKey(
            UInt32(keyCode), UInt32(modifierMask), id, GetApplicationEventTarget(), 0, &hotKeyRef)
        guard status == noErr else {
            throw HotKeyError(description: "Hotkey is taken by another app (\(status))")
        }
    }
}
