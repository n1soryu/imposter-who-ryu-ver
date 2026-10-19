import Foundation
import Testing
@testable import ImposterKit

struct RosterTests {
    private func roster(_ names: String...) throws -> Roster {
        var roster = Roster()
        for name in names {
            try roster.add(name)
        }
        return roster
    }

    // MARK: Adding

    @Test func addsPlayersInSeatingOrder() throws {
        let roster = try roster("Ryu", "Aiko", "Ben")
        #expect(roster.players.map(\.name) == ["Ryu", "Aiko", "Ben"])
    }

    @Test("Cleans up spacing", arguments: [("  Ryu ", "Ryu"), ("Mary   Jane", "Mary Jane"), ("\tKai\n", "Kai")])
    func cleansUpSpacing(input: String, expected: String) throws {
        let roster = try roster(input)
        #expect(roster.players.first?.name == expected)
    }

    @Test(arguments: ["", "   ", "\n"])
    func rejectsBlankNames(name: String) {
        var roster = Roster()
        #expect(throws: Roster.NameError.empty) {
            try roster.add(name)
        }
    }

    @Test func rejectsLongNames() {
        var roster = Roster()
        #expect(throws: Roster.NameError.tooLong(limit: 20)) {
            try roster.add(String(repeating: "a", count: 21))
        }
    }

    @Test(arguments: ["ryu", "RYU", "Ryū", " Ryu "])
    func rejectsDuplicateNames(name: String) throws {
        var roster = try roster("Ryu")
        #expect(throws: Roster.NameError.duplicate(existing: "Ryu")) {
            try roster.add(name)
        }
    }

    @Test func stopsAtTheMaximum() throws {
        var roster = Roster()
        for number in 1...Roster.maximumPlayers {
            try roster.add("Player \(number)")
        }

        #expect(throws: Roster.NameError.full(limit: 15)) {
            try roster.add("One too many")
        }
    }

    @Test func needsThreePlayersToPlay() throws {
        #expect(try roster("Ryu", "Aiko").canPlay == false)
        #expect(try roster("Ryu", "Aiko", "Ben").canPlay)
    }

    // MARK: Renaming

    @Test func renamesAPlayer() throws {
        var roster = try roster("Ryu", "Aiko")
        let aiko = roster.players[1].id

        try roster.rename(aiko, to: "Aiko B")

        #expect(roster.players.map(\.name) == ["Ryu", "Aiko B"])
        #expect(roster.players[1].id == aiko)
    }

    @Test func renamingToTheSameNameWithDifferentCaseIsAllowed() throws {
        var roster = try roster("ryu")
        try roster.rename(roster.players[0].id, to: "Ryu")
        #expect(roster.players[0].name == "Ryu")
    }

    @Test func renamingToAnotherPlayersNameFails() throws {
        var roster = try roster("Ryu", "Aiko")
        let aiko = roster.players[1].id
        #expect(throws: Roster.NameError.duplicate(existing: "Ryu")) {
            try roster.rename(aiko, to: "ryu")
        }
    }

    // MARK: Removing and reordering

    @Test func removesByIDAndOffset() throws {
        var roster = try roster("Ryu", "Aiko", "Ben", "Chloe")
        roster.remove(roster.players[0].id)
        roster.remove(atOffsets: [0, 2])

        #expect(roster.players.map(\.name) == ["Ben"])
    }

    @Test("Moves like List.onMove", arguments: [
        (IndexSet([0]), 2, ["B", "A", "C", "D"]),
        (IndexSet([0]), 4, ["B", "C", "D", "A"]),
        (IndexSet([3]), 0, ["D", "A", "B", "C"]),
        (IndexSet([1, 2]), 4, ["A", "D", "B", "C"]),
        (IndexSet([2]), 2, ["A", "B", "C", "D"]),
    ])
    func movesLikeListOnMove(source: IndexSet, destination: Int, expected: [String]) throws {
        var roster = try roster("A", "B", "C", "D")
        roster.move(fromOffsets: source, toOffset: destination)

        #expect(roster.players.map(\.name) == expected)
    }

    @Test func shufflingKeepsEveryone() throws {
        var roster = try roster("A", "B", "C", "D", "E", "F")
        var generator = SeededGenerator(seed: 9)
        roster.shuffleSeats(using: &generator)

        #expect(Set(roster.players.map(\.name)) == ["A", "B", "C", "D", "E", "F"])
    }

    @Test func survivesEncoding() throws {
        let original = try roster("Ryu", "Aiko", "Ben")
        let restored = try JSONDecoder().decode(Roster.self, from: JSONEncoder().encode(original))

        #expect(restored == original)
    }
}
