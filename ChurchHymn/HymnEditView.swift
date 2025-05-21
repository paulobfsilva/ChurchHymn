//
//  HymnEditView.swift
//  ChurchHymn
//
//  Created by paulo on 20/05/2025.
//
import SwiftUI
import SwiftData

struct HymnEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var hymn: Hymn
    private let isNew: Bool
    @State private var title: String
    @State private var lyrics: String

    /// Edit existing
    init(hymn: Hymn) {
        self._hymn = Bindable(wrappedValue: hymn)
        self._title = State(initialValue: hymn.title)
        self._lyrics = State(initialValue: hymn.lyrics)
        self.isNew = false
    }

    /// Add new
    init() {
        let new = Hymn(title: "", lyrics: "")
        self._hymn = Bindable(wrappedValue: new)
        self._title = State(initialValue: "")
        self._lyrics = State(initialValue: "")
        self.isNew = true
    }

    var body: some View {
        VStack(spacing: 16) {
            TextField("Title", text: $title)
            TextEditor(text: $lyrics)
                .border(Color.gray)
            HStack {
                Button("Cancel") {
                    if isNew { /* nothing */ }
                    dismiss()
                }
                Spacer()
                Button("Save") {
                    hymn.title = title
                    hymn.lyrics = lyrics
                    if isNew {
                        context.insert(hymn)
                    }
                    dismiss()
                }
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
    }
}
