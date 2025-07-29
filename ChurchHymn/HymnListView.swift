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
    
    var body: some View {
        List(hymns, id: \.id, selection: $selected) { hymn in
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
        .frame(minWidth: 200)
    }
} 