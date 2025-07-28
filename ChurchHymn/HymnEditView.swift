//
//  HymnEditView.swift
//  ChurchHymn
//
//  Created by paulo on 20/05/2025.
//
import SwiftUI
import SwiftData

struct HymnEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var hymn: Hymn
    var onSave: ((Hymn) -> Void)?

    init(hymn: Hymn, onSave: ((Hymn) -> Void)? = nil) {
        self._hymn = Bindable(wrappedValue: hymn)
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header section with basic info
            VStack(alignment: .leading, spacing: 12) {
                Text("Hymn Details")
                    .font(.headline)
                    .fontWeight(.bold)
                
                TextField("Title", text: $hymn.title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                HStack(spacing: 12) {
                    TextField("Key (e.g. G Major)", text: $hymn.musicalKey.unwrap(or: ""))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Author", text: $hymn.author.unwrap(or: ""))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                TextField("Copyright (e.g. © 2025 Church)", text: $hymn.copyright.unwrap(or: ""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Tags (comma separated)", text: Binding(
                    get: { hymn.tags?.joined(separator: ", ") ?? "" },
                    set: { hymn.tags = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Lyrics section
            VStack(alignment: .leading, spacing: 8) {
                Text("Lyrics")
                    .font(.headline)
                    .fontWeight(.bold)
                
                TextEditor(text: $hymn.lyrics.unwrap(or: ""))
                    .frame(minHeight: 200, maxHeight: .infinity)
                    .padding(8)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
            
            // Notes section
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.headline)
                    .fontWeight(.bold)
                
                TextField("Additional notes...", text: $hymn.notes.unwrap(or: ""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Buttons
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("Save") {
                    onSave?(hymn)
                    dismiss()
                }
                .keyboardShortcut(.return)
                .disabled(hymn.title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .frame(minWidth: 500, minHeight: 600)
    }
}

extension Binding where Value == String? {
    func unwrap(or defaultValue: String) -> Binding<String> {
        Binding<String>(
            get: { self.wrappedValue ?? defaultValue },
            set: { self.wrappedValue = $0.isEmpty ? nil : $0 }
        )
    }
}
