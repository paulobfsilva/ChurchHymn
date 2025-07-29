//
//  PresenterView.swift
//  ChurchHymn
//
//  Created by paulo on 20/05/2025.
//
import SwiftUI
import AppKit

struct PresenterView: View {
    var hymn: Hymn
    @State private var index: Int = 0
    @State private var monitor: Any?
    @Environment(\.dismiss) private var dismiss

    /// Sequence for presentation: if a chorus exists, repeat it after each verse;
    /// otherwise present each verse block in order.
    private var presentationParts: [(label: String?, lines: [String])] {
        let allBlocks = hymn.parts
        // Extract chorus blocks
        let choruses = allBlocks.filter { $0.label != nil }
        let verses = allBlocks.filter { $0.label == nil }
        if let chorusPart = choruses.first {
            // Interleave verse and chorus
            return verses.flatMap { [$0, chorusPart] }
        } else {
            // No chorus: just show each verse block
            return verses
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 24) {
                // Title at top
                Text(hymn.title)
                    .font(.system(size: 25, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 20)
                Spacer()
                // Lyrics block
                if !presentationParts.isEmpty {
                    Text(presentationParts[index].lines.joined(separator: "\n"))
                        .font(.system(size: 80))
                        .minimumScaleFactor(0.1)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding()
                } else if let lyrics = hymn.lyrics, !lyrics.isEmpty {
                    // Fallback: show raw lyrics if parts parsing failed
                    Text(lyrics)
                        .font(.system(size: 60))
                        .minimumScaleFactor(0.1)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding()
                } else {
                    // Show a test message when no lyrics are available
                    VStack(spacing: 20) {
                        Text("Test Hymn Display")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        Text("This is a test to verify the presenter is working correctly.")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        Text("Press ESC to close")
                            .font(.system(size: 20))
                            .foregroundColor(.yellow)
                    }
                    .padding()
                }
                Spacer()
                // Label or verse number at bottom right
                HStack {
                    // Copyright bottom-left
                    Text(hymn.copyright ?? "")
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                    Spacer()
                    // Key bottom-center
                    Text(hymn.musicalKey ?? "")
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                    Spacer().frame(width: 40)
                    // Verse/Chorus bottom-right
                    if !presentationParts.isEmpty {
                        Group {
                            if let label = presentationParts[index].label {
                                Text(label)
                            } else {
                                let verseNumber = presentationParts[0...index].filter { $0.label == nil }.count
                                Text("Verse \(verseNumber)")
                            }
                        }
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                    }
                }
                .padding([.bottom, .horizontal], 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .onAppear(perform: startMonitor)
            .onDisappear(perform: stopMonitor)
        }
        .ignoresSafeArea()
    }
    
    private func advance() {
        index = (index + 1) % presentationParts.count
    }
    
    private func retreat() {
        index = (index - 1 + presentationParts.count) % presentationParts.count
    }
    
    private func startMonitor() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            switch event.keyCode {
            case 49, 36, 124, 125: advance() // Space, Return, Right, Down
            case 123, 126: retreat() // Left, Up
            case 53: // ESC key
                DispatchQueue.main.async {
                    dismiss()
                }
                return nil
            default: return event
            }
            return nil
        }
    }
    
    private func stopMonitor() {
        if let m = monitor { 
            NSEvent.removeMonitor(m)
            monitor = nil 
        }
    }
}
