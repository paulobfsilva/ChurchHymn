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
            TextField("Key (e.g. G Major)", text: $hymn.musicalKey)
            TextField("Copyright (e.g. © 2025 Church)", text: $hymn.copyright)
            TextEditor(text: $hymn.lyrics)
                .border(Color.gray)
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
