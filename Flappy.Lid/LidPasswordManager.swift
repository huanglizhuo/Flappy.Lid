import Foundation
import Combine
import SwiftUI
import ApplicationServices

enum LidPasswordState {
    case idle       // Angle > Threshold
    case monitoring // Angle < Threshold, waiting for gestures
    case success    // Triggered, typing
}

class LidPasswordManager: ObservableObject {
    static let shared = LidPasswordManager()
    
    // Configuration
    @Published var maxActivationAngle: Double {
        didSet { UserDefaults.standard.set(maxActivationAngle, forKey: "lidPass_maxAngle") }
    }
    @Published var targetPassword: String {
        didSet { UserDefaults.standard.set(targetPassword, forKey: "lidPass_password") }
    }
    
    // Runtime State
    @Published var state: LidPasswordState = .idle
    @Published var openCount: Int = 0
    
    private var lastAngle: Double = 0.0
    private var cancellables = Set<AnyCancellable>()
    
    // Logic Buffers
    private var gestureTimestamps: [Date] = []
    
    // Constants
    private let triggerDelta: Double = 4.0
    private let timeWindow: TimeInterval = 3.0
    
    // Configurable
    @Published var requiredCount: Int {
        didSet { UserDefaults.standard.set(requiredCount, forKey: "lidPass_requiredCount") }
    }
    
    init() {
        let savedAngle = UserDefaults.standard.double(forKey: "lidPass_maxAngle")
        self.maxActivationAngle = savedAngle == 0 ? 30.0 : savedAngle
        self.targetPassword = UserDefaults.standard.string(forKey: "lidPass_password") ?? ""
        
        let savedCount = UserDefaults.standard.integer(forKey: "lidPass_requiredCount")
        self.requiredCount = savedCount == 0 ? 3 : savedCount
    }
    
    func startMonitoring(lidMonitor: LidAngleMonitor) {
        lidMonitor.$currentAngle
            .sink { [weak self] angle in
                self?.processAngleUpdate(angle)
            }
            .store(in: &cancellables)
    }
    
    private func processAngleUpdate(_ currentAngle: Double) {
        let delta = currentAngle - lastAngle
        lastAngle = currentAngle
        
        // 1. Check constraints
        if currentAngle > maxActivationAngle {
            if state != .idle {
                resetLogic()
                state = .idle
            }
            return
        } else {
            if state == .idle {
                state = .monitoring
            }
        }
        
        guard state == .monitoring else { return }
        
        // 2. Detect Positive Delta (Open)
        if delta > triggerDelta {
            registerGesture()
        }
    }
    
    private func registerGesture() {
        let now = Date()
        
        // Prune old gestures
        gestureTimestamps = gestureTimestamps.filter { now.timeIntervalSince($0) < timeWindow }
        
        // Add new one (Debounce slightly to avoid one big move counting as multiple? 
        // Logic says "close and open lid 3 times", so we assume significant motion.
        // We'll add a small debounce of 0.2s to prevent jitter counting)
        if let last = gestureTimestamps.last, now.timeIntervalSince(last) < 0.2 {
            return
        }
        
        gestureTimestamps.append(now)
        openCount = gestureTimestamps.count
        triggerFeedback(type: .generic) // Haptic tick per count
        
        // Check Trigger
        if gestureTimestamps.count >= requiredCount {
            performUnlock()
            resetLogic() // Reset count immediately so we don't double trigger
        }
    }
    
    private func resetLogic() {
        gestureTimestamps.removeAll()
        openCount = 0
    }
    
    private func performUnlock() {
        state = .success
        triggerFeedback(type: .success)
        
        guard !targetPassword.isEmpty else {
            // Just transition back after a delay if empty
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.state = .monitoring
            }
            return
        }
        
        let passwordToType = targetPassword
        
        DispatchQueue.global().async {
            // Type String
            // We need a char -> keyCode mapper. 
            // For MVP, we will assume simple ASCII or just type the string if we can.
            // But CGEvent keyboard requires keycodes.
            // Implementing a full mapper inside here is complex.
            // Is there a simpler way? 
            // We can use a Clipboard paste approach? "Cmd+V"? 
            // Or just iterate standard keys.
            // The prompt says "call key press api and each key press shoule have 50ms interval".
            
            for char in passwordToType {
                if let code = self.keyCode(for: char) {
                    KeySimulator.shared.simulateSpecificKey(code)
                    Thread.sleep(forTimeInterval: 0.05)
                }
            }
            
            // Enter
            KeySimulator.shared.simulateSpecificKey(36)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("Unlock Sequence Complete")
            }
        }
        
        // Reset UI state after typing
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.state = .monitoring
        }
    }
    
    private func keyCode(for char: Character) -> CGKeyCode? {
        // Basic Map
        let s = String(char).lowercased()
        switch s {
        case "a": return 0
        case "b": return 11
        case "c": return 8
        case "d": return 2
        case "e": return 14
        case "f": return 3
        case "g": return 5
        case "h": return 4
        case "i": return 34
        case "j": return 38
        case "k": return 40
        case "l": return 37
        case "m": return 46
        case "n": return 45
        case "o": return 31
        case "p": return 35
        case "q": return 12
        case "r": return 15
        case "s": return 1
        case "t": return 17
        case "u": return 32
        case "v": return 9
        case "w": return 13
        case "x": return 7
        case "y": return 16
        case "z": return 6
        case "1": return 18
        case "2": return 19
        case "3": return 20
        case "4": return 21
        case "5": return 23
        case "6": return 22
        case "7": return 26
        case "8": return 28
        case "9": return 25
        case "0": return 29
        case " ": return 49
        default: return nil // Unknown
        }
    }
    
    // Custom Enum for macOS Feedback
    enum FeedbackType {
        case success
        case generic
    }
    
    private func triggerFeedback(type: FeedbackType) {
        let pattern: NSHapticFeedbackManager.FeedbackPattern
        switch type {
        case .success: pattern = .levelChange
        case .generic: pattern = .generic
        }
        NSHapticFeedbackManager.defaultPerformer.perform(pattern, performanceTime: .now)
    }
}
