import AppKit
import SwiftUI
import Combine
           
class StatusBarManager: ObservableObject {
    static let shared = StatusBarManager()
    
    private var statusItem: NSStatusItem?
    private var isMinimized: Bool = false
    
    // Callbacks to trigger window actions
    var onRestore: (() -> Void)?
    
    func start() {
        guard statusItem == nil else { return }
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.title = "Flappy.Lid"
            button.image = NSImage(systemSymbolName: "macbook.and.ipad", accessibilityDescription: "Flappy Lid")
        }
        
        updateMenu()
    }
    
    func updateDisplay(angle: Double, keyName: String) {
        guard let button = statusItem?.button else { return }
        let angleStr = String(format: "%.1f°", angle)
        button.title = "\(angleStr) [\(keyName)]"
    }
    
    func minimizeToMenuBar() {
        start() // Ensure it's started
        isMinimized = true
        NSApp.windows.first?.orderOut(nil)
        // Or specific window management if multiple windows exist
    }
    
    func restoreFromMenuBar() {
        isMinimized = false
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
        stop() // Optional: Remove menu bar if we only want it when minimized
    }
    
    func stop() {
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
    }
    
    private func updateMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Show Flappy.Lid", action: #selector(onShowApp), keyEquivalent: "o"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
        // Need to set target for onShowApp
        menu.items.first?.target = self
    }
    
    @objc func onShowApp() {
        restoreFromMenuBar()
        onRestore?()
    }
}
