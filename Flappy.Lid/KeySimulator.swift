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
    
    @Published var isHapticEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isHapticEnabled, forKey: "sim_hapticEnabled")
        }
    }
    
    // UI Feedback
    @Published var lastTriggerTime: Date?
    
    init() {
        let savedKey = UserDefaults.standard.integer(forKey: "sim_targetKeyCode")
        // Default to Space (49)
        if savedKey == 0 && UserDefaults.standard.object(forKey: "sim_targetKeyCode") == nil {
            self.targetKeyCode = 49 // Space
        } else {
            self.targetKeyCode = CGKeyCode(savedKey)
        }
        
        self.isHapticEnabled = UserDefaults.standard.object(forKey: "sim_hapticEnabled") as? Bool ?? true
    }
    
    func simulatePress() {
        // Visual feedback
        DispatchQueue.main.async {
            self.lastTriggerTime = Date()
        }
        
        // Haptic Feedback
        if isHapticEnabled {
            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
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
    
    func keyCodeToName(_ code: CGKeyCode) -> String {
        switch code {
        case 49: return "SPACE"
        case 36: return "ENTER"
        case 123: return "LEFT"
        case 124: return "RIGHT"
        case 126: return "UP"
        case 125: return "DOWN"
        default: return "CODE: \(code)"
        }
    }
}
