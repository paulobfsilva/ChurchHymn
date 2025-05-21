//
//  PresenterView.swift
//  ChurchHymn
//
//  Created by paulo on 20/05/2025.
//
import SwiftUI

struct PresenterView: View {
    var hymn: Hymn
    @State private var index: Int = 0
    @State private var monitor: Any?

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
                Text(presentationParts[index].lines.joined(separator: "\n"))
                    .font(.system(size: 80))
                    .minimumScaleFactor(0.1)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding()
                                                           Spacer()
                // Label or verse number at bottom right
                HStack {
                    Spacer()
                    Group {
                        if let label = presentationParts[index].label {
                            Text(label)
                        } else {
                            // Calculate verse number
                            let verseCount = presentationParts[0...index].filter { $0.label == nil }.count
                            Text("Verse \(verseCount)")
                        }
                    }
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .padding([.bottom, .trailing], 20)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .background(Color.black)
            .onAppear(perform: startMonitor)
            .onDisappear(perform: stopMonitor)
        }
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
            case 49, 36, 124, 125: advance()
            case 123, 126: retreat()
            default: return event
            }
            return nil
        }
    }
    private func stopMonitor() {
        if let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
    }
}
