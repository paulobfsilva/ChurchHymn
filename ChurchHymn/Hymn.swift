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
    var lyrics: String  // raw text with blocks separated by empty lines
    var musicalKey: String     // e.g. "G Major"
    var copyright: String      // e.g. "© 2025 My Church"

    init(id: UUID = UUID(), title: String, lyrics: String, musicalKey: String, copyright: String) {
        self.id = id
        self.title = title
        self.lyrics = lyrics
        self.musicalKey = musicalKey
        self.copyright = copyright
    }

    /// Split into labeled blocks
        /// Split into labeled blocks
    var parts: [(label: String?, lines: [String])] {
        return lyrics
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { block in
                let lines = block.components(separatedBy: .newlines)
                // If a block starts with "CHORUS" (case-insensitive), treat as chorus
                if let first = lines.first, first.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == "CHORUS" {
                    let content = Array(lines.dropFirst())
                    return (label: "Chorus", lines: content)
                } else {
                    return (label: nil, lines: lines)
                }
            }
    }
}

// Conform Hymn to Hashable so it can be used as a selection tag
extension Hymn: Hashable {
    static func == (lhs: Hymn, rhs: Hymn) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
