//
//  Item.swift
//  ChurchHymn
//
//  Created by paulo on 19/05/2025.
//

import SwiftUI
import SwiftData

@Model
class Hymn: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var lyrics: String?
    var musicalKey: String?
    var copyright: String?
    var author: String?
    var tags: [String]?
    var notes: String?
    var modelVersion: Int

    // All fields except id and title are optional for migration safety and extensibility.
    init(
        id: UUID = UUID(),
        title: String,
        lyrics: String? = nil,
        musicalKey: String? = nil,
        copyright: String? = nil,
        author: String? = nil,
        tags: [String]? = nil,
        notes: String? = nil,
        modelVersion: Int = 1
    ) {
        self.id = id
        self.title = title
        self.lyrics = lyrics
        self.musicalKey = musicalKey
        self.copyright = copyright
        self.author = author
        self.tags = tags
        self.notes = notes
        self.modelVersion = modelVersion
    }

    /// Split into labeled blocks
    var parts: [(label: String?, lines: [String])] {
        guard let lyrics = lyrics else { return [] }
        return lyrics
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { block in
                let lines = block.components(separatedBy: .newlines)
                if let first = lines.first, first.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == "CHORUS" {
                    let content = Array(lines.dropFirst())
                    return (label: "Chorus", lines: content)
                } else {
                    return (label: nil, lines: lines)
                }
            }
    }
    // --- Migration Strategy ---
    // If you add new required fields in the future, make them optional first, then migrate old data, then make them required.
    // Use the modelVersion property to track schema changes and perform migrations as needed.

    // --- Test Plan ---
    // 1. Test encoding/decoding Hymn to/from JSON.
    // 2. Test creating Hymn with missing/partial data.
    // 3. Test UI with nil/empty fields.
}

// Conform Hymn to Hashable so it can be used as a selection tag
extension Hymn: Hashable {
    static func == (lhs: Hymn, rhs: Hymn) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
