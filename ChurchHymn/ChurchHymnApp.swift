//
//  ChurchHymnApp.swift
//  ChurchHymn
//
//  Created by paulo on 19/05/2025.
//

import SwiftUI
import SwiftData

// Global holder to keep presenter window alive
public var presenterWindow: NSWindow?

@main
struct ChurchHymnApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Hymn.self])
    }
}
