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
            TextField("Title", text: $hymn.title)
            TextField("Key (e.g. G Major)", text: $hymn.musicalKey.unwrap(or: ""))
            TextField("Copyright (e.g. © 2025 Church)", text: $hymn.copyright.unwrap(or: ""))
            TextField("Author", text: $hymn.author.unwrap(or: ""))
            TextField("Tags (comma separated)", text: Binding(
                get: { hymn.tags?.joined(separator: ", ") ?? "" },
                set: { hymn.tags = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
            ))
            TextEditor(text: $hymn.lyrics.unwrap(or: ""))
                .border(Color.gray)
            TextField("Notes", text: $hymn.notes.unwrap(or: ""))
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                Spacer()
                Button("Save") {
                    onSave?(hymn)
                    dismiss()
                }
                .disabled(hymn.title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
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
