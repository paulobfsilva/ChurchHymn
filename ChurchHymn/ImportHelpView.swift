//
//  ImportHelpView.swift
//  ChurchHymn
//
//  Created by paulo on 02/08/2025.
//

import SwiftUI

struct ImportHelpView: View {
    private let jsonSingle = """
{
  "title": "Amazing Grace",
  "songNumber": 123,
  "lyrics": "Amazing grace, how sweet the sound...",
  "musicalKey": "C",
  "author": "John Newton",
  "copyright": "Public Domain",
  "tags": ["grace", "salvation"],
  "notes": "Traditional hymn"
}
"""

    private let jsonBatch = """
[
  { "title": "Hymn 1", "lyrics": "..." },
  { "title": "Hymn 2", "lyrics": "..." }
]
"""

    private let plainText = """
Amazing Grace
#Number: 123
#Key: C
#Author: John Newton
#Copyright: Public Domain
#Tags: grace, salvation
#Notes:

Amazing grace, how sweet the sound
That saved a wretch like me
…

Chorus
Praise God, praise God, praise God
"""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Importing Hymns")
                        .font(.title)
                        .bold()

                    Text("""
You can import hymns from **JSON** or **plain-text** files. \
Use the **Import** toolbar button, and select your file(s).
""")

                    Group {
                        Text("JSON – single hymn")
                            .font(.headline)
                        CodeBlock(text: jsonSingle)
                    }

                    Group {
                        Text("JSON – batch import")
                            .font(.headline)
                        CodeBlock(text: jsonBatch)
                    }

                    Group {
                        Text("Plain-text")
                            .font(.headline)
                        CodeBlock(text: plainText)
                        Text("Put the word **“Chorus”** on a line by itself immediately before the chorus section.")
                            .font(.callout)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            HStack {
                Spacer()
                Link("Support page", destination: URL(string: "https://paulobfsilva.github.io/ChurchHymn/support.html")!)
            }
        }
        .padding()
    }
}

/// A tiny helper for monospaced, selectable code blocks
private struct CodeBlock: View {
    let text: String
    var body: some View {
        ScrollView(.horizontal) {
            Text(text)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .padding(8)
                .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 6))
        }
    }
}

