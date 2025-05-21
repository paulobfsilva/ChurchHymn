import SwiftUI
import UniformTypeIdentifiers
import AppKit
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Hymn.title, order: .forward) private var hymns: [Hymn]
    @State private var selected: Hymn? = nil
    @State private var showingAdd = false
    @State private var showingEdit = false
    @State private var importPicker = false

    var body: some View {
        NavigationSplitView {
            List(selection: $selected) {
                ForEach(hymns, id: \.id) { hymn in
                    Text(hymn.title)
                        .tag(hymn)
                }
                .onDelete(perform: deleteHymns)
            }
            .frame(minWidth: 200)
            .toolbar {
                // Sidebar actions
                ToolbarItemGroup(placement: .navigation) {
                    Button("Add") { showingAdd = true }
                    Button("Import") { importPicker = true }
                }
                // Detail actions
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("Edit") { showingEdit = true }
                        .disabled(selected == nil)
                    Button("Present") { if let hymn = selected { present(hymn) } }
                        .disabled(selected == nil)
                }
            }
            .fileImporter(
                isPresented: $importPicker,
                allowedContentTypes: [UTType.plainText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let url): importFromFile(url.first!)
                case .failure(let error): print(error)
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
        .sheet(isPresented: $showingAdd) {
            HymnEditView()
        }
        .sheet(isPresented: $showingEdit) {
            if let hymn = selected {
                HymnEditView(hymn: hymn)
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
