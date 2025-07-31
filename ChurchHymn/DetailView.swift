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
    var body: some View {
        Text("Select a hymn")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
} 