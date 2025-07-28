import SwiftUI
import UniformTypeIdentifiers
import AppKit
import SwiftData
import Foundation

enum ExportType: Identifiable {
    case singlePlainText, singleJSON, batchJSON
    var id: Int { hashValue }
}

enum ImportType: Identifiable {
    case plainText, json
    var id: Int { hashValue }
}

// MARK: - Import Error Types
enum ImportError: LocalizedError, Identifiable {
    case fileReadFailed(String)
    case invalidFormat(String)
    case missingTitle
    case emptyFile
    case permissionDenied
    case fileNotFound
    case corruptedData(String)
    case duplicateHymn(String)
    case unknown(String)
    
    // Enhanced error details for better user feedback
    var detailedErrorDescription: String {
        switch self {
        case .fileReadFailed(let reason):
            return "Failed to read file: \(reason)"
        case .invalidFormat(let details):
            return "Invalid file format: \(details)"
        case .missingTitle:
            return "Hymn title is missing or empty"
        case .emptyFile:
            return "The selected file is empty"
        case .permissionDenied:
            return "Permission denied. Please check file permissions."
        case .fileNotFound:
            return "File not found. It may have been moved or deleted."
        case .corruptedData(let details):
            return "File appears to be corrupted: \(details)"
        case .duplicateHymn(let title):
            return "A hymn with the title '\(title)' already exists"
        case .unknown(let message):
            return "An unexpected error occurred: \(message)"
        }
    }
    
    var id: String {
        switch self {
        case .fileReadFailed: return "fileReadFailed"
        case .invalidFormat: return "invalidFormat"
        case .missingTitle: return "missingTitle"
        case .emptyFile: return "emptyFile"
        case .permissionDenied: return "permissionDenied"
        case .fileNotFound: return "fileNotFound"
        case .corruptedData: return "corruptedData"
        case .duplicateHymn: return "duplicateHymn"
        case .unknown: return "unknown"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .fileReadFailed(let reason):
            return "Failed to read file: \(reason)"
        case .invalidFormat(let details):
            return "Invalid file format: \(details)"
        case .missingTitle:
            return "Hymn title is missing or empty"
        case .emptyFile:
            return "The selected file is empty"
        case .permissionDenied:
            return "Permission denied. Please check file permissions."
        case .fileNotFound:
            return "File not found. It may have been moved or deleted."
        case .corruptedData(let details):
            return "File appears to be corrupted: \(details)"
        case .duplicateHymn(let title):
            return "A hymn with the title '\(title)' already exists"
        case .unknown(let message):
            return "An unexpected error occurred: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .fileReadFailed:
            return "Please ensure the file exists and is not corrupted."
        case .invalidFormat:
            return "Please check that the file format matches the expected structure."
        case .missingTitle:
            return "Please ensure the first non-empty line contains the hymn title."
        case .emptyFile:
            return "Please select a file that contains hymn data."
        case .permissionDenied:
            return "Please check the file permissions or try selecting a different file."
        case .fileNotFound:
            return "Please verify the file location and try again."
        case .corruptedData:
            return "Please try with a different file or check the file integrity."
        case .duplicateHymn:
            return "You can either rename the existing hymn or choose a different file."
        case .unknown:
            return "Please try again or contact support if the problem persists."
        }
    }
}



// MARK: - Duplicate Handling
struct DuplicateHymn: Identifiable {
    let id = UUID()
    let existingHymn: Hymn
    let newHymn: Hymn
    let title: String
    
    init(existing: Hymn, new: Hymn) {
        self.existingHymn = existing
        self.newHymn = new
        self.title = existing.title
    }
}

enum DuplicateResolution: String, CaseIterable {
    case skip = "Skip"
    case merge = "Merge"
    case replace = "Replace"
    
    var description: String {
        switch self {
        case .skip:
            return "Skip duplicate hymns"
        case .merge:
            return "Merge new data with existing hymns"
        case .replace:
            return "Replace existing hymns with new data"
        }
    }
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
    
    // Error handling states
    // Error handling states
    @State private var importError: ImportError?
    @State private var showingErrorAlert = false
    @State private var importSuccessMessage: String?
    @State private var showingSuccessAlert = false
    

    
    // Store the current import type to avoid timing issues
    @State private var currentImportType: ImportType?
    
