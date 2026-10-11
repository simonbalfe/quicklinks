import Carbon.HIToolbox
import Foundation
import Testing
@testable import quicklinks

struct LinkTargetsTests {
    private func decode(_ json: String) throws -> LinkTargets {
        try JSONDecoder().decode(LinkTargets.self, from: Data(json.utf8))
    }

    private func encode(_ targets: LinkTargets) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return String(decoding: try encoder.encode(targets), as: UTF8.self)
    }

    @Test func singleStringIsOneTarget() throws {
        #expect(try decode("\"https://github.com\"").targets == [Target(value: "https://github.com")])
    }

    @Test func arrayKeepsOrderAndMixesStringsWithObjects() throws {
        let targets = try decode("[\"https://mail.google.com\", {\"target\": \"~/notes\", \"with\": \"Obsidian\"}]").targets
        #expect(targets == [Target(value: "https://mail.google.com"), Target(value: "~/notes", app: "Obsidian")])
    }

    @Test func singleObjectIsOneTarget() throws {
        #expect(try decode("{\"target\": \"~/workspace\", \"with\": \"Cursor\"}").targets == [Target(value: "~/workspace", app: "Cursor")])
    }

    @Test func emptyArrayIsRejected() {
        #expect(throws: DecodingError.self) { try decode("[]") }
    }

    @Test func oneTargetEncodesWithoutAnArray() throws {
        #expect(try encode(LinkTargets([Target(value: "https://github.com")])) == "\"https://github.com\"")
    }

    @Test func severalTargetsEncodeAsAnArray() throws {
        let targets = LinkTargets([Target(value: "https://a.example"), Target(value: "~/b", app: "Zed")])
        #expect(try encode(targets) == "[\"https://a.example\",{\"target\":\"~/b\",\"with\":\"Zed\"}]")
    }

    @Test func configWithMixedLinksRoundTripsUnchanged() throws {
        let json = """
            {"hotkey":"cmd+space","links":{"gh":"https://github.com","morning":["https://mail.google.com","~/notes"],"ws":{"target":"~/workspace","with":"Cursor"}},"terminal":"iTerm"}
            """
        let config = try JSONDecoder().decode(Config.self, from: Data(json.utf8))
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let encoded = String(decoding: try encoder.encode(config), as: UTF8.self)
        #expect(encoded == json)
    }

    @Test func terminalFallsBackToDefault() throws {
        let config = try JSONDecoder().decode(Config.self, from: Data("{\"hotkey\":\"cmd+space\",\"links\":{}}".utf8))
        #expect(config.terminalApp == Config.defaultTerminal)
    }
}

struct WithFlagTests {
    @Test func flagAndValueAreRemovedFromThePositionalArguments() throws {
        let parsed = try CLI.withApp(["ws", "~/workspace", "--with", "Cursor"])
        #expect(parsed.positional == ["ws", "~/workspace"])
        #expect(parsed.app == "Cursor")
    }

    @Test func flagCanComeBeforeTheTargets() throws {
        let parsed = try CLI.withApp(["--with", "Google Chrome", "work", "https://github.com"])
        #expect(parsed.positional == ["work", "https://github.com"])
        #expect(parsed.app == "Google Chrome")
    }

    @Test func equalsFormIsAccepted() throws {
        let parsed = try CLI.withApp(["site", "https://example.com", "--with=Safari"])
        #expect(parsed.positional == ["site", "https://example.com"])
        #expect(parsed.app == "Safari")
    }

    @Test func noFlagMeansNoApp() throws {
        let parsed = try CLI.withApp(["gh", "https://github.com"])
        #expect(parsed.positional == ["gh", "https://github.com"])
        #expect(parsed.app == nil)
    }

    @Test func flagWithoutAValueFails() {
        #expect(throws: CLIError.self) { try CLI.withApp(["gh", "https://github.com", "--with"]) }
    }
}

struct TargetNormalizationTests {
    @Test func urlsWithSlashesAreKept() throws {
        #expect(try CLI.normalizedTarget("https://github.com") == "https://github.com")
    }

    @Test func schemeOnlyUrisAreKept() throws {
        #expect(try CLI.normalizedTarget("spotify:playlist:123") == "spotify:playlist:123")
        #expect(try CLI.normalizedTarget("mailto:me@example.com") == "mailto:me@example.com")
    }

    @Test func absoluteAndHomePathsAreKept() throws {
        #expect(try CLI.normalizedTarget("/tmp") == "/tmp")
        #expect(try CLI.normalizedTarget("~/notes") == "~/notes")
    }

    @Test func aBareWordThatIsNotAFolderIsRejected() {
        #expect(throws: CLIError.self) { try CLI.normalizedTarget("definitely-not-a-folder-or-link") }
    }

    @Test func aColonWithNothingAfterItIsRejected() {
        #expect(throws: CLIError.self) { try CLI.normalizedTarget("spotify:") }
    }
}

struct HotKeyParseTests {
    @Test func modifiersAndKeyAreCombined() throws {
        let parsed = try HotKey.parse("cmd+shift+k")
        #expect(parsed.keyCode == kVK_ANSI_K)
        #expect(parsed.modifierMask == cmdKey | shiftKey)
    }

    @Test func spaceKeyWorksWithAliasAndCase() throws {
        let parsed = try HotKey.parse("Option+Space")
        #expect(parsed.keyCode == kVK_Space)
        #expect(parsed.modifierMask == optionKey)
    }

    @Test func unknownKeyIsRejected() {
        #expect(throws: HotKeyError.self) { try HotKey.parse("cmd+f13") }
    }

    @Test func unknownModifierIsRejected() {
        #expect(throws: HotKeyError.self) { try HotKey.parse("hyper+k") }
    }

    @Test func aKeyWithoutAModifierIsRejected() {
        #expect(throws: HotKeyError.self) { try HotKey.parse("k") }
    }
}
