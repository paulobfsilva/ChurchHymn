import SwiftUI

struct HelpCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .help) {
            Button("Import Help") {
                openWindow(id: "importHelp")
            }

            Divider()

            Link("Support Page", destination: URL(string: "https://paulobfsilva.github.io/ChurchHymn/support.html")!)
        }
    }
}