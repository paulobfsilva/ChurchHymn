//
//  Item.swift
//  ChurchHymn
//
//  Created by paulo on 19/05/2025.
//

import SwiftUI
import SwiftData

// MARK: - Model
@Model
class Hymn: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var lyrics: String  // raw text with blocks separated by empty lines

    init(id: UUID = UUID(), title: String, lyrics: String) {
        self.id = id
        self.title = title
        self.lyrics = lyrics
    }

    /// Split into labeled blocks
    var parts: [(label: String?, lines: [String])] {
        lyrics
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { block in
                let lines = block.components(separatedBy: .newlines)
                if lines.allSatisfy({ $0.hasPrefix("C:") }) {
                    let content = lines.map { String($0.dropFirst(2)).trimmingCharacters(in: .whitespaces) }
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
