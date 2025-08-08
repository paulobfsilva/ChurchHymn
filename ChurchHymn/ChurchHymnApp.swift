//
//  ChurchHymnApp.swift
//  ChurchHymn
//
//  Created by paulo on 19/05/2025.
//

import SwiftUI
import SwiftData

#if os(macOS)
// Global holder to keep presenter window alive
public var presenterWindow: NSWindow?
#endif

@main
struct ChurchHymnApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Hymn.self])
        
        #if os(macOS)
        // ➊ Help window
        WindowGroup("Import Help", id: "importHelp") {
            ImportHelpView()
        }
        .defaultSize(width: 540, height: 640)
        .windowResizability(.contentSize)
        .commands {
            MainMenuCommands()
        }
        #endif
    }
}
