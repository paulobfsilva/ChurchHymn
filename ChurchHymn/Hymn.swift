//
//  Item.swift
//  ChurchHymn
//
//  Created by paulo on 19/05/2025.
//

import SwiftUI
import SwiftData
import Foundation

@Model
class Hymn: Identifiable, Codable {
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
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.lyrics = lyrics?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.musicalKey = musicalKey?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.copyright = copyright?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.author = author?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.tags = tags?.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        self.notes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
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

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, title, lyrics, musicalKey, copyright, author, tags, notes, modelVersion
    }

    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        let title = try container.decode(String.self, forKey: .title)
        let lyrics = try container.decodeIfPresent(String.self, forKey: .lyrics)
        let musicalKey = try container.decodeIfPresent(String.self, forKey: .musicalKey)
        let copyright = try container.decodeIfPresent(String.self, forKey: .copyright)
        let author = try container.decodeIfPresent(String.self, forKey: .author)
        let tags = try container.decodeIfPresent([String].self, forKey: .tags)
        let notes = try container.decodeIfPresent(String.self, forKey: .notes)
        let modelVersion = try container.decodeIfPresent(Int.self, forKey: .modelVersion) ?? 1
        self.init(
            id: id,
            title: title,
            lyrics: lyrics,
            musicalKey: musicalKey,
            copyright: copyright,
            author: author,
            tags: tags,
            notes: notes,
            modelVersion: modelVersion
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(lyrics, forKey: .lyrics)
        try container.encodeIfPresent(musicalKey, forKey: .musicalKey)
        try container.encodeIfPresent(copyright, forKey: .copyright)
        try container.encodeIfPresent(author, forKey: .author)
        try container.encodeIfPresent(tags, forKey: .tags)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(modelVersion, forKey: .modelVersion)
    }
}

// Conform Hymn to Hashable so it can be used as a selection tag
extension Hymn: Hashable {
    static func == (lhs: Hymn, rhs: Hymn) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension Hymn {
    // MARK: - Plain Text Import/Export

    static func fromPlainText(_ text: String) -> Hymn? {
        let lines = text.components(separatedBy: .newlines)
        var title: String?
        var lyricsLines: [String] = []
        var key: String?
        var author: String?
        var copyright: String?
        var foundTitle = false
        var inMetadata = true

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Handle empty lines
            if trimmed.isEmpty { 
                if foundTitle {
                    lyricsLines.append(line)
                }
                continue 
            }
            
            // Handle metadata lines
            if trimmed.hasPrefix("#") {
                if trimmed.hasPrefix("#Key:") { 
                    key = trimmed.dropFirst(5).trimmingCharacters(in: .whitespaces) 
                }
                else if trimmed.hasPrefix("#Author:") { 
                    author = trimmed.dropFirst(8).trimmingCharacters(in: .whitespaces) 
                }
                else if trimmed.hasPrefix("#Copyright:") { 
                    copyright = trimmed.dropFirst(10).trimmingCharacters(in: .whitespaces) 
                }
                continue
            }
            
            // Handle title (first non-empty, non-metadata line)
            if !foundTitle && !trimmed.hasPrefix("#") {
                title = trimmed
                foundTitle = true
                continue
            }
            
            // Everything after title is lyrics
            if foundTitle {
                lyricsLines.append(line)
            }
        }
        
        // Validate that we have a title
        guard let hymnTitle = title, !hymnTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { 
            return nil 
        }
        
        let lyrics = lyricsLines.drop(while: { $0.trimmingCharacters(in: .whitespaces).isEmpty }).joined(separator: "\n")
        return Hymn(title: hymnTitle, lyrics: lyrics.isEmpty ? nil : lyrics, musicalKey: key, copyright: copyright, author: author)
    }

    func toPlainText() -> String {
        var lines: [String] = [title]
        if let key = musicalKey, !key.isEmpty { lines.append("#Key: \(key)") }
        if let author = author, !author.isEmpty { lines.append("#Author: \(author)") }
        if let copyright = copyright, !copyright.isEmpty { lines.append("#Copyright: \(copyright)") }
        if let lyrics = lyrics, !lyrics.isEmpty {
            lines.append("")
            lines.append(lyrics)
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - JSON Import/Export

    static func fromJSON(_ data: Data) -> Hymn? {
        do {
            return try JSONDecoder().decode(Hymn.self, from: data)
        } catch let error as DecodingError {
            print("JSON decode error: \(error)")
            return nil
        } catch {
            print("JSON decode error: \(error)")
            return nil
        }
    }

    func toJSON(pretty: Bool = false) -> Data? {
        do {
            let encoder = JSONEncoder()
            if pretty { encoder.outputFormatting = .prettyPrinted }
            return try encoder.encode(self)
        } catch let error as EncodingError {
            print("JSON encode error: \(error)")
            return nil
        } catch {
            print("JSON encode error: \(error)")
            return nil
        }
    }

    // MARK: - Batch JSON Import/Export

    static func arrayFromJSON(_ data: Data) -> [Hymn]? {
        do {
            return try JSONDecoder().decode([Hymn].self, from: data)
        } catch let error as DecodingError {
            print("JSON array decode error: \(error)")
            return nil
        } catch {
            print("JSON array decode error: \(error)")
            return nil
        }
    }

    static func arrayToJSON(_ hymns: [Hymn], pretty: Bool = false) -> Data? {
        do {
            let encoder = JSONEncoder()
            if pretty { encoder.outputFormatting = .prettyPrinted }
            return try encoder.encode(hymns)
        } catch let error as EncodingError {
            print("JSON array encode error: \(error)")
            return nil
        } catch {
            print("JSON array encode error: \(error)")
            return nil
        }
    }
}
