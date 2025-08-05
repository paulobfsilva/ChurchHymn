import SwiftUI

struct DetailView: View {
    let hymn: Hymn
    var currentPresentationIndex: Int?
    var isPresenting: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Title and metadata
            VStack(alignment: .leading, spacing: 8) {
                Text(hymn.title)
                    .font(.title)
                    .padding(.bottom, 4)
                
                HStack {
                    if let number = hymn.songNumber {
                        Text("#\(number)")
                            .foregroundColor(.secondary)
                    }
                    if let key = hymn.musicalKey {
                        Text("Key: \(key)")
                            .foregroundColor(.secondary)
                    }
                    if let author = hymn.author {
                        Text("By: \(author)")
                            .foregroundColor(.secondary)
                    }
                }
                .font(.subheadline)
                
                if let copyright = hymn.copyright {
                    Text(copyright)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Lyrics with highlighting
            LyricsDetailView(
                hymn: hymn,
                currentPresentationIndex: currentPresentationIndex,
                isPresenting: isPresenting
            )
        }
    }
}

struct MultiSelectDetailView: View {
    let selectedHymnsForDelete: Set<UUID>
    
    var body: some View {
        VStack {
            Text("Multi-Select Mode")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.orange)
            
            Text("\(selectedHymnsForDelete.count) hymn\(selectedHymnsForDelete.count == 1 ? "" : "s") selected")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if !selectedHymnsForDelete.isEmpty {
                Text("Press Cmd+Delete to delete selected hymns")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyDetailView: View {
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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(spacing: 8) {
                    Text("Select a hymn to get started")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("You can also drag and drop .txt or .json files here to import hymns")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 10)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Import Formats")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("JSON – Single Hymn")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(jsonSingle)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(8)
                            .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("JSON – Multiple Hymns")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(jsonBatch)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(8)
                            .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Plain Text")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(plainText)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(8)
                            .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
                        
                        Text("Put the word 'Chorus' on a line by itself before the chorus section.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
} 
