import Foundation
import Combine
import ApplicationServices
import SwiftUI

class KeySimulator: ObservableObject {
    static let shared = KeySimulator()
    
    @Published var targetKeyCode: CGKeyCode {
        didSet {
            UserDefaults.standard.set(targetKeyCode, forKey: "sim_targetKeyCode")
        }
    }
    
    // UI Feedback
    @Published var lastTriggerTime: Date?
    
    init() {
        let savedKey = UserDefaults.standard.integer(forKey: "sim_targetKeyCode")
        // Default to Space (49) if 0 (which is 'a', somewhat ambiguous but safe enough, or we check specifically)
        // Better: check if key exists. Space is 49.
        if savedKey == 0 && UserDefaults.standard.object(forKey: "sim_targetKeyCode") == nil {
            self.targetKeyCode = 49 // Space
        } else {
            self.targetKeyCode = CGKeyCode(savedKey)
        }
    }
    
    func simulatePress() {
        // Visual feedback
        DispatchQueue.main.async {
            self.lastTriggerTime = Date()
        }
        
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Key Down
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: targetKeyCode, keyDown: true) else { return }
        // Key Up
        guard let keyUp = CGEvent(keyboardEventSource: source, virtualKey: targetKeyCode, keyDown: false) else { return }
        
        keyDown.post(tap: .cghidEventTap)
        
        // Add a small delay to simulate real key press duration.
        // Some apps (like Chrome) might ignore zero-duration presses.
        Thread.sleep(forTimeInterval: 0.05) // 50ms
        
        keyUp.post(tap: .cghidEventTap)
        
        print("[KeySimulator] Sent Key Code: \(targetKeyCode)")
    }
    
    func checkPermissions() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}
