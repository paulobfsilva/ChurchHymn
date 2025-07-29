import SwiftUI
import SwiftData

struct HymnToolbar {
    let hymns: [Hymn]
    @Binding var selected: Hymn?
    @Binding var selectedHymnsForDelete: Set<UUID>
    @Binding var isMultiSelectMode: Bool
    @Binding var showingEdit: Bool
    @Binding var newHymn: Hymn?
    @Binding var importType: ImportType?
    @Binding var currentImportType: ImportType?
    @Binding var selectedHymnsForExport: Set<UUID>
    @Binding var showingExportSelection: Bool
    @Binding var hymnToDelete: Hymn?
    @Binding var showingDeleteConfirmation: Bool
    @Binding var showingBatchDeleteConfirmation: Bool
    
    let context: ModelContext
    let onPresent: (Hymn) -> Void
    
    func createToolbar() -> some ToolbarContent {
        Group {
            ToolbarItemGroup(placement: .navigation) {
                Button("Add") {
                    let hymn = Hymn(title: "")
                    context.insert(hymn)
                    // Don't save immediately - wait for user to save or cancel
                    newHymn = hymn
                    selected = hymn
                    showingEdit = true
                }
                Button("Import") { 
                    importType = .auto
                    currentImportType = .auto
                }
                .help("Import hymns from text or JSON files")
                Button("Export Selected") { 
                    if let hymn = selected {
                        selectedHymnsForExport = [hymn.id]
                        showingExportSelection = true
                    }
                }
                .disabled(selected == nil)
                Button("Export Multiple") { 
                    showingExportSelection = true
                }
                .disabled(hymns.isEmpty)
                            Button("Export All") { 
                selectedHymnsForExport = Set(hymns.map { $0.id })
                showingExportSelection = true
            }
            .disabled(hymns.isEmpty)
            Button("Export Large Collection") { 
                selectedHymnsForExport = Set(hymns.map { $0.id })
                showingExportSelection = true
                // This will automatically use streaming for large collections
            }
            .disabled(hymns.isEmpty)
            .help("Use streaming for large collections (>1000 hymns)")
                Divider()
                Button(isMultiSelectMode ? "Exit Multi-Select" : "Multi-Select") {
                    isMultiSelectMode.toggle()
                    if !isMultiSelectMode {
                        selectedHymnsForDelete.removeAll()
                    }
                }
                .foregroundColor(isMultiSelectMode ? .orange : .blue)
                .keyboardShortcut("m", modifiers: [.command])
                
                if isMultiSelectMode {
                    Button("Delete Selected (\(selectedHymnsForDelete.count))") {
                        showingBatchDeleteConfirmation = true
                    }
                    .disabled(selectedHymnsForDelete.isEmpty)
                    .foregroundColor(.red)
                    .keyboardShortcut(.delete, modifiers: [.command])
                } else {
                    Button("Delete Selected") {
                        hymnToDelete = selected
                        showingDeleteConfirmation = true
                    }
                    .disabled(selected == nil)
                    .foregroundColor(.red)
                }
            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Edit") {
                    showingEdit = true
                }
                .disabled(selected == nil)
                Button("Present") { 
                    if let hymn = selected { 
                        onPresent(hymn) 
                    } 
                }
                .disabled(selected == nil)
                Button("Delete") {
                    hymnToDelete = selected
                    showingDeleteConfirmation = true
                }
                .disabled(selected == nil)
                .keyboardShortcut(.delete, modifiers: [])
            }
        }
    }
} 