    // Import preview states
    @State private var importPreview: ImportPreview?
    @State private var showingImportPreview = false
    @State private var selectedHymnsForImport: Set<UUID> = []
    @State private var duplicateResolution: DuplicateResolution = .skip

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
                    Button("Import Plain Text") { 
                        importType = .plainText
                        currentImportType = .plainText
                    }
                    Button("Import JSON") { 
                        importType = .json
                        currentImportType = .json
                    }
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
                isPresented: Binding(get: { importType != nil }, set: { if !$0 { 
                    importType = nil
                } }),
                allowedContentTypes: importType == .json ? [UTType.json] : [UTType.plainText],
                allowsMultipleSelection: false
            ) { result in
                // Store the import type before processing to avoid timing issues
                let importTypeToUse = importType ?? currentImportType
                handleImportResult(result, importType: importTypeToUse)
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

    // MARK: - Import Result Handler
    
    private func handleImportResult(_ result: Result<[URL], Error>, importType: ImportType?) {
        // Debug: Print the import type
        print("DEBUG: importType parameter = \(String(describing: importType))")
        
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                showError(.unknown("No file selected"))
                return
            }
            
            // Start accessing the security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                showError(.permissionDenied)
                return
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            // Check if file exists
            guard FileManager.default.fileExists(atPath: url.path) else {
                showError(.fileNotFound)
                return
            }
            
            // Perform import based on type
            switch importType {
            case .plainText:
                print("DEBUG: Importing as plain text")
                importPlainTextHymn(from: url)
            case .json:
                print("DEBUG: Importing as JSON")
                importBatchJSON(from: url)
            case .none:
                print("DEBUG: importType is nil! Trying to determine from file extension...")
                // Fallback: try to determine import type from file extension
                let fileExtension = url.pathExtension.lowercased()
                if fileExtension == "json" {
                    print("DEBUG: Detected JSON from file extension")
                    importBatchJSON(from: url)
                } else if fileExtension == "txt" || fileExtension.isEmpty {
                    print("DEBUG: Detected plain text from file extension")
                    importPlainTextHymn(from: url)
                } else {
                    showError(.unknown("Unknown import type - importType is nil and could not determine from file extension"))
                }
            }
            
        case .failure(let error):
            let nsError = error as NSError
            switch nsError.code {
            case NSFileReadNoPermissionError:
                showError(.permissionDenied)
            case NSFileReadNoSuchFileError:
                showError(.fileNotFound)
            case NSFileReadCorruptFileError:
                showError(.corruptedData("File appears to be corrupted"))
            default:
                showError(.unknown(error.localizedDescription))
            }
        }
        
        // Clear the current import type after processing
        currentImportType = nil
    }
    
    // MARK: - Import Preview Functions
    
    private func confirmImport() {
        guard let preview = importPreview else { return }
        
        // Get selected hymns
        let selectedValidHymns = preview.hymns.filter { selectedHymnsForImport.contains($0.id) }
        let selectedDuplicateHymns = preview.duplicates.filter { selectedHymnsForImport.contains($0.id) }
        
        // Convert back to Hymn objects for processing
        var hymnsToImport: [Hymn] = []
        var duplicatesToProcess: [DuplicateHymn] = []
        
        // Process valid hymns
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
        
        // Process duplicates
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
        
        // Process the import
        processFinalImport(validHymns: hymnsToImport, duplicates: duplicatesToProcess, errors: preview.errors)
        
        // Clear preview state
        importPreview = nil
        selectedHymnsForImport.removeAll()
    }
    
    private func cancelImport() {
        importPreview = nil
        selectedHymnsForImport.removeAll()
    }
    
    private func processFinalImport(validHymns: [Hymn], duplicates: [DuplicateHymn], errors: [String]) {
        do {
            // Handle duplicates based on resolution
            switch duplicateResolution {
            case .skip:
                // Skip duplicates, only import new hymns
                break
            case .merge:
                // Merge new data with existing hymns
                for duplicate in duplicates {
                    mergeHymnData(existing: duplicate.existingHymn, new: duplicate.newHymn)
                }
            case .replace:
                // Replace existing hymns with new data
                for duplicate in duplicates {
                    replaceHymnData(existing: duplicate.existingHymn, new: duplicate.newHymn)
                }
            }
            
            // Insert all valid hymns
            for hymn in validHymns {
                context.insert(hymn)
            }
            
            try context.save()
            
            // Generate success message
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
            
            showSuccess(message)
            
        } catch {
            showError(.unknown("Failed to save imported hymns: \(error.localizedDescription)"))
        }
    }
    
    private func showError(_ error: ImportError) {
        importError = error
        showingErrorAlert = true
    }
    
    private func showSuccess(_ message: String) {
        importSuccessMessage = message
        showingSuccessAlert = true
    }
    

    
    private func mergeHymnData(existing: Hymn, new: Hymn) {
        // Merge new data into existing hymn, preserving existing data when new data is empty
        // Only update fields that are empty in existing but have content in new
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
        // Replace existing hymn data with new data
        existing.lyrics = new.lyrics
        existing.musicalKey = new.musicalKey
        existing.author = new.author
        existing.copyright = new.copyright
        existing.notes = new.notes
        existing.tags = new.tags
    }
    
    // MARK: - Specific Error Handling
    
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
    
    private func getSpecificExportError(_ error: NSError, operation: String) -> ImportError {
        switch error.code {
        case NSFileWriteNoPermissionError:
            return .permissionDenied
        case NSFileWriteOutOfSpaceError:
            return .fileReadFailed("Not enough disk space to save the \(operation) file")
        case NSFileWriteVolumeReadOnlyError:
            return .fileReadFailed("Cannot write to read-only volume")
        case NSFileWriteFileExistsError:
            return .fileReadFailed("A file with the same name already exists")
        case NSFileWriteInapplicableStringEncodingError:
            return .invalidFormat("Cannot encode \(operation) data with the current encoding")
        default:
            return .fileReadFailed("Failed to export \(operation): \(error.localizedDescription)")
        }
    }

    // MARK: - Import/Export Helpers

    private func importPlainTextHymn(from url: URL) {
        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            
            // Check if file is empty
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                showError(.emptyFile)
                return
            }
            
            guard let hymn = Hymn.fromPlainText(text) else {
                showError(.invalidFormat("Could not parse plain text format. Please ensure the first non-empty line is the title."))
                return
            }
            
            // Create preview data
            var validHymns: [ImportPreviewHymn] = []
            var duplicateHymns: [ImportPreviewHymn] = []
            var errors: [String] = []
            
            // Check for duplicate titles
            if let existingHymn = hymns.first(where: { $0.title.lowercased() == hymn.title.lowercased() }) {
                duplicateHymns.append(ImportPreviewHymn(from: hymn, isDuplicate: true, existingHymn: existingHymn))
            } else {
                validHymns.append(ImportPreviewHymn(from: hymn))
            }
            
            // Create preview and show it
            let preview = ImportPreview(
                hymns: validHymns,
                duplicates: duplicateHymns,
                errors: errors,
                fileName: url.lastPathComponent
            )
            
            importPreview = preview
            showingImportPreview = true
            
        } catch let error as NSError {
            let specificError = getSpecificFileError(error)
            showError(specificError)
        }
    }

    private func importBatchJSON(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            
            // Check if file is empty
            guard !data.isEmpty else {
                showError(.emptyFile)
                return
            }
            
            guard let importedHymns = Hymn.arrayFromJSON(data) else {
                showError(.invalidFormat("Could not parse JSON format. Please ensure the file contains valid JSON."))
                return
            }
            
            guard !importedHymns.isEmpty else {
                showError(.invalidFormat("No hymns found in the JSON file."))
                return
            }
            
            // Create preview data
            var validHymns: [ImportPreviewHymn] = []
            var duplicateHymns: [ImportPreviewHymn] = []
            var errors: [String] = []
            
            for hymn in importedHymns {
                // Validate hymn has a title
                guard !hymn.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    errors.append("Hymn missing title")
                    continue
                }
                
                // Check for duplicates
                if let existingHymn = hymns.first(where: { $0.title.lowercased() == hymn.title.lowercased() }) {
                    duplicateHymns.append(ImportPreviewHymn(from: hymn, isDuplicate: true, existingHymn: existingHymn))
                } else {
                    validHymns.append(ImportPreviewHymn(from: hymn))
                }
            }
            
            // Create preview and show it
            let preview = ImportPreview(
                hymns: validHymns,
                duplicates: duplicateHymns,
                errors: errors,
                fileName: url.lastPathComponent
            )
            
            importPreview = preview
            showingImportPreview = true
            
        } catch let error as NSError {
            let specificError = getSpecificFileError(error)
            showError(specificError)
        }
    }

    private func exportPlainTextHymn(_ hymn: Hymn, to url: URL) {
        do {
            let text = hymn.toPlainText()
            try text.write(to: url, atomically: true, encoding: .utf8)
        } catch let error as NSError {
            let specificError = getSpecificExportError(error, operation: "plain text")
            showError(specificError)
        }
    }

    private func exportSingleJSONHymn(_ hymn: Hymn, to url: URL) {
        do {
            guard let data = hymn.toJSON(pretty: true) else {
                showError(.invalidFormat("Failed to generate JSON data for hymn '\(hymn.title)'. The hymn data may be corrupted."))
                return
            }
            try data.write(to: url)
        } catch let error as NSError {
            let specificError = getSpecificExportError(error, operation: "JSON")
            showError(specificError)
        }
    }

    private func exportBatchJSON(_ hymns: [Hymn], to url: URL) {
        do {
            guard let data = Hymn.arrayToJSON(hymns, pretty: true) else {
                showError(.invalidFormat("Failed to generate JSON data for \(hymns.count) hymns. Some hymn data may be corrupted."))
                return
            }
            try data.write(to: url)
        } catch let error as NSError {
            let specificError = getSpecificExportError(error, operation: "JSON")
            showError(specificError)
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
