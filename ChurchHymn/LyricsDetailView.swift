//
//  LyricsDetailView.swift
//  ChurchHymn
//
//  Created by paulo on 20/05/2025.
//
import SwiftUI

struct LyricsDetailView: View {
    var hymn: Hymn
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(hymn.title)
                    .font(.largeTitle)
                ForEach(Array(hymn.parts.enumerated()), id: \.offset) { _, block in
                    if let label = block.label {
                        Text(label)
                            .italic()
                    }
                    ForEach(block.lines.indices, id: \.self) { i in
                        Text(block.lines[i])
                    }
                    Divider()
                }
            }
            .padding()
        }
    }
}
