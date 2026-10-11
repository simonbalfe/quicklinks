import Foundation
import Testing
@testable import quicklinks

struct SearchTests {
    private let gh = Link(keyword: "gh", targets: [Target(value: "https://github.com")])
    private let g = Link(keyword: "g", targets: [Target(value: "https://www.google.com/search?q={query}")])
    private let cal = Link(keyword: "cal", targets: [Target(value: "https://calendar.google.com")])
    private let morning = Link(keyword: "morning", targets: [Target(value: "https://mail.google.com"), Target(value: "~/notes")])
    private let ghostty = AppEntry(name: "Ghostty", url: URL(fileURLWithPath: "/Applications/Ghostty.app"))
    private let desktop = AppEntry(name: "GitHub Desktop", url: URL(fileURLWithPath: "/Applications/GitHub Desktop.app"))

    private func titles(_ entries: [Entry]) -> [String] {
        entries.map {
            switch $0 {
            case .link(let link): return link.keyword
            case .app(let app): return app.name
            }
        }
    }

    @Test func emptyTextListsEveryLinkAndNoApps() {
        let results = Search.results(for: "  ", links: [gh, cal], apps: [ghostty])
        #expect(titles(results) == ["gh", "cal"])
    }

    @Test func keywordWithQueryReturnsOnlyThatLink() {
        let results = Search.results(for: "g best pizza", links: [gh, g], apps: [ghostty])
        #expect(titles(results) == ["g"])
    }

    @Test func queryIsTheTextAfterTheKeyword() {
        #expect(Search.query(for: "g best pizza", link: g) == "best pizza")
    }

    @Test func queryIsEmptyForAnotherLink() {
        #expect(Search.query(for: "g best pizza", link: gh) == "")
    }

    @Test func linksRankAboveAppsForTheSameMatch() {
        let results = Search.results(for: "gh", links: [gh], apps: [ghostty])
        #expect(titles(results) == ["gh", "Ghostty"])
    }

    @Test func wordPrefixMatchesAnAppName() {
        let results = Search.results(for: "desk", links: [gh], apps: [desktop])
        #expect(titles(results) == ["GitHub Desktop"])
    }

    @Test func matchesATargetWhenTheKeywordDoesNot() {
        let results = Search.results(for: "calendar", links: [gh, cal], apps: [])
        #expect(titles(results) == ["cal"])
    }

    @Test func nothingMatchingReturnsNothing() {
        #expect(Search.results(for: "zzzz", links: [gh, cal], apps: [ghostty]).isEmpty)
    }

    @Test func groupsAreReportedAsGroups() {
        #expect(morning.isGroup)
        #expect(!gh.isGroup)
    }
}
