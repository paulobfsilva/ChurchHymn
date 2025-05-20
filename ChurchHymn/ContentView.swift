import SwiftUI
import UniformTypeIdentifiers
import AppKit

// MARK: - Model
struct Hymn: Identifiable, Codable {
    let id: UUID
    var title: String
    var parts: [HymnPart]
}

enum HymnPart: Codable {
    case verse([String])
    case chorus([String])
}

// MARK: - ViewModel
class HymnViewModel: ObservableObject {
    @Published var hymns: [Hymn] = []
    @Published var selectedHymn: Hymn? = nil

    func addHymn(title: String, parts: [HymnPart]) {
        let hymn = Hymn(id: UUID(), title: title, parts: parts)
        hymns.append(hymn)
    }

    func deleteHymn(at offsets: IndexSet) {
        hymns.remove(atOffsets: offsets)
    }

    func load(from url: URL) {
        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            parseTextFile(text)
        } catch {
            print("Failed to load file: \(error)")
        }
    }

    private func parseTextFile(_ text: String) {
            // First non-empty line is title
            let lines = text.components(separatedBy: .newlines)
            guard let titleLine = lines.first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) else { return }
            let title = titleLine.trimmingCharacters(in: .whitespaces)
            // Remaining text after title
            let bodyLines = Array(lines.drop { $0 != titleLine }).dropFirst()
            let bodyText = bodyLines.joined(separator: "\n")
            // Split into blocks by empty line
            let blockStrings = bodyText.components(separatedBy: "\n\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            var parts: [HymnPart] = []
            for block in blockStrings {
                let blockLines = block.components(separatedBy: .newlines)
                if blockLines.allSatisfy({ $0.hasPrefix("C:") }) {
                    let content = blockLines.map { String($0.dropFirst(2)).trimmingCharacters(in: .whitespaces) }
                    parts.append(.chorus(content))
                } else {
                    parts.append(.verse(blockLines))
                }
            }
            addHymn(title: title, parts: parts)
        }
    }

// MARK: - Views
struct ContentView: View {
    @EnvironmentObject var viewModel: HymnViewModel
    @State private var showingFileImporter = false
    @State private var showingAddSheet = false
    @State private var presenterWindow: NSWindow?

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.hymns) { hymn in
                    Button(hymn.title) { viewModel.selectedHymn = hymn }
                }
                .onDelete(perform: viewModel.deleteHymn)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) { Button("Add") { showingAddSheet = true } }
                ToolbarItem { Button("Load from File") { showingFileImporter = true } }
                ToolbarItem { Button("Present") { if let hymn = viewModel.selectedHymn { present(hymn) } } }
            }
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [.plainText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let url): viewModel.load(from: url.first!)
                case .failure(let error): print("Import failed: \(error)")
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddHymnView(isPresented: $showingAddSheet)
                    .environmentObject(viewModel)
            }

            if let hymn = viewModel.selectedHymn {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(hymn.title)
                            .font(.title)
                        ForEach(Array(hymn.parts.enumerated()), id: \.offset) { idx, part in
                            Group {
                                switch part {
                                case .verse(let lines):
                                    VStack(alignment: .leading, spacing: 4) {
                                        ForEach(lines, id: \.self) { line in
                                            Text(line)
                                        }
                                    }
                                case .chorus(let lines):
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Chorus")
                                            .italic()
                                        ForEach(lines, id: \.self) { line in
                                            Text(line)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text("Select a hymn")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    // Launch presenter mode
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
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { window.toggleFullScreen(nil) }
        presenterWindow = window
    }
}


    // MARK: - Add Hymn Sheet
    struct AddHymnView: View {
        @EnvironmentObject var viewModel: HymnViewModel
        @Binding var isPresented: Bool
        @State private var title = ""
        @State private var lyrics = "Verse line 1\nVerse line 2\n\nC:Chorus line 1\nC:Chorus line 2"

        var body: some View {
            VStack(spacing: 20) {
                Text("New Hymn").font(.headline)
                TextField("Title", text: $title)
                Text("Enter lyrics. Prefix chorus lines with \"C:\". Separate blocks with an empty line.")
                    .font(.subheadline)
                TextEditor(text: $lyrics)
                    .border(Color.gray, width: 1)
                    .frame(height: 200)
                HStack {
                    Button("Cancel") { isPresented = false }
                    Spacer()
                    Button("Add") {
                        // Split lyrics into blocks separated by empty lines
                        let blocks = lyrics.components(separatedBy: "\n\n")
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                        var parts: [HymnPart] = []
                        for block in blocks {
                            let lines = block.components(separatedBy: .newlines)
                            if lines.allSatisfy({ $0.hasPrefix("C:") }) {
                                let content = lines.map { String($0.dropFirst(2)).trimmingCharacters(in: .whitespaces) }
                                parts.append(.chorus(content))
                            } else {
                                parts.append(.verse(lines))
                            }
                        }
                        viewModel.addHymn(title: title, parts: parts)
                        isPresented = false
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || lyrics.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding()
            .frame(width: 500, height: 400)
        }
    }

    // MARK: - Presenter View
    struct PresenterView: View {
        var hymn: Hymn
        @State private var index = 0
        @State private var eventMonitor: Any?

        var body: some View {
            GeometryReader { proxy in
                VStack(spacing: 30) {
                    Text(hymn.title)
                        .font(.title)
                        .foregroundColor(.white)
                    Text(currentBlock)
                        .font(.system(size: 80))
                        .minimumScaleFactor(0.1)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                }
                .padding()
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
                .background(Color.black)
                .onAppear(perform: startKeyMonitor)
                .onDisappear(perform: stopKeyMonitor)
            }
        }

        private var currentBlock: String {
            let lines: [String]
            switch hymn.parts[index] {
            case .verse(let ls): lines = ls
            case .chorus(let ls): lines = ls
            }
            return lines.joined(separator: "\n")
        }

        private func advance() {
            index = index + 1 < hymn.parts.count ? index + 1 : 0
        }
        private func retreat() {
            index = index - 1 >= 0 ? index - 1 : hymn.parts.count - 1
        }

        private func startKeyMonitor() {
            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                switch event.keyCode {
                case 49, 36, 124, 125: // Space, Return, Right Arrow, down arrow
                    advance()
                    return nil
                case 123, 126: // Left Arrow, Up Arrow
                    retreat()
                    return nil
                default:
                    return event
                }
            }
        }

        private func stopKeyMonitor() {
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
        }
    }
