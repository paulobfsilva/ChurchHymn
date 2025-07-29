import SwiftUI

struct DetailView: View {
    let selected: Hymn?
    let isMultiSelectMode: Bool
    let selectedHymnsForDelete: Set<UUID>
    
    var body: some View {
        if isMultiSelectMode {
            MultiSelectDetailView(selectedHymnsForDelete: selectedHymnsForDelete)
        } else if let hymn = selected {
            LyricsDetailView(hymn: hymn)
        } else {
            EmptyDetailView()
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