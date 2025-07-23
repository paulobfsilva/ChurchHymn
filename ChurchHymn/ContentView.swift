import SwiftUI
import UniformTypeIdentifiers
import AppKit
import SwiftData

enum ExportType: Identifiable {
    case singlePlainText, singleJSON, batchJSON
    var id: Int { hashValue }
}

enum ImportType: Identifiable {
    case plainText, json
    var id: Int { hashValue }
}

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Hymn.title, order: .forward) private var hymns: [Hymn]
    @State private var selected: Hymn? = nil
    @State private var newHymn: Hymn? = nil
    @State private var showingEdit = false
    @State private var editHymn: Hymn? = nil
    @State private var importPicker = false
    @State private var importJSONPicker = false
    @State private var exportType: ExportType?
    @State private var importType: ImportType?
    @State private var exportURL: URL?

    var body: some View {
        NavigationSplitView {
            List(hymns, id: \.id, selection: $selected) { hymn in
                Text(hymn.title)
                    .tag(hymn)
            }
            .frame(minWidth: 200)
            .toolbar {
                // Sidebar actions
                ToolbarItemGroup(placement: .navigation) {
                    Button("Add") {
                        let hymn = Hymn(title: "")
                        context.insert(hymn)
                        try? context.save()
                        newHymn = hymn
                        selected = hymn
                        showingEdit = true
                    }
                    Button("Import Plain Text") { importType = .plainText }
                    Button("Import JSON") { importType = .json }
                    Button("Export Selected (Text)") { exportType = .singlePlainText }
                        .disabled(selected == nil)
                    Button("Export Selected (JSON)") { exportType = .singleJSON }
                        .disabled(selected == nil)
                    Button("Export All (JSON)") { exportType = .batchJSON }
                        .disabled(hymns.isEmpty)
                }
                // Detail actions
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("Edit") {
                        editHymn = selected
                        showingEdit = true
                    }
                        .disabled(selected == nil)
                    Button("Present") { if let hymn = selected { present(hymn) } }
                        .disabled(selected == nil)
                }
            }
            .fileImporter(
                isPresented: Binding(get: { importType != nil }, set: { if !$0 { importType = nil } }),
                allowedContentTypes: importType == .json ? [UTType.json] : [UTType.plainText],
                allowsMultipleSelection: false
            ) { result in
                if case let .success(urls) = result, let url = urls.first {
                    switch importType {
                    case .plainText:
                        importPlainTextHymn(from: url)
                    case .json:
                        importBatchJSON(from: url)
                    case .none:
                        break
                    }
                }
            }
            .fileExporter(
                isPresented: Binding(get: { exportType != nil }, set: { if !$0 { exportType = nil } }),
                document: exportDocument,
                contentType: exportContentType,
                defaultFilename: exportDefaultFilename
            ) { result in
                if case let .success(url) = result, let type = exportType {
                    switch type {
                    case .singlePlainText:
                        if let hymn = selected { exportPlainTextHymn(hymn, to: url) }
                    case .singleJSON:
                        if let hymn = selected { exportSingleJSONHymn(hymn, to: url) }
                    case .batchJSON:
                        exportBatchJSON(hymns, to: url)
                    }
                }
            }
        } detail: {
            if let hymn = selected {
                LyricsDetailView(hymn: hymn)
            } else {
                Text("Select a hymn")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showingEdit) {
            if let hymn = selected { HymnEditView(hymn: hymn) }
        }
    }

    // MARK: - Actions

    private func deleteHymns(at offsets: IndexSet) {
        for index in offsets {
            let hymn = hymns[index]
            context.delete(hymn)
        }
    }

    private func importFromFile(_ url: URL) {
        guard let text = try? String(contentsOf: url) else { return }
        let titleLine = text
            .components(separatedBy: .newlines)
            .first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) ?? ""
        let body = text.dropFirst(titleLine.count)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let newHymn = Hymn(title: titleLine, lyrics: body)
        context.insert(newHymn)
        try? context.save()
    }

    // MARK: - Import/Export Helpers

    private func importPlainTextHymn(from url: URL) {
        guard let text = try? String(contentsOf: url),
              let hymn = Hymn.fromPlainText(text) else { return }
        context.insert(hymn)
        try? context.save()
    }

    private func importBatchJSON(from url: URL) {
        guard let data = try? Data(contentsOf: url),
              let hymns = Hymn.arrayFromJSON(data) else { return }
        for hymn in hymns {
            context.insert(hymn)
        }
        try? context.save()
    }

    private func exportPlainTextHymn(_ hymn: Hymn, to url: URL) {
        let text = hymn.toPlainText()
        try? text.write(to: url, atomically: true, encoding: .utf8)
    }

    private func exportSingleJSONHymn(_ hymn: Hymn, to url: URL) {
        guard let data = hymn.toJSON(pretty: true) else { return }
        try? data.write(to: url)
    }

    private func exportBatchJSON(_ hymns: [Hymn], to url: URL) {
        guard let data = Hymn.arrayToJSON(hymns, pretty: true) else { return }
        try? data.write(to: url)
    }

    // MARK: - File Exporter Helpers

    private var exportDocument: some FileDocument {
        struct ExportDoc: FileDocument {
            static var readableContentTypes: [UTType] = [.plainText, .json]
            var data: Data
            init(data: Data) { self.data = data }
            init(configuration: ReadConfiguration) throws { self.data = configuration.file.regularFileContents ?? Data() }
            func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { .init(regularFileWithContents: data) }
        }
        switch exportType {
        case .singlePlainText:
            if let hymn = selected {
                return ExportDoc(data: (hymn.toPlainText().data(using: .utf8) ?? Data()))
            }
        case .singleJSON:
            if let hymn = selected, let data = hymn.toJSON(pretty: true) {
                return ExportDoc(data: data)
            }
        case .batchJSON:
            if let data = Hymn.arrayToJSON(hymns, pretty: true) {
                return ExportDoc(data: data)
            }
        case .none:
            break
        }
        // Always return a default ExportDoc if no other case matches
        return ExportDoc(data: Data())
    }

    private var exportContentType: UTType {
        switch exportType {
        case .singlePlainText: return .plainText
        case .singleJSON, .batchJSON: return .json
        default: return .plainText
        }
    }

    private var exportDefaultFilename: String {
        switch exportType {
        case .singlePlainText: return (selected?.title ?? "Hymn") + ".txt"
        case .singleJSON: return (selected?.title ?? "Hymn") + ".json"
        case .batchJSON: return "Hymns.json"
        default: return "Export"
        }
    }

    // MARK: - Presenter

    private func present(_ hymn: Hymn) {
        guard let screen = NSScreen.main else { return }
        let window = NSWindow(
            contentRect: screen.visibleFrame,
            styleMask: [.titled, .fullSizeContentView, .resizable, .closable, .miniaturizable],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        window.contentViewController = NSHostingController(rootView: PresenterView(hymn: hymn))
        window.collectionBehavior = [.fullScreenPrimary, .fullScreenAllowsTiling, .canJoinAllSpaces]
        window.title = hymn.title
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        presenterWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            window.toggleFullScreen(nil)
        }
    }
}
