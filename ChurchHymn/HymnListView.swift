import SwiftUI
import SwiftData

struct HymnListView: View {
    let hymns: [Hymn]
    @Binding var selected: Hymn?
    @Binding var selectedHymnsForDelete: Set<UUID>
    @Binding var isMultiSelectMode: Bool
    @Binding var editHymn: Hymn?
    @Binding var showingEdit: Bool
    @Binding var hymnToDelete: Hymn?
    @Binding var showingDeleteConfirmation: Bool
    @Binding var showingBatchDeleteConfirmation: Bool
    
    let onPresent: (Hymn) -> Void
    
    @State private var searchText = ""
    
    var filteredHymns: [Hymn] {
        if searchText.isEmpty {
            return hymns
        }
        return hymns.filter { hymn in
            let searchQuery = searchText.lowercased()
            
            // Search in title
            if hymn.title.lowercased().contains(searchQuery) {
                return true
            }
            
            // Search in song number if present
            if let number = hymn.songNumber,
               String(number).contains(searchQuery) {
                return true
            }
            
            // Search in lyrics if present
            if let lyrics = hymn.lyrics,
               lyrics.lowercased().contains(searchQuery) {
                return true
            }
            
            // Search in author if present
            if let author = hymn.author,
               author.lowercased().contains(searchQuery) {
                return true
            }
            
            return false
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            SearchBar(text: $searchText)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Hymns list
            List(filteredHymns, id: \.id, selection: $selected) { hymn in
                HStack {
                    if isMultiSelectMode {
                        Image(systemName: selectedHymnsForDelete.contains(hymn.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedHymnsForDelete.contains(hymn.id) ? .blue : .gray)
                            .onTapGesture {
                                if selectedHymnsForDelete.contains(hymn.id) {
                                    selectedHymnsForDelete.remove(hymn.id)
                                } else {
                                    selectedHymnsForDelete.insert(hymn.id)
                                }
                            }
                    }
                    Text(hymn.title)
                        .tag(hymn)
                }
                .onTapGesture {
                    if !isMultiSelectMode {
                        selected = hymn
                    }
                }
                .contextMenu {
                    Button("Edit") {
                        editHymn = hymn
                        selected = hymn
                        showingEdit = true
                    }
                    Divider()
                    Button("Delete", role: .destructive) {
                        if isMultiSelectMode {
                            selectedHymnsForDelete.insert(hymn.id)
                            showingBatchDeleteConfirmation = true
                        } else {
                            hymnToDelete = hymn
                            selected = hymn
                            showingDeleteConfirmation = true
                        }
                    }
                }
            }
            
            // Footer with total count
            HStack {
                Spacer()
                Text("\(filteredHymns.count) of \(hymns.count) hymns")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                Spacer()
            }
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(minWidth: 200)
    }
}

// Custom SearchBar to ensure immediate updates
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search hymns...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                // Add these modifiers to ensure immediate updates
                .onChange(of: text) { oldValue, newValue in
                    // Force immediate update
                    text = newValue
                }
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
} 