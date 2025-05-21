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

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 24) {
                Text(hymn.title)
                    .font(.title)
                    .foregroundColor(.white)
                Text(hymn.parts[index].lines.joined(separator: "\n"))
                    .font(.system(size: 80))
                    .minimumScaleFactor(0.1)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding()
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .background(Color.black)
            .onAppear(perform: startMonitor)
            .onDisappear(perform: stopMonitor)
        }
    }

    private func advance() { index = (index + 1) % hymn.parts.count }
    private func retreat() { index = (index - 1 + hymn.parts.count) % hymn.parts.count }

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
