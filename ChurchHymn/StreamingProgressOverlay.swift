import SwiftUI
import AppKit

struct StreamingProgressOverlay: View {
    let isStreaming: Bool
    let progress: StreamingProgress?
    let message: String
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            // Progress card
            VStack(spacing: 20) {
                // Icon
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                
                // Title
                Text("Streaming Operation")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Progress bars
                VStack(spacing: 12) {
                    // File progress
                    if let progress = progress, progress.totalBytes > 0 {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("File Progress")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ProgressView(value: progress.percentage, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle())
                                .frame(width: 300)
                            
                            Text("\(formatBytes(progress.bytesProcessed)) / \(formatBytes(progress.totalBytes))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Hymn progress
                    if let progress = progress, let totalHymns = progress.totalHymns, totalHymns > 0 {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Hymn Processing")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ProgressView(value: progress.hymnsPercentage, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle())
                                .frame(width: 300)
                            
                            Text("\(progress.hymnsProcessed) / \(totalHymns) hymns")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Overall percentage
                    if let progress = progress {
                        Text("\(Int(progress.percentage * 100))%")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }
                
                // Phase information
                if let progress = progress {
                    Text(progress.currentPhase)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                // Message
                if !message.isEmpty {
                    Text(message)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: 400)
                }
                
                // Memory usage indicator
                if let progress = progress {
                    HStack {
                        Image(systemName: "memorychip")
                            .foregroundColor(.orange)
                        Text("Memory efficient processing")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Cancel button
                Button("Cancel") {
                    // TODO: Implement cancellation
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.windowBackgroundColor))
                    .shadow(radius: 10)
            )
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
} 