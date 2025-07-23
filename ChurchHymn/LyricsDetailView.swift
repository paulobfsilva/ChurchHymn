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
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(hymn.title).font(.largeTitle)
                    ForEach(Array(hymn.parts.enumerated()), id: \.offset) { _, part in
                        if let label = part.label {
                            Text(label).italic()
                        }
                        ForEach(part.lines, id: \.self) { Text($0) }
                        Divider()
                    }
                }
                .padding()
            }
            Divider()
            // Footer with copyright and key
            HStack {
                Text(hymn.copyright ?? "")
                    .font(.caption)
                Spacer()
                Text(hymn.musicalKey ?? "")
                    .font(.caption)
                Spacer().frame(width: 20)
            }
            .padding([.leading, .trailing, .bottom], 8)
        }
    }
}
