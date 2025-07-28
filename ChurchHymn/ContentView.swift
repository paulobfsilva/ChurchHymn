import SwiftUI
import UniformTypeIdentifiers
import AppKit
import SwiftData
import Foundation

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Hymn.title, order: .forward) private var hymns: [Hymn]
    
    // Core state
    @State private var selected: Hymn? = nil
    @State private var newHymn: Hymn? = nil
    @State private var showingEdit = false
    @State private var editHymn: Hymn? = nil
    
    // Import/Export state
    @State private var exportType: ExportType?
    @State private var importType: ImportType?
    @State private var currentImportType: ImportType?
    
    // Error handling states
    @State private var importError: ImportError?
    @State private var showingErrorAlert = false
    @State private var importSuccessMessage: String?
    @State private var showingSuccessAlert = false
    
    // Import preview states
    @State private var importPreview: ImportPreview?
    @State private var showingImportPreview = false
    @State private var selectedHymnsForImport: Set<UUID> = []
    @State private var duplicateResolution: DuplicateResolution = .skip
    
    // Export selection states
    @State private var showingExportSelection = false
    @State private var selectedHymnsForExport: Set<UUID> = []
    @State private var exportFormat: ExportFormat = .json
    
    // Delete confirmation states
    @State private var showingDeleteConfirmation = false
    @State private var hymnToDelete: Hymn?
    
    // Multi-select states for batch delete
    @State private var selectedHymnsForDelete: Set<UUID> = []
    @State private var isMultiSelectMode = false
    @State private var showingBatchDeleteConfirmation = false
    
    // Operations
    @StateObject private var operations: HymnOperations
    
    init() {
        // Initialize operations with a temporary context - will be updated in onAppear
        self._operations = StateObject(wrappedValue: HymnOperations(context: ModelContext(try! ModelContainer(for: Hymn.self))))
    }

    var body: some View {
        NavigationSplitView {
            HymnListView(
                hymns: hymns,
                selected: $selected,
                selectedHymnsForDelete: $selectedHymnsForDelete,
                isMultiSelectMode: $isMultiSelectMode,
                editHymn: $editHymn,
                showingEdit: $showingEdit,
                hymnToDelete: $hymnToDelete,
                showingDeleteConfirmation: $showingDeleteConfirmation,
                showingBatchDeleteConfirmation: $showingBatchDeleteConfirmation,
                onPresent: present
            )
            .toolbar {
                HymnToolbar(
                    hymns: hymns,
                    selected: $selected,
                    selectedHymnsForDelete: $selectedHymnsForDelete,
                    isMultiSelectMode: $isMultiSelectMode,
                    showingEdit: $showingEdit,
                    newHymn: $newHymn,
                    importType: $importType,
                    currentImportType: $currentImportType,
                    selectedHymnsForExport: $selectedHymnsForExport,
                    showingExportSelection: $showingExportSelection,
                    hymnToDelete: $hymnToDelete,
                    showingDeleteConfirmation: $showingDeleteConfirmation,
                    showingBatchDeleteConfirmation: $showingBatchDeleteConfirmation,
                    context: context,
                    onPresent: present
                ).createToolbar()
            }
            .fileImporter(
                isPresented: Binding(get: { importType != nil }, set: { if !$0 { 
                    importType = nil
                } }),
                allowedContentTypes: importType == .json ? [UTType.json] : [UTType.plainText],
                allowsMultipleSelection: false
            ) { result in
                let importTypeToUse = importType ?? currentImportType
                handleImportResult(result, importType: importTypeToUse)
            }
            .fileExporter(
                isPresented: Binding(get: { exportType != nil }, set: { if !$0 { 
                    exportType = nil
                    cleanupAfterExport()
                } }),
                document: exportDocument,
                contentType: exportContentType,
                defaultFilename: exportDefaultFilename
            ) { result in
                if case let .success(url) = result, let type = exportType {
                    handleExportResult(type, url: url)
                }
            }
            .alert("Import Error", isPresented: $showingErrorAlert, presenting: importError) { error in
                Button("OK") { }
            } message: { error in
                Text(error.detailedErrorDescription)
            }
            .alert("Import Successful", isPresented: $showingSuccessAlert) {
                Button("OK") { }
            } message: {
                Text(importSuccessMessage ?? "Hymn imported successfully.")
            }
            .alert("Delete Hymn", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteHymn()
                }
            } message: {
                if let hymn = hymnToDelete {
                    Text("Are you sure you want to delete '\(hymn.title)'? This action cannot be undone.")
                }
            }
            .alert("Delete Multiple Hymns", isPresented: $showingBatchDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete \(selectedHymnsForDelete.count) Hymn\(selectedHymnsForDelete.count == 1 ? "" : "s")", role: .destructive) {
                    deleteSelectedHymns()
                }
            } message: {
                let hymnTitles = hymns.filter { selectedHymnsForDelete.contains($0.id) }.map { $0.title }
                let titleList = hymnTitles.prefix(3).joined(separator: ", ")
                let remainingCount = max(0, hymnTitles.count - 3)
                
                var message = "Are you sure you want to delete the following hymn\(selectedHymnsForDelete.count == 1 ? "" : "s")? This action cannot be undone.\n\n\(titleList)"
                
                if remainingCount > 0 {
                    message += "\n\n...and \(remainingCount) more"
                }
                
                return Text(message)
            }

        } detail: {
            if isMultiSelectMode {
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
            } else if let hymn = selected {
                LyricsDetailView(hymn: hymn)
            } else {
                Text("Select a hymn")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showingEdit) {
            if let hymn = selected { 
                HymnEditView(hymn: hymn, onSave: { savedHymn in
                    try? context.save()
                    if newHymn == savedHymn {
                        newHymn = nil
                    }
                })
            }
        }
        .onChange(of: showingEdit) { _, isShowing in
            if !isShowing {
                cleanupEmptyHymn()
            }
        }
        .sheet(isPresented: $showingImportPreview) {
            if let preview = importPreview {
                ImportPreviewView(
                    preview: preview,
                    selectedHymns: $selectedHymnsForImport,
                    duplicateResolution: $duplicateResolution,
                    onConfirm: confirmImport,
                    onCancel: cancelImport
                )
            }
        }
        .sheet(isPresented: $showingExportSelection) {
            ExportSelectionView(
                hymns: hymns,
                selectedHymns: $selectedHymnsForExport,
                exportFormat: $exportFormat,
                onConfirm: confirmExport,
                onCancel: cancelExport
            )
        }
        .overlay(
            Group {
                if operations.isImporting || operations.isExporting {
                    ProgressOverlay(
                        isImporting: operations.isImporting,
                        isExporting: operations.isExporting,
                        progress: operations.isImporting ? operations.importProgress : operations.exportProgress,
                        message: operations.progressMessage
                    )
                }
            }
        )
        .onAppear {
            // Update operations context with the actual context
            operations.updateContext(context)
        }
    }

    // MARK: - Actions
    
    private func present(_ hymn: Hymn) {
        if let window = NSApplication.shared.windows.first(where: { $0.title == "Presenter" }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            let presenterWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            presenterWindow.title = "Presenter"
            presenterWindow.contentView = NSHostingView(rootView: PresenterView(hymn: hymn))
            presenterWindow.makeKeyAndOrderFront(nil)
        }
    }
    
    private func deleteHymn() {
        guard let hymn = hymnToDelete else { return }
        
        context.delete(hymn)
        
        if selected == hymn {
            selected = nil
        }
        if editHymn == hymn {
            editHymn = nil
        }
        if newHymn == hymn {
            newHymn = nil
        }
        
        do {
            try context.save()
        } catch {
            print("Error saving after delete: \(error)")
        }
        
        hymnToDelete = nil
        showingDeleteConfirmation = false
    }
    
    private func deleteSelectedHymns() {
        let hymnsToDelete = hymns.filter { selectedHymnsForDelete.contains($0.id) }
        
        for hymn in hymnsToDelete {
            context.delete(hymn)
            
            if selected == hymn {
                selected = nil
            }
            if editHymn == hymn {
                editHymn = nil
            }
            if newHymn == hymn {
                newHymn = nil
            }
        }
        
        do {
            try context.save()
        } catch {
            print("Error saving after batch delete: \(error)")
        }
        
        selectedHymnsForDelete.removeAll()
        isMultiSelectMode = false
        showingBatchDeleteConfirmation = false
    }
    
    private func cleanupEmptyHymn() {
        if let hymn = newHymn, hymn.title.trimmingCharacters(in: .whitespaces).isEmpty {
            context.delete(hymn)
            
            if selected == hymn {
                selected = nil
            }
            if editHymn == hymn {
                editHymn = nil
            }
            newHymn = nil
            
            do {
                try context.save()
            } catch {
                print("Error saving after cleanup: \(error)")
            }
        }
    }
    
    private func cleanupAfterExport() {
        selectedHymnsForExport.removeAll()
    }
    
    // MARK: - Import/Export Handlers
    
    private func handleImportResult(_ result: Result<[URL], Error>, importType: ImportType?) {
        print("DEBUG: importType parameter = \(String(describing: importType))")
        
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                showError(.unknown("No file selected"))
                return
            }
            
            guard let importType = importType else {
                showError(.unknown("Unknown import type"))
                return
            }
            
            switch importType {
            case .plainText:
                operations.importPlainTextHymn(
                    from: url,
                    hymns: hymns,
                    onComplete: { preview in
                        importPreview = preview
                        showingImportPreview = true
                    },
                    onError: { error in
                        showError(error)
                    }
                )
            case .json:
                operations.importBatchJSON(
                    from: url,
                    hymns: hymns,
                    onComplete: { preview in
                        importPreview = preview
                        showingImportPreview = true
                    },
                    onError: { error in
                        showError(error)
                    }
                )
            }
            
        case .failure(let error):
            let nsError = error as NSError
            let specificError = getSpecificFileError(nsError)
            showError(specificError)
        }
        
        currentImportType = nil
    }
    
    private func handleExportResult(_ type: ExportType, url: URL) {
        switch type {
        case .singlePlainText:
            if let hymn = selected {
                operations.exportPlainTextHymn(
                    hymn,
                    to: url,
                    onComplete: { },
                    onError: { error in
                        showError(error)
                    }
                )
            }
        case .singleJSON:
            if let hymn = selected {
                operations.exportSingleJSONHymn(
                    hymn,
                    to: url,
                    onComplete: { },
                    onError: { error in
                        showError(error)
                    }
                )
            }
        case .multipleJSON:
            let hymnsToExport = hymns.filter { selectedHymnsForExport.contains($0.id) }
            operations.exportBatchJSON(
                hymnsToExport,
                to: url,
                onComplete: { },
                onError: { error in
                    showError(error)
                }
            )
        case .batchJSON:
            operations.exportBatchJSON(
                hymns,
                to: url,
                onComplete: { },
                onError: { error in
                    showError(error)
                }
            )
        }
    }
    
    // MARK: - Import Preview Functions
    
    private func confirmImport() {
        guard let preview = importPreview else { return }
        
        let selectedValidHymns = preview.hymns.filter { selectedHymnsForImport.contains($0.id) }
        let selectedDuplicateHymns = preview.duplicates.filter { selectedHymnsForImport.contains($0.id) }
        
        var hymnsToImport: [Hymn] = []
        var duplicatesToProcess: [DuplicateHymn] = []
        
        for previewHymn in selectedValidHymns {
            let hymn = Hymn(
                title: previewHymn.title,
                lyrics: previewHymn.lyrics,
                musicalKey: previewHymn.musicalKey,
                copyright: previewHymn.copyright,
                author: previewHymn.author,
                tags: previewHymn.tags,
                notes: previewHymn.notes
            )
            hymnsToImport.append(hymn)
        }
        
        for previewHymn in selectedDuplicateHymns {
            if let existingHymn = previewHymn.existingHymn {
                let newHymn = Hymn(
                    title: previewHymn.title,
                    lyrics: previewHymn.lyrics,
                    musicalKey: previewHymn.musicalKey,
                    copyright: previewHymn.copyright,
                    author: previewHymn.author,
                    tags: previewHymn.tags,
                    notes: previewHymn.notes
                )
                duplicatesToProcess.append(DuplicateHymn(existing: existingHymn, new: newHymn))
            }
        }
        
        processFinalImport(validHymns: hymnsToImport, duplicates: duplicatesToProcess, errors: preview.errors)
    }
    
    private func cancelImport() {
        showingImportPreview = false
        importPreview = nil
        selectedHymnsForImport.removeAll()
    }
    
    private func processFinalImport(validHymns: [Hymn], duplicates: [DuplicateHymn], errors: [String]) {
        Task {
            await MainActor.run {
                operations.isImporting = true
                operations.importProgress = 0.0
                operations.progressMessage = "Processing import..."
            }
            
            do {
                let totalItems = validHymns.count + duplicates.count
                var processedItems = 0
                
                switch duplicateResolution {
                case .skip:
                    break
                case .merge:
                    for duplicate in duplicates {
                        await MainActor.run {
                            operations.importProgress = Double(processedItems) / Double(totalItems)
                            operations.progressMessage = "Merging duplicate: \(duplicate.newHymn.title)..."
                        }
                        mergeHymnData(existing: duplicate.existingHymn, new: duplicate.newHymn)
                        processedItems += 1
                    }
                case .replace:
                    for duplicate in duplicates {
                        await MainActor.run {
                            operations.importProgress = Double(processedItems) / Double(totalItems)
                            operations.progressMessage = "Replacing duplicate: \(duplicate.newHymn.title)..."
                        }
                        replaceHymnData(existing: duplicate.existingHymn, new: duplicate.newHymn)
                        processedItems += 1
                    }
                }
                
                for hymn in validHymns {
                    await MainActor.run {
                        operations.importProgress = Double(processedItems) / Double(totalItems)
                        operations.progressMessage = "Importing hymn: \(hymn.title)..."
                    }
                    context.insert(hymn)
                    processedItems += 1
                }
                
                await MainActor.run {
                    operations.importProgress = 0.9
                    operations.progressMessage = "Saving to database..."
                }
                
                try context.save()
                
                await MainActor.run {
                    operations.importProgress = 1.0
                    operations.progressMessage = "Import complete!"
                }
                
                var message = "Successfully imported \(validHymns.count) hymn\(validHymns.count == 1 ? "" : "s")"
                
                if !duplicates.isEmpty {
                    let duplicateCount = duplicates.count
                    switch duplicateResolution {
                    case .skip:
                        message += ". Skipped \(duplicateCount) duplicate\(duplicateCount == 1 ? "" : "s")"
                    case .merge:
                        message += ". Merged \(duplicateCount) duplicate\(duplicateCount == 1 ? "" : "s")"
                    case .replace:
                        message += ". Replaced \(duplicateCount) duplicate\(duplicateCount == 1 ? "" : "s")"
                    }
                }
                
                if !errors.isEmpty {
                    message += ". \(errors.count) error\(errors.count == 1 ? "" : "s") encountered"
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    operations.isImporting = false
                    showSuccess(message)
                }
                
            } catch {
                await MainActor.run {
                    operations.isImporting = false
                }
                showError(.unknown("Failed to save imported hymns: \(error.localizedDescription)"))
            }
        }
    }
    
    // MARK: - Export Functions
    
    private func confirmExport() {
        let hymnsToExport = hymns.filter { selectedHymnsForExport.contains($0.id) }
        
        if hymnsToExport.isEmpty {
            showError(.unknown("No hymns selected for export"))
            return
        }
        
        if hymnsToExport.count == 1 {
            exportType = exportFormat == .json ? .singleJSON : .singlePlainText
        } else {
            exportType = exportFormat == .json ? .multipleJSON : .batchJSON
        }
        
        showingExportSelection = false
    }
    
    private func cancelExport() {
        showingExportSelection = false
        selectedHymnsForExport.removeAll()
    }
    
    // MARK: - Helper Functions
    
    private func showError(_ error: ImportError) {
        importError = error
        showingErrorAlert = true
    }
    
    private func showSuccess(_ message: String) {
        importSuccessMessage = message
        showingSuccessAlert = true
    }
    
    private func mergeHymnData(existing: Hymn, new: Hymn) {
        if (existing.lyrics?.isEmpty ?? true) && !(new.lyrics?.isEmpty ?? true) {
            existing.lyrics = new.lyrics
        }
        if (existing.musicalKey?.isEmpty ?? true) && !(new.musicalKey?.isEmpty ?? true) {
            existing.musicalKey = new.musicalKey
        }
        if (existing.author?.isEmpty ?? true) && !(new.author?.isEmpty ?? true) {
            existing.author = new.author
        }
        if (existing.copyright?.isEmpty ?? true) && !(new.copyright?.isEmpty ?? true) {
            existing.copyright = new.copyright
        }
        if (existing.notes?.isEmpty ?? true) && !(new.notes?.isEmpty ?? true) {
            existing.notes = new.notes
        }
        if (existing.tags?.isEmpty ?? true) && !(new.tags?.isEmpty ?? true) {
            existing.tags = new.tags
        }
    }
    
    private func replaceHymnData(existing: Hymn, new: Hymn) {
        existing.lyrics = new.lyrics
        existing.musicalKey = new.musicalKey
        existing.author = new.author
        existing.copyright = new.copyright
        existing.notes = new.notes
        existing.tags = new.tags
    }
    
    private func getSpecificFileError(_ error: NSError) -> ImportError {
        switch error.code {
        case NSFileReadNoPermissionError:
            return .permissionDenied
        case NSFileReadNoSuchFileError:
            return .fileNotFound
        case NSFileReadCorruptFileError:
            return .corruptedData("File appears to be corrupted")
        case NSFileReadInapplicableStringEncodingError:
            return .invalidFormat("File encoding is not supported. Please ensure the file uses UTF-8 encoding.")
        case NSFileReadTooLargeError:
            return .fileReadFailed("File is too large to read")
        case NSFileReadUnknownStringEncodingError:
            return .invalidFormat("Unknown file encoding. Please ensure the file uses UTF-8 encoding.")
        default:
            return .fileReadFailed(error.localizedDescription)
        }
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
        case .multipleJSON:
            let hymnsToExport = hymns.filter { selectedHymnsForExport.contains($0.id) }
            if let data = Hymn.arrayToJSON(hymnsToExport, pretty: true) {
                return ExportDoc(data: data)
            }
        case .batchJSON:
            if let data = Hymn.arrayToJSON(hymns, pretty: true) {
                return ExportDoc(data: data)
            }
        case .none:
            break
        }
        return ExportDoc(data: Data())
    }
    
    private var exportContentType: UTType {
        switch exportType {
        case .singlePlainText: return .plainText
        case .singleJSON, .multipleJSON, .batchJSON: return .json
        default: return .plainText
        }
    }
    
    private var exportDefaultFilename: String {
        switch exportType {
        case .singlePlainText: return (selected?.title ?? "Hymn") + ".txt"
        case .singleJSON: return (selected?.title ?? "Hymn") + ".json"
        case .multipleJSON: return "Selected_Hymns.json"
        case .batchJSON: return "Hymns.json"
        default: return "Export"
        }
    }
}
