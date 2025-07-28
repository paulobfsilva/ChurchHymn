import SwiftUI
import AppKit

struct ExportSelectionView: View {
    let hymns: [Hymn]
    @Binding var selectedHymns: Set<UUID>
    @Binding var exportFormat: ExportFormat
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Title
            Text("Export Hymns")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            // Summary and format selection
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Selected: \(selectedHymns.count) hymn\(selectedHymns.count == 1 ? "" : "s")")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button("Select All") {
                        selectedHymns = Set(hymns.map { $0.id })
                    }
                    .disabled(selectedHymns.count == hymns.count)
                    
                    Button("Clear All") {
                        selectedHymns.removeAll()
                    }
                    .disabled(selectedHymns.isEmpty)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Export Format")
                        .font(.headline)
                    
                    Picker("Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.description).tag(format)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            // Hymn list
            List {
                ForEach(hymns) { hymn in
                    ExportSelectionHymnRow(
                        hymn: hymn,
                        isSelected: selectedHymns.contains(hymn.id),
                        onToggle: { isSelected in
                            if isSelected {
                                selectedHymns.insert(hymn.id)
                            } else {
                                selectedHymns.remove(hymn.id)
                            }
                        }
                    )
                }
            }
            
            // Toolbar buttons
            HStack {
                Spacer()
                Button("Cancel") {
                    onCancel()
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Button("Export") {
                    onConfirm()
                    dismiss()
                }
                .keyboardShortcut(.return)
                .disabled(selectedHymns.isEmpty)
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 400)
        .onAppear {
            // If no hymns are selected, select the first one by default
            if selectedHymns.isEmpty && !hymns.isEmpty {
                selectedHymns.insert(hymns.first!.id)
            }
        }
    }
}

struct ExportSelectionHymnRow: View {
    let hymn: Hymn
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack {
            Button(action: {
                onToggle(!isSelected)
            }) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(hymn.title)
                    .fontWeight(.medium)
                
                if let author = hymn.author, !author.isEmpty {
                    Text("Author: \(author)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let key = hymn.musicalKey, !key.isEmpty {
                    Text("Key: \(key)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let lyrics = hymn.lyrics, !lyrics.isEmpty {
                    Text(lyrics.prefix(100) + (lyrics.count > 100 ? "..." : ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
} 