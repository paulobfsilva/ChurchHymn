import SwiftUI
import Foundation

// MARK: - Menu Action Types
enum MenuAction {
    case addNewHymn
    case importHymns
    case editCurrentHymn
    case exportSelected
    case exportMultiple
    case exportAll
}

// MARK: - Menu Action Publisher
class MenuActionPublisher: ObservableObject {
    static let shared = MenuActionPublisher()
    
    func sendAction(_ action: MenuAction) {
        NotificationCenter.default.post(name: .menuAction, object: action)
    }
}

extension Notification.Name {
    static let menuAction = Notification.Name("MenuAction")
}

// MARK: - Main Menu Commands
struct MainMenuCommands: Commands {
    @Environment(\.openWindow) private var openWindow
    
    var body: some Commands {
        // File Menu
        CommandGroup(after: .newItem) {
            Button("Add New Hymn") {
                MenuActionPublisher.shared.sendAction(.addNewHymn)
            }
            .keyboardShortcut("n", modifiers: [.command])
            
            Divider()
            
            Button("Import...") {
                MenuActionPublisher.shared.sendAction(.importHymns)
            }
            .keyboardShortcut("i", modifiers: [.command])
        }
        
        // Edit Menu
        CommandGroup(after: .undoRedo) {
            Divider()
            
            Button("Edit Current Hymn") {
                MenuActionPublisher.shared.sendAction(.editCurrentHymn)
            }
            .keyboardShortcut("e", modifiers: [.command])
        }
        
        // Export Menu (Custom)
        CommandMenu("Export") {
            Button("Export Selected Hymn") {
                MenuActionPublisher.shared.sendAction(.exportSelected)
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])
            
            Button("Export Multiple Hymns...") {
                MenuActionPublisher.shared.sendAction(.exportMultiple)
            }
            
            Button("Export All Hymns") {
                MenuActionPublisher.shared.sendAction(.exportAll)
            }
            .keyboardShortcut("e", modifiers: [.command, .option])
        }
        
        // Help Menu (replacing existing)
        CommandGroup(replacing: .help) {
            Button("Import Help") {
                openWindow(id: "importHelp")
            }
            .keyboardShortcut("?", modifiers: [.command])

            Divider()

            Link("Support Page", destination: URL(string: "https://paulobfsilva.github.io/ChurchHymn/support.html")!)
        }
    }
}