import Foundation
import Testing
@testable import quicklinks

struct TargetTests {
    private func decode(_ json: String) throws -> Target {
        try JSONDecoder().decode(Target.self, from: Data(json.utf8))
    }

    private func encode(_ target: Target) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return String(decoding: try encoder.encode(target), as: UTF8.self)
    }

    @Test func plainStringHasNoApp() throws {
        let target = try decode("\"https://github.com\"")
        #expect(target == Target(value: "https://github.com"))
        #expect(target.app == nil)
    }

    @Test func objectCarriesTheApp() throws {
        let target = try decode("{\"target\": \"~/workspace\", \"with\": \"Cursor\"}")
        #expect(target == Target(value: "~/workspace", app: "Cursor"))
    }

    @Test func objectWithoutAppIsAccepted() throws {
        #expect(try decode("{\"target\": \"~/workspace\"}") == Target(value: "~/workspace"))
    }

    @Test func objectWithoutTargetIsRejected() {
        #expect(throws: DecodingError.self) { try decode("{\"with\": \"Cursor\"}") }
    }

    @Test func targetWithoutAppEncodesAsPlainString() throws {
        #expect(try encode(Target(value: "https://github.com")) == "\"https://github.com\"")
    }

    @Test func targetWithAppEncodesAsObject() throws {
        #expect(try encode(Target(value: "~/workspace", app: "Cursor")) == "{\"target\":\"~/workspace\",\"with\":\"Cursor\"}")
    }

    @Test func folderTargetsStartWithSlashOrTilde() {
        #expect(Target(value: "/tmp").isFolder)
        #expect(Target(value: "~/notes").isFolder)
        #expect(!Target(value: "https://example.com").isFolder)
        #expect(!Target(value: "spotify:playlist:abc").isFolder)
    }

    @Test func queryIsPercentEncodedIntoTheUrl() {
        let target = Target(value: "https://www.google.com/search?q={query}")
        #expect(target.resolvedURL(query: "best pizza")?.absoluteString == "https://www.google.com/search?q=best%20pizza")
    }

    @Test func queryKeepsReservedCharactersInsideTheValue() {
        let target = Target(value: "https://example.com/?q={query}")
        #expect(target.resolvedURL(query: "a&b=c/d+e#f")?.absoluteString == "https://example.com/?q=a%26b%3Dc%2Fd%2Be%23f")
    }

    @Test func spotifyUriResolves() {
        #expect(Target(value: "spotify:playlist:123").resolvedURL(query: "")?.scheme == "spotify")
    }

    @Test func summaryNamesTheApp() {
        #expect(Target(value: "~/workspace", app: "Cursor").summary == "~/workspace (Cursor)")
        #expect(Target(value: "~/workspace").summary == "~/workspace")
    }
}
